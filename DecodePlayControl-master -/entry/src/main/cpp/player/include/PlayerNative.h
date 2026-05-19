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

#ifndef VIDEOPLAYBACKCONTROLONSURFACE_PLAYERNATIVE_H
#define VIDEOPLAYBACKCONTROLONSURFACE_PLAYERNATIVE_H

#include <js_native_api.h>
#include <js_native_api_types.h>
#include "napi/native_api.h"

class PlayerNative {
public:
    static napi_value CreatePlayer(napi_env env, napi_callback_info info);
    static napi_value ReleasePlayer(napi_env env, napi_callback_info info);
    static napi_value Init(napi_env env, napi_callback_info info);
    static napi_value Play(napi_env env, napi_callback_info info);
    static napi_value Pause(napi_env env, napi_callback_info info);
    static napi_value Resume(napi_env env, napi_callback_info info);
    static napi_value SetSpeed(napi_env env, napi_callback_info info);
    static napi_value GetRenderTime(napi_env env, napi_callback_info info);
    static napi_value SeekVideo(napi_env env, napi_callback_info info);
};
#endif // VIDEOPLAYBACKCONTROLONSURFACE_PLAYERNATIVE_H