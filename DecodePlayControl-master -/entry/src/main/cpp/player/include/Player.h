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

#ifndef VIDEOPLAYBACKCONTROLONSURFACE_PLAYER_H
#define VIDEOPLAYBACKCONTROLONSURFACE_PLAYER_H

#include <atomic>
#include <mutex>
#include <thread>
#include <ohaudio/native_audiorenderer.h>
#include <ohaudio/native_audiostreambuilder.h>
#include "common/include/SampleInfo.h"
#include "capabilities/include/AudioDecoder.h"
#include "capabilities/include/Demuxer.h"
#include "capabilities/include/VideoDecoder.h"
#include "stdint.h"

class Player {
public:
    Player();
    ~Player();

    int32_t Init(SampleInfo &sampleInfo);
    int32_t Start();
    int32_t Pause();
    int32_t Resume();
    void SetSpeed(float speed);
    int64_t GetRenderTimeStamp()
    {
        return currentRenderTime_.load();
    };
    int32_t Seek(int64_t desTime);
    void StartRelease();

private:
    void VideoDecInputThread();
    void VideoDecOutputThread();
    void AudioDecInputThread();
    void AudioDecOutputThread();
    void Release();
    void ReleaseThread();

    int32_t CreateAudioDecoder();
    int32_t CreateVideoDecoder();
    int64_t GetCurrentTime();
    CodecBufferInfo GetBufferInfo();
    bool AudioToVideoSync(CodecBufferInfo bufferInfo, int64_t framePosition);
    std::unique_ptr<VideoDecoder> videoDecoder_ = nullptr;
    std::unique_ptr<AudioDecoder> audioDecoder_ = nullptr;
    std::unique_ptr<Demuxer> demuxer_ = nullptr;

    std::mutex mutex_;
    std::atomic<bool> isStarted_{false};
    std::atomic<bool> isPause_{false};
    std::atomic<bool> isReleased_{false};
    std::unique_ptr<std::thread> videoDecInputThread_ = nullptr;
    std::unique_ptr<std::thread> videoDecOutputThread_ = nullptr;
    std::unique_ptr<std::thread> audioDecInputThread_ = nullptr;
    std::unique_ptr<std::thread> audioDecOutputThread_ = nullptr;
    SampleInfo videoInfo_;
    CodecUserData *videoDecContext_ = nullptr;
    CodecUserData *audioDecContext_ = nullptr;
    OH_AudioStreamBuilder *builder_ = nullptr;
    OH_AudioRenderer *audioRenderer_ = nullptr;

    int64_t nowTimeStamp_ = 0;
    int64_t audioTimeStamp_ = 0;
    int64_t audioBufferPts_ = 0;

    std::atomic<bool> isReadRenderTime_{true};
    std::atomic<bool> isAudioWaitSeek_{false};
    std::atomic<int64_t> currentRenderTime_{0};
    float speed_ = 1.0f;
    bool isDecoding_ = true;

    static constexpr int64_t MICROSECOND = 1000000;
    static constexpr int64_t MILLISECONDS = 1000;
};

#endif // VIDEOPLAYBACKCONTROLONSURFACE_PLAYER_H