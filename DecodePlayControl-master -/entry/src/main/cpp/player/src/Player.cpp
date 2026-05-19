/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <cinttypes>
#include <cstdint>
#include "CodecCallback.h"
#include "XComponentManager.h"
#include "common/include/MediaError.h"
#include "common/include/MediaLog.h"
#include "Player.h"

constexpr int BALANCE_VALUE = 5;
constexpr int64_t WAIT_TIME_US_THRESHOLD_WARNING = -1 * 40 * 1000; // Warning threshold 40ms
constexpr int64_t WAIT_TIME_US_THRESHOLD = 1 * 1000 * 1000;        // Max sleep time 1s
constexpr int64_t PER_SINK_TIME_THRESHOLD = 33 * 1000;             // Max per sink time 33ms
constexpr int64_t SINK_TIME_US_THRESHOLD = 100000;                 // Max sink time 100ms
constexpr int32_t BYTES_PER_SAMPLE_2 = 2;                          // 2 bytes per sample
constexpr int32_t SEC_TO_NSEC = 1000000000;                        // s to ns
constexpr int32_t WAIT_TIME = 100;                                 // Thread release wait time

using namespace std::chrono_literals;

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0xFF00
#define LOG_TAG "Player"

Player::Player()
{
    isStarted_.store(false);
    isPause_.store(false);
    isReleased_.store(false);
    isReadRenderTime_.store(true);
    isAudioWaitSeek_.store(false);
    currentRenderTime_.store(0);
    speed_ = 1.0f;
    nowTimeStamp_ = 0;
    audioTimeStamp_ = 0;
    audioBufferPts_ = 0;
}

Player::~Player() { Player::StartRelease(); }

// [Start player_init]
int32_t Player::Init(SampleInfo &info)
{
    // [StartExclude player_init]
    std::unique_lock<std::mutex> lock(mutex_);
    CHECK_AND_RETURN_RET_LOG(!isStarted_, MEDIA_ERR_ERROR, "Already started.");
    CHECK_AND_RETURN_RET_LOG(demuxer_ == nullptr && videoDecoder_ == nullptr && audioDecoder_ == nullptr,
                             MEDIA_ERR_ERROR, "Already started.");

    videoInfo_ = info;
    // [EndExclude player_init]
    // Create decode sources pointer.
    videoDecoder_ = std::make_unique<VideoDecoder>();
    audioDecoder_ = std::make_unique<AudioDecoder>();
    demuxer_ = std::make_unique<Demuxer>();

    // Create demuxer by video info.
    int32_t ret = demuxer_->Create(videoInfo_);
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Create demuxer failed");
    // Create and Configure audio ande video decoder.
    ret = CreateAudioDecoder();
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Create audio decoder failed");
    ret = CreateVideoDecoder();
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Create video decoder failed");
    // [StartExclude player_init]
    if (audioDecContext_ != nullptr) {
        audioDecContext_->sampleInfo = &videoInfo_;
    }

    info = videoInfo_;
    isReleased_ = false;
    lock.unlock();
    return MEDIA_ERR_OK;
    // [EndExclude player_init]
}
// [End player_init]

int32_t Player::CreateAudioDecoder()
{
    MEDIA_LOGI("audio mime:%{public}s", videoInfo_.audioInfo.audioCodecMime.c_str());
    int32_t ret = audioDecoder_->Create(videoInfo_.audioInfo.audioCodecMime);
    if (ret != MEDIA_ERR_OK) {
        MEDIA_LOGE("Create audio decoder failed, mime:%{public}s", videoInfo_.audioInfo.audioCodecMime.c_str());
    } else {
        audioDecContext_ = new CodecUserData;
        ret = audioDecoder_->Config(videoInfo_, audioDecContext_);
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Audio Decoder config failed");
        OH_AudioStreamBuilder_Create(&builder_, AUDIOSTREAM_TYPE_RENDERER);
        OH_AudioStreamBuilder_SetLatencyMode(builder_, AUDIOSTREAM_LATENCY_MODE_NORMAL);
        // Set the audio sample rate
        OH_AudioStreamBuilder_SetSamplingRate(builder_, videoInfo_.audioInfo.audioSampleRate);
        // Set the audio channel
        OH_AudioStreamBuilder_SetChannelCount(builder_, videoInfo_.audioInfo.audioChannelCount);
        // Set the audio sample format
        OH_AudioStreamBuilder_SetSampleFormat(builder_, AUDIOSTREAM_SAMPLE_S16LE);
        // Set the encoding type of the audio stream
        OH_AudioStreamBuilder_SetEncodingType(builder_, AUDIOSTREAM_ENCODING_TYPE_RAW);
        // Set the working scenario for the output audio stream
        OH_AudioStreamBuilder_SetRendererInfo(builder_, AUDIOSTREAM_USAGE_MUSIC);
        MEDIA_LOGW("Init audioSampleRate: %{public}d, ChannelCount: %{public}d", videoInfo_.audioInfo.audioSampleRate,
                   videoInfo_.audioInfo.audioChannelCount);
        OH_AudioRenderer_Callbacks callbacks;
        // Configure the callback function
        callbacks.OH_AudioRenderer_OnWriteData = nullptr;
        callbacks.OH_AudioRenderer_OnStreamEvent = CodecCallback::OnRenderStreamEvent;
        callbacks.OH_AudioRenderer_OnInterruptEvent = CodecCallback::OnRenderInterruptEvent;
        callbacks.OH_AudioRenderer_OnError = CodecCallback::OnRenderError;
        // Set the callback for the output audio stream
        OH_AudioStreamBuilder_SetRendererCallback(builder_, callbacks, audioDecContext_);

        OH_AudioRenderer_OnWriteDataCallback writDataCb = CodecCallback::OnRenderWriteData;
        OH_AudioStreamBuilder_SetRendererWriteDataCallback(builder_, writDataCb, audioDecContext_);
        OH_AudioStreamBuilder_GenerateRenderer(builder_, &audioRenderer_);
    }
    return MEDIA_ERR_OK;
}

// [Start CreateVideoDecoder]
int32_t Player::CreateVideoDecoder()
{
    // Create decoder by system mime.
    int32_t ret = videoDecoder_->Create(videoInfo_.videoInfo.videoCodecMime);
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "Create video decoder failed, mime:%{public}s",
                             videoInfo_.videoInfo.videoCodecMime.c_str());
    videoDecContext_ = new CodecUserData;
    // Configure nativeWindow and video info to decoder.
    videoInfo_.videoInfo.window = XComponentManager::GetInstance()->nativeWindow_;
    ret = videoDecoder_->Config(videoInfo_, videoDecContext_);
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Video Decoder config failed");
    return MEDIA_ERR_OK;
}
// [End CreateVideoDecoder]

// [Start player_start]
int32_t Player::Start()
{
    // [StartExclude player_start]
    std::unique_lock<std::mutex> lock(mutex_);
    int32_t ret;
    CHECK_AND_RETURN_RET_LOG(!isStarted_, MEDIA_ERR_ERROR, "Already started.");
    CHECK_AND_RETURN_RET_LOG(demuxer_ != nullptr, MEDIA_ERR_ERROR, "demuxer is nullptr.");
    // [EndExclude player_start]
    if (videoDecContext_) {
        // Start the video decoder.
        ret = videoDecoder_->Start();
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Video Decoder start failed");
        // Set start state.
        isStarted_ = true;
        isPause_ = false;
        // Create video decode input and output sub thread.
        videoDecInputThread_ = std::make_unique<std::thread>(&Player::VideoDecInputThread, this);
        videoDecOutputThread_ = std::make_unique<std::thread>(&Player::VideoDecOutputThread, this);
        // [StartExclude player_start]
        // Deal exception.
        if (videoDecInputThread_ == nullptr || videoDecOutputThread_ == nullptr) {
            MEDIA_LOGE("Create thread failed");
            StartRelease();
            return MEDIA_ERR_ERROR;
        }
        // [EndExclude player_start]
    }
    // [StartExclude player_start]
    if (audioDecContext_) {
        ret = audioDecoder_->Start();
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, ret, "Audio Decoder start failed");
        isStarted_ = true;
        audioDecInputThread_ = std::make_unique<std::thread>(&Player::AudioDecInputThread, this);
        audioDecOutputThread_ = std::make_unique<std::thread>(&Player::AudioDecOutputThread, this);
        if (audioDecInputThread_ == nullptr || audioDecOutputThread_ == nullptr) {
            MEDIA_LOGE("Create thread failed");
            StartRelease();
            return MEDIA_ERR_ERROR;
        }
        // Clear the queue
        while (audioDecContext_ && !audioDecContext_->renderQueue.empty()) {
            audioDecContext_->renderQueue.pop();
        }
        if (audioRenderer_) {
            OH_AudioRenderer_Start(audioRenderer_);
            OH_AudioRenderer_SetSpeed(audioRenderer_, speed_);
            audioDecContext_->speed = speed_;
        }
    }
    lock.unlock();
    return MEDIA_ERR_OK;
    // [EndExclude player_start]
}
// [End player_start]

// [Start videoInput]
void Player::VideoDecInputThread()
{
    while (isDecoding_) {
        // [StartExclude videoInput]
        CHECK_AND_BREAK_LOG(isStarted_, "Decoder input thread out");
        // [Start wait]
        // Use condition to wait for decoder requests for data.
        std::unique_lock<std::mutex> lock(videoDecContext_->inputMutex);
        videoDecContext_->inputCond.wait(
            lock, [this]() { return !isPause_ && (!isStarted_ || !videoDecContext_->inputBufferInfoQueue.empty()); });
        // [End wait]
        // Check states.
        CHECK_AND_BREAK_LOG(isStarted_, "Work done, thread out");
        CHECK_AND_CONTINUE_LOG(!isPause_, "not pause, continue");
        CHECK_AND_CONTINUE_LOG(!videoDecContext_->inputBufferInfoQueue.empty(), "Buffer queue is empty, continue.");

        // [EndExclude videoInput]
        // Get AVBuffer and maintain the queue.
        CodecBufferInfo bufferInfo = videoDecContext_->inputBufferInfoQueue.front();
        videoDecContext_->inputBufferInfoQueue.pop();
        videoDecContext_->inputFrameCount++;
        // [StartExclude videoInput]
        lock.unlock();

        // Check flush state;
        std::shared_lock<std::shared_mutex> flushLock(videoDecContext_->flushMutex_, std::try_to_lock);
        if (!flushLock.owns_lock() || videoDecContext_->isFlushing.load()) {
            continue;
        }
        // [EndExclude videoInput]
        // [Start XPS]
        // [Start VideoReadSample]
        // read sample from demuxer.
        int32_t ret = demuxer_->ReadSample(demuxer_->GetVideoTrackId(),
                                           reinterpret_cast<OH_AVBuffer *>(bufferInfo.buffer), bufferInfo.attr);
        CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "ReadSample failed, thread out");
        // [StartExclude XPS]
        // [StartExclude videoInput]
        // Check if the buffer flag include eos.
        if (bufferInfo.attr.flags & AVCODEC_BUFFER_FLAGS_EOS) {
            while (!isAudioWaitSeek_.load()) {
                std::this_thread::sleep_for(std::chrono::microseconds(WAIT_TIME));
            }
            ret = demuxer_->Seek(0); // Seek to the first frame.
            CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "Loop failed, thread out");
            // Read first frame data from demuxer.
            ret = demuxer_->ReadSample(demuxer_->GetVideoTrackId(), reinterpret_cast<OH_AVBuffer *>(bufferInfo.buffer),
                                       bufferInfo.attr);
            CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "ReadSample failed, thread out");
        }
        // [End VideoReadSample]
        if (audioDecContext_ && isAudioWaitSeek_.load()) {
            audioDecContext_->endCond.notify_all();
            audioDecContext_->inputCond.notify_all();
        }
        // [EndExclude XPS]
        // [EndExclude videoInput]
        // push the buffer to the decoder.
        ret = videoDecoder_->PushInputBuffer(bufferInfo);
        CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "Push data failed, thread out");
        // [End XPS]
    }
    MEDIA_LOGI("VideoDecInputThread out.");
}
// [End videoInput]

CodecBufferInfo Player::GetBufferInfo()
{
    // Get Buffer after decoding and maintain the queue.
    CodecBufferInfo bufferInfo = videoDecContext_->outputBufferInfoQueue.front();
    videoDecContext_->outputBufferInfoQueue.pop();
    MEDIA_LOGI("VD bufferInfo.bufferIndex: %{public}d", bufferInfo.bufferIndex);
    videoDecContext_->outputFrameCount++;
    MEDIA_LOGI("VD Out buffer count: %{public}u, size: %{public}d, flag: %{public}u, pts: %{public}" PRId64,
               videoDecContext_->outputFrameCount, bufferInfo.attr.size, bufferInfo.attr.flags, bufferInfo.attr.pts);
    if (isReadRenderTime_.load()) {
        currentRenderTime_.store(bufferInfo.attr.pts);
    }
    return bufferInfo;
}

bool Player::AudioToVideoSync(CodecBufferInfo bufferInfo, int64_t framePosition)
{
    // after seek, audio render flush, framePosition = 0, then writtenSampleCnt = 0
    int64_t latency = (audioDecContext_->frameWrittenForSpeed - framePosition) * 1000 * 1000 /
                      videoInfo_.audioInfo.audioSampleRate / speed_;
    MEDIA_LOGI("VD latency: %{public}ld writtenSampleCnt: %{public}ld", latency,
               audioDecContext_->frameWrittenForSpeed);

    nowTimeStamp_ = GetCurrentTime();
    int64_t anchorDiff = (nowTimeStamp_ - audioTimeStamp_) / 1000;
    // us, audio buffer accelerate render time
    int64_t audioPlayedTime = audioDecContext_->currentPosAudioBufferPts - latency + anchorDiff;
    // us, video buffer expected render time
    int64_t videoPlayedTime = bufferInfo.attr.pts;

    // audio render timeStamp and now timeStamp diff
    int64_t waitTimeUs = videoPlayedTime - audioPlayedTime;

    MEDIA_LOGI("VD bufferInfo.bufferIndex: %{public}d", bufferInfo.bufferIndex);
    MEDIA_LOGI("VD audioPlayedTime: %{public}ld, videoPlayedTime: %{public}ld, nowTimeStamp: %{public}ld, "
               "audioTimeStamp: %{public}ld, waitTimeUs: %{public}ld, anchorDiff: %{public}ld",
               audioPlayedTime, videoPlayedTime, nowTimeStamp_, audioTimeStamp_, waitTimeUs, anchorDiff);

    bool dropFrame = false;
    // [Start AVSync]
    // video buffer is too late, drop it
    if (waitTimeUs < WAIT_TIME_US_THRESHOLD_WARNING) {
        dropFrame = true;
        MEDIA_LOGW("VD buffer is too late");
    } else {
        MEDIA_LOGW("VD buffer is too early waitTimeUs: %{public}ld", waitTimeUs);
        // [0, ), render it with waitTimeUs, max 1s
        // [-40,0), render it
        if (waitTimeUs > WAIT_TIME_US_THRESHOLD) {
            waitTimeUs = WAIT_TIME_US_THRESHOLD;
        }
        // per frame render time reduced by 33ms
        if (waitTimeUs > videoInfo_.videoInfo.frameInterval + PER_SINK_TIME_THRESHOLD) {
            waitTimeUs = videoInfo_.videoInfo.frameInterval + PER_SINK_TIME_THRESHOLD;
            MEDIA_LOGW("VD buffer is too early and reduced 33ms, waitTimeUs: %{public}ld", waitTimeUs);
        }
    }
    if (waitTimeUs > 0) {
        std::this_thread::sleep_for(std::chrono::microseconds(waitTimeUs));
    }
    // [End AVSync]
    return dropFrame;
}

// [Start videoOutput]
void Player::VideoDecOutputThread()
{
    videoInfo_.videoInfo.frameInterval = MICROSECOND / videoInfo_.videoInfo.frameRate;
    while (isDecoding_) {
        // [StartExclude videoOutput]
        thread_local auto lastPushTime = std::chrono::system_clock::now();
        CHECK_AND_BREAK_LOG(isStarted_, "VD Decoder output thread out");
        // Use condition to wait for decoder push data.
        std::unique_lock<std::mutex> lock(videoDecContext_->outputMutex);
        videoDecContext_->outputCond.wait(
            lock, [this]() { return !isPause_ && (!isStarted_ || !videoDecContext_->outputBufferInfoQueue.empty()); });
        // Check states.
        CHECK_AND_BREAK_LOG(isStarted_, "VD Decoder output thread out");
        CHECK_AND_CONTINUE_LOG(!isPause_, "not pause, continue");
        CHECK_AND_CONTINUE_LOG(!videoDecContext_->outputBufferInfoQueue.empty(), "VD Buffer queue is empty, continue.");
        // [EndExclude videoOutput]

        CodecBufferInfo bufferInfo = GetBufferInfo();
        // [StartExclude videoOutput]
        lock.unlock();
        std::shared_lock<std::shared_mutex> flushLock(videoDecContext_->flushMutex_, std::try_to_lock);
        if (!flushLock.owns_lock() || videoDecContext_->isFlushing.load()) {
            continue;
        }

        // get audio render position
        int64_t framePosition = 0;
        int64_t timeStamp = 0;
        int32_t ret = OH_AudioRenderer_GetTimestamp(audioRenderer_, CLOCK_MONOTONIC, &framePosition, &timeStamp);
        audioTimeStamp_ = timeStamp;

        // audio render getTimeStamp error, render it
        if (ret != AUDIOSTREAM_SUCCESS || (timeStamp == 0) || (framePosition == 0)) {
            // first frame, render without wait
            videoDecoder_->RenderOutputBuffer(bufferInfo.bufferIndex, true);
            std::this_thread::sleep_until(lastPushTime + std::chrono::microseconds(videoInfo_.videoInfo.frameInterval));
            lastPushTime = std::chrono::system_clock::now();
            continue;
        }

        bool dropFrame = AudioToVideoSync(bufferInfo, framePosition);
        CHECK_AND_BREAK_LOG(isStarted_, "VD Decoder output thread out");
        // [EndExclude videoOutput]
        // Notify the suface to render the data and release it.
        lastPushTime = std::chrono::system_clock::now();
        ret = videoDecoder_->RenderOutputBuffer(bufferInfo.bufferIndex, !dropFrame);
        CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "Decoder output thread out");
    }
    // [StartExclude videoOutput]
    audioBufferPts_ = 0;
    MEDIA_LOGI("VideoDecOutputThread out.");
    // [EndExclude videoOutput]
}
// [End videoOutput]

int64_t Player::GetCurrentTime()
{
    int64_t result = -1; // -1 for bad result
    struct timespec time;
    clockid_t clockId = CLOCK_MONOTONIC;
    int ret = clock_gettime(clockId, &time);
    CHECK_AND_RETURN_RET_LOG(ret >= 0, result, "GetCurNanoTime fail, result: %{public}d", ret);
    result = (time.tv_sec * SEC_TO_NSEC) + time.tv_nsec;
    return result;
}

void Player::AudioDecInputThread()
{
    while (isDecoding_) {
        CHECK_AND_BREAK_LOG(isStarted_, "Decoder input thread out");
        std::unique_lock<std::mutex> lock(audioDecContext_->inputMutex);
        audioDecContext_->inputCond.wait(
            lock, [this]() { return !isPause_ && (!isStarted_ || !audioDecContext_->inputBufferInfoQueue.empty()); });
        CHECK_AND_BREAK_LOG(isStarted_, "Work done, thread out");
        CHECK_AND_CONTINUE_LOG(!isPause_, "not pause, continue");
        CHECK_AND_CONTINUE_LOG(!audioDecContext_->inputBufferInfoQueue.empty(), "Buffer queue is empty, continue.");

        CodecBufferInfo bufferInfo = audioDecContext_->inputBufferInfoQueue.front();
        audioDecContext_->inputBufferInfoQueue.pop();
        audioDecContext_->inputFrameCount++;
        lock.unlock();

        // Check flush state;
        std::shared_lock<std::shared_mutex> flushLock(audioDecContext_->flushMutex_, std::try_to_lock);
        if (!flushLock.owns_lock() || audioDecContext_->isFlushing.load()) {
            continue;
        }

        // [Start AudioReadSample]
        // Read sample from demuxer.
        int32_t ret = demuxer_->ReadSample(demuxer_->GetAudioTrackId(),
                                           reinterpret_cast<OH_AVBuffer *>(bufferInfo.buffer), bufferInfo.attr);
        CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "ReadSample failed, thread out");
        // Check if the buffer flag include eos.
        while (bufferInfo.attr.flags & AVCODEC_BUFFER_FLAGS_EOS) {
            // Wait the video thread seek to first frame.
            std::unique_lock<std::mutex> lock(audioDecContext_->endMutex);
            isAudioWaitSeek_.store(true);
            audioDecContext_->endCond.wait(lock);
            int32_t ret = demuxer_->ReadSample(demuxer_->GetAudioTrackId(),
                                               reinterpret_cast<OH_AVBuffer *>(bufferInfo.buffer), bufferInfo.attr);
            CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "ReadSample failed, thread out");
        }
        isAudioWaitSeek_.store(false);
        // [End AudioReadSample]

        ret = audioDecoder_->PushInputBuffer(bufferInfo);
        CHECK_AND_BREAK_LOG(ret == MEDIA_ERR_OK, "Push data failed, thread out");
    }
    MEDIA_LOGI("AudioDecInputThread out.");
}

void Player::AudioDecOutputThread()
{
    while (isDecoding_) {
        CHECK_AND_BREAK_LOG(isStarted_, "Decoder output thread out");
        std::unique_lock<std::mutex> lock(audioDecContext_->outputMutex);
        audioDecContext_->outputCond.wait(lock, [this]() {
            return !isPause_ && (!isStarted_ || !audioDecContext_->outputBufferInfoQueue.empty());
        });
        CHECK_AND_BREAK_LOG(isStarted_, "Decoder output thread out");
        CHECK_AND_CONTINUE_LOG(!isPause_, "not pause, continue");
        CHECK_AND_CONTINUE_LOG(!audioDecContext_->outputBufferInfoQueue.empty(),
                               "Buffer queue is empty, continue.");

        CodecBufferInfo bufferInfo = audioDecContext_->outputBufferInfoQueue.front();
        audioDecContext_->outputBufferInfoQueue.pop();
        audioDecContext_->outputFrameCount++;
        MEDIA_LOGI("Out buffer count: %{public}u, size: %{public}d, flag: %{public}u, pts: %{public}" PRId64,
                   audioDecContext_->outputFrameCount, bufferInfo.attr.size, bufferInfo.attr.flags,
                   bufferInfo.attr.pts);
        uint8_t *source = OH_AVBuffer_GetAddr(reinterpret_cast<OH_AVBuffer *>(bufferInfo.buffer));
        // Put the decoded PMC data into the queue
        for (int i = 0; i < bufferInfo.attr.size; i++) {
            CHECK_AND_BREAK_LOG(isStarted_, "Decoder output thread out");
            audioDecContext_->renderQueue.push(*(source + i));
        }
        CHECK_AND_BREAK_LOG(isStarted_, "Decoder output thread out");
        lock.unlock();
        
        // Check flush state;
        std::shared_lock<std::shared_mutex> flushLock(audioDecContext_->flushMutex_, std::try_to_lock);
        if (!flushLock.owns_lock() || audioDecContext_->isFlushing.load()) {
            continue;
        }

        audioBufferPts_ = bufferInfo.attr.pts;
        audioDecContext_->endPosAudioBufferPts = audioBufferPts_;
        size_t bufferSize = bufferInfo.attr.size;
        audioDecoder_->FreeOutputBuffer(bufferInfo.bufferIndex);

        std::unique_lock<std::mutex> lockRender(audioDecContext_->renderMutex);
        audioDecContext_->renderCond.wait_for(lockRender, 20ms, [this, bufferSize]() {
            return audioDecContext_->renderQueue.size() < BALANCE_VALUE * bufferSize;
        });
    }
    MEDIA_LOGI("AudioDecOutputThread out.");
}

// [Start Pause]
int32_t Player::Pause()
{
    CHECK_AND_RETURN_RET_LOG(isStarted_, MEDIA_ERR_ERROR, "player do not start!");
    // Set pause state.
    isPause_.store(true);
    // if the audio render, pause it.
    if (audioRenderer_) {
        OH_AudioRenderer_Pause(audioRenderer_);
    }
    return MEDIA_ERR_OK;
}
// [End Pause]

// [Start Resume]
int32_t Player::Resume()
{
    CHECK_AND_RETURN_RET_LOG(isStarted_, MEDIA_ERR_ERROR, "player do not start!");
    isPause_.store(false); // Cancel the pause state.
    // Notify the thread to continue work.
    if (videoDecContext_) {
        videoDecContext_->inputCond.notify_all();
        videoDecContext_->outputCond.notify_all();
    }
    if (audioDecContext_) {
        audioDecContext_->inputCond.notify_all();
        audioDecContext_->outputCond.notify_all();
    }
    if (audioRenderer_) {
        OH_AudioRenderer_Start(audioRenderer_); // if need audio to play, continue.
    }
    return MEDIA_ERR_OK;
}
// [Start Resume]

// [Start SetSpeed]
void Player::SetSpeed(float speed)
{
    // [StartExclude SetSpeed]
    CHECK_AND_RETURN_LOG(isStarted_, "player do not start!");
    if (speed_ == speed) {
        MEDIA_LOGI("Same speed value");
        return;
    }

    if (!audioDecContext_ || !audioRenderer_) {
        MEDIA_LOGE("Audio ptr is nullptr");
        return;
    }
    // [EndExclude SetSpeed]
    // Set audio play speed.
    OH_AudioRenderer_SetSpeed(audioRenderer_, speed);
    // Set speed value for sub thread.
    speed_ = speed;
    audioDecContext_->speed = speed;
}
// [End SetSpeed]

// [Start Seek]
int32_t Player::Seek(int64_t desTime)
{
    isReadRenderTime_.store(false);
    // [StartExclude Seek]
    int64_t milliseconds = desTime * MILLISECONDS;
    currentRenderTime_.store(milliseconds);
    int32_t ret = demuxer_->Seek(milliseconds);
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "video seek failed");

    if (audioDecoder_) {
        audioDecContext_->isFlushing.store(true);
        audioDecContext_->ClearQueue();
        ret = audioDecoder_->Flush(audioDecContext_);
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "video seek audio flush failed");
        audioDecContext_->isFlushing.store(false);
        ret = audioDecoder_->Start();
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "video seek start audioDecoder failed");
    }
    // [EndExclude Seek]
    if (videoDecoder_) {
        // Flush decoder, clear cache.
        videoDecContext_->isFlushing.store(true);
        videoDecContext_->ClearQueue();
        ret = videoDecoder_->Flush(videoDecContext_);
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "video seek video flush failed");
        videoDecContext_->isFlushing.store(false);
        // Restart the decoder.
        ret = videoDecoder_->Start();
        CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "video seek start videoDecoder failed");
    }
    // [StartExclude Seek]
    // When the video is paused, continue playing after seeking.
    if (isPause_.load()) {
        Resume();
    }

    currentRenderTime_.store(desTime);
    isReadRenderTime_.store(true);
    return MEDIA_ERR_OK;
    // [EndExclude Seek]
}
// [End Seek]

void Player::StartRelease()
{
    if (isReleased_) {
        return;
    }
    if (audioRenderer_) {
        OH_AudioRenderer_Stop(audioRenderer_);
    }
    isReleased_ = true;
    Release();
}

void Player::ReleaseThread()
{
    if (videoDecInputThread_ && videoDecInputThread_->joinable()) {
        videoDecInputThread_->join();
        videoDecInputThread_.reset();
    }
    if (videoDecOutputThread_ && videoDecOutputThread_->joinable()) {
        videoDecOutputThread_->join();
        videoDecOutputThread_.reset();
    }
    if (audioDecInputThread_ && audioDecInputThread_->joinable()) {
        audioDecInputThread_->join();
        audioDecInputThread_.reset();
    }
    if (audioDecOutputThread_ && audioDecOutputThread_->joinable()) {
        audioDecOutputThread_->join();
        audioDecOutputThread_.reset();
    }
}

// [Start Release]
void Player::Release()
{
    // [StartExclude Release]
    // Set release state.
    std::unique_lock<std::mutex> lock(mutex_);
    isStarted_ = false;
    isPause_ = false;
    // [EndExclude Release]
    // Notify the sub thread continue and over.
    if (videoDecContext_) {
        videoDecContext_->inputCond.notify_all();
        videoDecContext_->outputCond.notify_all();
    }
    // [StartExclude Release]
    if (audioDecContext_) {
        audioDecContext_->inputCond.notify_all();
        audioDecContext_->outputCond.notify_all();
    }

    // Clear the queue
    while (audioDecContext_ && !audioDecContext_->renderQueue.empty()) {
        audioDecContext_->renderQueue.pop();
    }
    // [EndExclude Release]
    ReleaseThread();
    currentRenderTime_.store(0);
    
    if (audioRenderer_ != nullptr) {
        OH_AudioRenderer_Release(audioRenderer_);
        audioRenderer_ = nullptr;
    }
    // Release decode resoure.
    if (demuxer_ != nullptr) {
        demuxer_->Release();
        demuxer_.reset();
    }
    if (videoDecoder_ != nullptr) {
        videoDecoder_->Release();
        videoDecoder_.reset();
    }
    // [StartExclude Release]
    // Clear video info.
    if (videoDecContext_ != nullptr) {
        delete videoDecContext_;
        videoDecContext_ = nullptr;
    }
    if (audioDecoder_ != nullptr) {
        audioDecoder_->Release();
        audioDecoder_.reset();
    }
    if (audioDecContext_ != nullptr) {
        delete audioDecContext_;
        audioDecContext_ = nullptr;
    }
    if (builder_ != nullptr) {
        OH_AudioStreamBuilder_Destroy(builder_);
        builder_ = nullptr;
    }
    lock.unlock();
    // [EndExclude Release]
}
// [End Release]