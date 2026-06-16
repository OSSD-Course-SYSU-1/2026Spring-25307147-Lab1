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

#ifndef VIDEOPLAYBACKCONTROLONSURFACE_SAMPLEINFO_H
#define VIDEOPLAYBACKCONTROLONSURFACE_SAMPLEINFO_H

#include <mutex>
#include <queue>
#include <shared_mutex>
#include "multimedia/player_framework/native_avcodec_base.h"
#include "stdint.h"
#include "VideoSampleInfo.h"
#include "AudioSampleInfo.h"

struct SampleInfo {
    int32_t inputFd = -1;        // Input video file fd.
    int64_t inputFileOffset = 0; // Input video file offset.
    int64_t inputFileSize = 0;   // Input video file size.
    int64_t durationTime = 0;
    int64_t bitrate = 10 * 1024 * 1024; // 10Mbps.

    VideoSampleInfo videoInfo;
    AudioSampleInfo audioInfo;
};

struct CodecBufferInfo {
    uint32_t bufferIndex = 0;
    uintptr_t *buffer = nullptr;
    uint8_t *bufferAddr = nullptr;
    OH_AVCodecBufferAttr attr = {0, 0, 0, AVCODEC_BUFFER_FLAGS_NONE};

    explicit CodecBufferInfo(uint8_t *addr) : bufferAddr(addr){};
    CodecBufferInfo(uint8_t *addr, int32_t bufferSize)
        : bufferAddr(addr), attr({0, bufferSize, 0, AVCODEC_BUFFER_FLAGS_NONE}){};
    CodecBufferInfo(uint32_t argBufferIndex, OH_AVBuffer *argBuffer)
        : bufferIndex(argBufferIndex), buffer(reinterpret_cast<uintptr_t *>(argBuffer))
    {
        OH_AVBuffer_GetBufferAttr(argBuffer, &attr);
    };
};

struct CodecUserData {
public:
    SampleInfo *sampleInfo = nullptr;
    std::queue<unsigned char> renderQueue;
    std::atomic<bool> isFlushing{false};
    std::shared_mutex flushMutex_;

    uint32_t inputFrameCount = 0;
    std::mutex inputMutex;
    std::condition_variable inputCond;
    std::queue<CodecBufferInfo> inputBufferInfoQueue;

    uint32_t outputFrameCount = 0;
    std::mutex outputMutex;
    std::condition_variable outputCond;
    std::mutex renderMutex;
    std::condition_variable renderCond;
    std::mutex endMutex;
    std::condition_variable endCond;
    std::queue<CodecBufferInfo> outputBufferInfoQueue;

    float speed = 1.0f;
    int64_t frameWrittenForSpeed = 0;
    int64_t endPosAudioBufferPts = 0;
    int64_t currentPosAudioBufferPts = 0;

    void ClearQueue()
    {
        std::unique_lock<std::mutex> inputLock(inputMutex);
        auto inputEmptyQueue = std::queue<CodecBufferInfo>();
        inputBufferInfoQueue.swap(inputEmptyQueue);
        inputLock.unlock();

        std::unique_lock<std::mutex> outputLock(outputMutex);
        auto outputEmptyQueue = std::queue<CodecBufferInfo>();
        outputBufferInfoQueue.swap(outputEmptyQueue);
        outputLock.unlock();
    }
};
#endif // VIDEOPLAYBACKCONTROLONSURFACE_SAMPLEINFO_H
