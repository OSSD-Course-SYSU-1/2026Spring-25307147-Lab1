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

#include <shared_mutex>
#include "MediaError.h"
#include "MediaLog.h"
#include "CodecCallback.h"
#include "VideoDecoder.h"

#undef LOG_TAG
#define LOG_TAG "VideoDecoder"

VideoDecoder::~VideoDecoder()
{
    Release();
}

int32_t VideoDecoder::Create(const std::string &videoCodecMime)
{
    decoder_ = OH_VideoDecoder_CreateByMime(videoCodecMime.c_str());
    CHECK_AND_RETURN_RET_LOG(decoder_ != nullptr, MEDIA_ERR_ERROR, "Create failed");
    return MEDIA_ERR_OK;
}

int32_t VideoDecoder::Start()
{
    CHECK_AND_RETURN_RET_LOG(decoder_ != nullptr, MEDIA_ERR_ERROR, "Decoder is null");

    int ret = OH_VideoDecoder_Start(decoder_);
    CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "Start failed, ret: %{public}d", ret);
    return MEDIA_ERR_OK;
}

int32_t VideoDecoder::Config(const SampleInfo &sampleInfo, CodecUserData *codecUserData)
{
    CHECK_AND_RETURN_RET_LOG(decoder_ != nullptr, MEDIA_ERR_ERROR, "Decoder is null");
    CHECK_AND_RETURN_RET_LOG(codecUserData != nullptr, MEDIA_ERR_ERROR, "Invalid param: codecUserData");

    // Configure video decoder
    int32_t ret = Configure(sampleInfo);
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR, "Configure failed");

    // SetSurface from video decoder
    if (sampleInfo.videoInfo.window != nullptr) {
        int ret = OH_VideoDecoder_SetSurface(decoder_, sampleInfo.videoInfo.window);
        CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK && sampleInfo.videoInfo.window, MEDIA_ERR_ERROR,
            "Set surface failed, ret: %{public}d", ret);
    }

    // SetCallback for video decoder
    ret = SetCallback(codecUserData);
    CHECK_AND_RETURN_RET_LOG(ret == MEDIA_ERR_OK, MEDIA_ERR_ERROR,
                             "Set callback failed, ret: %{public}d", ret);

    // Prepare video decoder
    {
        int ret = OH_VideoDecoder_Prepare(decoder_);
        CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "Prepare failed, ret: %{public}d", ret);
    }

    return MEDIA_ERR_OK;
}

int32_t VideoDecoder::Configure(const SampleInfo &sampleInfo)
{
    OH_AVFormat *format = OH_AVFormat_Create();
    CHECK_AND_RETURN_RET_LOG(format != nullptr, MEDIA_ERR_ERROR, "AVFormat create failed");
    
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_ROTATION, sampleInfo.videoInfo.videoRotation);
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_HEIGHT, sampleInfo.videoInfo.videoHeight);
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_WIDTH, sampleInfo.videoInfo.videoWidth);
    OH_AVFormat_SetDoubleValue(format, OH_MD_KEY_FRAME_RATE, sampleInfo.videoInfo.frameRate);
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_PIXEL_FORMAT, sampleInfo.videoInfo.pixelFormat);

    MEDIA_LOGI("====== VideoDecoder config ======");
    MEDIA_LOGI("%{public}d*%{public}d, %{public}.1ffps", sampleInfo.videoInfo.videoWidth,
        sampleInfo.videoInfo.videoHeight, sampleInfo.videoInfo.frameRate);
    MEDIA_LOGI("====== VideoDecoder config ======");

    int ret = OH_VideoDecoder_Configure(decoder_, format);
    OH_AVFormat_Destroy(format);
    format = nullptr;
    CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "Config failed, ret: %{public}d", ret);
    return MEDIA_ERR_OK;
}

int32_t VideoDecoder::SetCallback(CodecUserData *codecUserData)
{
    int32_t ret = AV_ERR_OK;
    ret = OH_VideoDecoder_RegisterCallback(decoder_,
        {CodecCallback::OnCodecError, CodecCallback::OnCodecFormatChange,
         CodecCallback::OnNeedInputBuffer, CodecCallback::OnNewOutputBuffer}, codecUserData);
    CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "Set callback failed, ret: %{public}d", ret);

    return MEDIA_ERR_OK;
}

int32_t VideoDecoder::Release()
{
    if (decoder_ != nullptr) {
        OH_VideoDecoder_Flush(decoder_);
        OH_VideoDecoder_Stop(decoder_);
        OH_VideoDecoder_Destroy(decoder_);
        decoder_ = nullptr;
    }
    return MEDIA_ERR_OK;
}

int32_t VideoDecoder::PushInputBuffer(CodecBufferInfo &info)
{
    CHECK_AND_RETURN_RET_LOG(decoder_ != nullptr, MEDIA_ERR_ERROR, "Decoder is null");
    int32_t ret = OH_VideoDecoder_PushInputBuffer(decoder_, info.bufferIndex);
    CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "Push input data failed");
    return MEDIA_ERR_OK;
}

// [Start RenderOutputBuffer]
int32_t VideoDecoder::RenderOutputBuffer(uint32_t bufferIndex, bool render)
{
    CHECK_AND_RETURN_RET_LOG(decoder_ != nullptr, MEDIA_ERR_ERROR, "Decoder is null");
    int32_t ret = MEDIA_ERR_OK;
    // Check if render.
    if (render) {
        // Get timestamp for render time.
        int64_t renderTimestamp = std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::high_resolution_clock::now().time_since_epoch()).count();
        // Notify video decode to render by surface.
        ret = OH_VideoDecoder_RenderOutputBufferAtTime(decoder_, bufferIndex, renderTimestamp);
    } else {
        // Free buffer that does not need to be rendered.
        ret = OH_VideoDecoder_FreeOutputBuffer(decoder_, bufferIndex);
    }
    CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "Render output data failed, RET = %{public}d", ret);
    return MEDIA_ERR_OK;
}
// [End RenderOutputBuffer]

int32_t VideoDecoder::Flush(CodecUserData *userdata)
{
    CHECK_AND_RETURN_RET_LOG(userdata != nullptr, MEDIA_ERR_ERROR, "Invalid userdata ptr");
    std::unique_lock<std::shared_mutex> flushLock(userdata->flushMutex_);
    int32_t ret = OH_VideoDecoder_Flush(decoder_);
    CHECK_AND_RETURN_RET_LOG(ret == AV_ERR_OK, MEDIA_ERR_ERROR, "flush failed, ret: %{public}d", ret);
    flushLock.unlock();
    return MEDIA_ERR_OK;
}