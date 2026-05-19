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

#ifndef VIDEOPLAYBACKCONTROLONSURFACE_VIDEOSAMPLEINFO_H
#define VIDEOPLAYBACKCONTROLONSURFACE_VIDEOSAMPLEINFO_H

#include <string>
#include "multimedia/player_framework/native_avcodec_base.h"

struct VideoSampleInfo {
    std::string videoCodecMime = "";
    int32_t videoWidth = 0;
    int32_t videoHeight = 0;
    int32_t videoRotation = 0;
    double frameRate = 0.0;
    OH_AVPixelFormat pixelFormat = AV_PIXEL_FORMAT_NV12;
    int64_t frameInterval = 0;
    int32_t hevcProfile = HEVC_PROFILE_MAIN;
    OHNativeWindow *window = nullptr;
};

#endif // VIDEOPLAYBACKCONTROLONSURFACE_VIDEOSAMPLEINFO_H
