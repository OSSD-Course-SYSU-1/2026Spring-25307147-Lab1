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

#include <mutex>
#include "MediaLog.h"
#include "CodecCallback.h"

namespace {
constexpr int LIMIT_LOGD_FREQUENCY = 50;
constexpr int32_t BYTES_PER_SAMPLE_2 = 2;
} // namespace

// Custom write data function
OH_AudioData_Callback_Result CodecCallback::OnRenderWriteData(
    OH_AudioRenderer *renderer, void *userData, void *audioData, int32_t audioDataSize)
{
    (void)renderer;
    (void)audioDataSize;
    CodecUserData *codecUserData = static_cast<CodecUserData *>(userData);

    // Write the data to be played to the buffer by length
    uint8_t *dest = (uint8_t *)audioData;
    size_t index = 0;
    std::unique_lock<std::mutex> lock(codecUserData->outputMutex);
    // Retrieve the length of the data to be played from the queue
    while (!codecUserData->renderQueue.empty() && index < audioDataSize) {
        dest[index++] = codecUserData->renderQueue.front();
        codecUserData->renderQueue.pop();
    }
    MEDIA_LOGI("render BufferLength:%{public}d Out buffer count: %{public}u, renderQueue.size: %{public}u "
               "renderReadSize: %{public}u",
               audioDataSize, codecUserData->outputFrameCount, (unsigned int)codecUserData->renderQueue.size(),
               (unsigned int)index);

    // SAMPLE_S16LE 2 bytes per frame
    // If set speed, cnt / speed
    codecUserData->frameWrittenForSpeed += audioDataSize / codecUserData->speed /
        codecUserData->sampleInfo->audioInfo.audioChannelCount / BYTES_PER_SAMPLE_2;
    codecUserData->currentPosAudioBufferPts =
        codecUserData->endPosAudioBufferPts - codecUserData->renderQueue.size() /
        codecUserData->sampleInfo->audioInfo.audioSampleRate /
        codecUserData->sampleInfo->audioInfo.audioChannelCount /
        BYTES_PER_SAMPLE_2;

    if (codecUserData->renderQueue.size() < audioDataSize) {
        codecUserData->renderCond.notify_all();
    }
    lock.unlock();
    return AUDIO_DATA_CALLBACK_RESULT_VALID;
}
// Customize the audio stream event function
int32_t CodecCallback::OnRenderStreamEvent(OH_AudioRenderer *renderer, void *userData, OH_AudioStream_Event event)
{
    (void)renderer;
    (void)userData;
    (void)event;
    // Update the player status and interface based on the audio stream event information represented by the event
    return 0;
}
// Customize the audio interrupt event function
int32_t CodecCallback::OnRenderInterruptEvent(OH_AudioRenderer *renderer, void *userData,
                                              OH_AudioInterrupt_ForceType type, OH_AudioInterrupt_Hint hint)
{
    (void)renderer;
    (void)userData;
    (void)type;
    (void)hint;
    // Update the player status and interface based on the audio interrupt information indicated by type and hint
    return 0;
}
// Custom exception callback functions
int32_t CodecCallback::OnRenderError(OH_AudioRenderer *renderer, void *userData, OH_AudioStream_Result error)
{
    (void)renderer;
    (void)userData;
    (void)error;
    MEDIA_LOGE("OnRenderError");
    // Handle the audio exception information based on the error message
    return 0;
}

void CodecCallback::OnCodecError(OH_AVCodec *codec, int32_t errorCode, void *userData)
{
    (void)codec;
    (void)errorCode;
    (void)userData;
    MEDIA_LOGE("On codec error, error code: %{public}d", errorCode);
}

void CodecCallback::OnCodecFormatChange(OH_AVCodec *codec, OH_AVFormat *format, void *userData)
{
    MEDIA_LOGI("On codec format change, codec: %{public}p, format: %{public}p, userData: %{public}p", codec, format,
               userData);
}

void CodecCallback::OnNeedInputBuffer(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer, void *userData)
{
    if (userData == nullptr) {
        return;
    }
    (void)codec;
    CodecUserData *codecUserData = static_cast<CodecUserData *>(userData);
    std::unique_lock<std::mutex> lock(codecUserData->inputMutex);
    if (codecUserData->isFlushing) {
        return;
    }
    codecUserData->inputBufferInfoQueue.emplace(index, buffer);
    codecUserData->inputCond.notify_all();
    lock.unlock();
}

void CodecCallback::OnNewOutputBuffer(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer, void *userData)
{
    if (userData == nullptr) {
        return;
    }
    (void)codec;
    CodecUserData *codecUserData = static_cast<CodecUserData *>(userData);
    std::unique_lock<std::mutex> lock(codecUserData->outputMutex);
    if (codecUserData->isFlushing) {
        return;
    }
    codecUserData->outputBufferInfoQueue.emplace(index, buffer);
    codecUserData->outputCond.notify_all();
    lock.unlock();
}