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

#include "MediaError.h"
#include "MediaLog.h"
#include "Player.h"
#include "XComponentManager.h"
#include "common/include/SampleInfo.h"
#include "PlayerNative.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0xFF00
#define LOG_TAG "PlayerNative"

constexpr int FIRST_PARAM = 0;
constexpr int SECOND_PARAM = 1;
constexpr int THIRD_PARAM = 2;
constexpr int FOURTH_PARAM = 3;

struct AsyncCallbackInfo {
    napi_env env;
    napi_async_work asyncWork;
    napi_deferred deferred;
    int32_t resultCode = -1;
    std::string resultStr = "";
    SampleInfo sampleInfo;
    int64_t addrValue;
};

void SetCallBackResult(AsyncCallbackInfo *asyncCallbackInfo, int32_t code, std::string str)
{
    asyncCallbackInfo->resultCode = code;
    asyncCallbackInfo->resultStr = str;
}

void DealCallBack(napi_env env, void *data)
{
    AsyncCallbackInfo *asyncCallbackInfo = static_cast<AsyncCallbackInfo *>(data);
    napi_value videoWidth;
    napi_create_int32(env, asyncCallbackInfo->sampleInfo.videoInfo.videoWidth, &videoWidth);
    napi_value videoHeight;
    napi_create_int32(env, asyncCallbackInfo->sampleInfo.videoInfo.videoHeight, &videoHeight);
    napi_value durationTime;
    napi_create_int64(env, asyncCallbackInfo->sampleInfo.durationTime, &durationTime);
    napi_value code;
    napi_create_int32(env, asyncCallbackInfo->resultCode, &code);
    napi_value message;
    napi_create_string_utf8(env, asyncCallbackInfo->resultStr.data(), NAPI_AUTO_LENGTH, &message);
    napi_value obj;
    napi_create_object(env, &obj);

    napi_set_named_property(env, obj, "code", code);
    napi_set_named_property(env, obj, "videoWidth", videoWidth);
    napi_set_named_property(env, obj, "videoHeight", videoHeight);
    napi_set_named_property(env, obj, "durationTime", durationTime);
    napi_set_named_property(env, obj, "message", message);
    napi_resolve_deferred(asyncCallbackInfo->env, asyncCallbackInfo->deferred, obj);
    napi_delete_async_work(env, asyncCallbackInfo->asyncWork);
    delete asyncCallbackInfo;
}

napi_value PlayerNative::CreatePlayer(napi_env env, napi_callback_info info)
{
    MEDIA_LOGI("CreatePlayer: enter");
    Player *player = new Player();
    int64_t addrValue = reinterpret_cast<int64_t>(player);
    
    napi_value result;
    napi_create_bigint_int64(env, addrValue, &result);
    MEDIA_LOGI("CreatePlayer: exit, addrValue=%{public}ld", addrValue);
    return result;
}

napi_value PlayerNative::ReleasePlayer(napi_env env, napi_callback_info info)
{
    MEDIA_LOGI("ReleasePlayer: enter");
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool flag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &flag);
    
    if (flag) {
        Player *player = reinterpret_cast<Player *>(addrValue);
        if (player != nullptr) {
            player->StartRelease();
            delete player;
            MEDIA_LOGI("ReleasePlayer: player deleted, addrValue=%{public}ld", addrValue);
        }
    }
    
    return nullptr;
}

void InitializePlayer(napi_env env, void *data)
{
    CHECK_AND_RETURN_LOG(env != nullptr, "env or info is null");
    AsyncCallbackInfo *asyncCallbackInfo = static_cast<AsyncCallbackInfo *>(data);
    
    Player *player = reinterpret_cast<Player *>(asyncCallbackInfo->addrValue);
    CHECK_AND_RETURN_LOG(player != nullptr, "player is null");
    
    int32_t ret = player->Init(asyncCallbackInfo->sampleInfo);
    SetCallBackResult(asyncCallbackInfo, ret, "Player init finish");
}

napi_value PlayerNative::Init(napi_env env, napi_callback_info info)
{
    SampleInfo sampleInfo;
    size_t argc = 4;
    napi_value args[4] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool flag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &flag);
    napi_get_value_int32(env, args[SECOND_PARAM], &sampleInfo.inputFd);
    napi_get_value_int64(env, args[THIRD_PARAM], &sampleInfo.inputFileOffset);
    napi_get_value_int64(env, args[FOURTH_PARAM], &sampleInfo.inputFileSize);
    
    napi_value promise;
    napi_deferred deferred;
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_create_promise(env, &deferred, &promise), nullptr,
        "Initialize: Create promise failed");
    auto asyncCallbackInfo = std::make_unique<AsyncCallbackInfo>();
    asyncCallbackInfo->env = env;
    asyncCallbackInfo->asyncWork = nullptr;
    asyncCallbackInfo->deferred = deferred;
    asyncCallbackInfo->sampleInfo = sampleInfo;
    asyncCallbackInfo->addrValue = addrValue;
    napi_value resourceName;
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_create_string_latin1(env, "Initialize", NAPI_AUTO_LENGTH, &resourceName),
        nullptr, "Initialize: Create resourceName failed");
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_create_async_work(env, nullptr, resourceName,
        [](napi_env env, void *data) { InitializePlayer(env, data); },
        [](napi_env env, napi_status status, void *data) { DealCallBack(env, data); },
        static_cast<void *>(asyncCallbackInfo.get()), &asyncCallbackInfo->asyncWork), nullptr,
        "Initialize: Create async work failed");
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_queue_async_work(env, asyncCallbackInfo->asyncWork), nullptr,
        "Initialize: queue_async_work failed");
    asyncCallbackInfo.release();
    return promise;
}

napi_value PlayerNative::Play(napi_env env, napi_callback_info info)
{
    CHECK_AND_RETURN_RET_LOG(env != nullptr && info != nullptr, nullptr, "env or info is null");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool flag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &flag);
    CHECK_AND_RETURN_RET_LOG(flag, nullptr, "player id is invalid");
    
    Player *player = reinterpret_cast<Player *>(addrValue);
    CHECK_AND_RETURN_RET_LOG(player != nullptr, nullptr, "player is null");
    
    int32_t ret = player->Start();
    if (ret != MEDIA_ERR_OK) {
        MEDIA_LOGE("Player play failed.");
    }
    return nullptr;
}

napi_value PlayerNative::Pause(napi_env env, napi_callback_info info)
{
    CHECK_AND_RETURN_RET_LOG(env != nullptr && info != nullptr, nullptr, "env or info is null");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool flag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &flag);
    CHECK_AND_RETURN_RET_LOG(flag, nullptr, "player id is invalid");
    
    Player *player = reinterpret_cast<Player *>(addrValue);
    CHECK_AND_RETURN_RET_LOG(player != nullptr, nullptr, "player is null");
    
    int32_t ret = player->Pause();
    if (ret != MEDIA_ERR_OK) {
        MEDIA_LOGE("Player pause failed.");
    }
    return nullptr;
}

napi_value PlayerNative::Resume(napi_env env, napi_callback_info info)
{
    CHECK_AND_RETURN_RET_LOG(env != nullptr && info != nullptr, nullptr, "env or info is null");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool flag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &flag);
    CHECK_AND_RETURN_RET_LOG(flag, nullptr, "player id is invalid");
    
    Player *player = reinterpret_cast<Player *>(addrValue);
    CHECK_AND_RETURN_RET_LOG(player != nullptr, nullptr, "player is null");
    
    int32_t ret = player->Resume();
    if (ret != MEDIA_ERR_OK) {
        MEDIA_LOGE("Player resume failed.");
    }
    return nullptr;
}

napi_value PlayerNative::SetSpeed(napi_env env, napi_callback_info info)
{
    CHECK_AND_RETURN_RET_LOG(env != nullptr && info != nullptr, nullptr, "env or info is null");
    
    size_t argc = 2;
       napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool addrFlag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &addrFlag);
    CHECK_AND_RETURN_RET_LOG(addrFlag, nullptr, "player id is invalid");
    
    Player *player = reinterpret_cast<Player *>(addrValue);
    CHECK_AND_RETURN_RET_LOG(player != nullptr, nullptr, "player is null");
    
    double speed;
    napi_get_value_double(env, args[SECOND_PARAM], &speed);
    player->SetSpeed(static_cast<float>(speed));
    return nullptr;
}

napi_value PlayerNative::GetRenderTime(napi_env env, napi_callback_info info)
{
    CHECK_AND_RETURN_RET_LOG(env != nullptr && info != nullptr, nullptr, "env or info is null");
    
    size_t argc = 1;
       napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool flag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &flag);
    CHECK_AND_RETURN_RET_LOG(flag, nullptr, "player id is invalid");
    
    Player *player = reinterpret_cast<Player *>(addrValue);
    CHECK_AND_RETURN_RET_LOG(player != nullptr, nullptr, "player is null");
    
    int64_t res = player->GetRenderTimeStamp();
    napi_value result;
    napi_create_int64(env, res, &result);
    return result;
}

void SeekVideoWorker(napi_env env, void *data)
{
    CHECK_AND_RETURN_LOG(env != nullptr, "env is null");
    AsyncCallbackInfo *asyncCallbackInfo = static_cast<AsyncCallbackInfo *>(data);
    
    Player *player = reinterpret_cast<Player *>(asyncCallbackInfo->addrValue);
    CHECK_AND_RETURN_LOG(player != nullptr, "player is null");
    
    int32_t ret = player->Seek(asyncCallbackInfo->sampleInfo.durationTime);
    SetCallBackResult(asyncCallbackInfo, ret, "Seek video finish");
}

napi_value PlayerNative::SeekVideo(napi_env env, napi_callback_info info)
{
    CHECK_AND_RETURN_RET_LOG(env != nullptr && info != nullptr, nullptr, "env or info is null");
    
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t addrValue = 0;
    bool addrFlag = false;
    napi_get_value_bigint_int64(env, args[FIRST_PARAM], &addrValue, &addrFlag);
    CHECK_AND_RETURN_RET_LOG(addrFlag, nullptr, "player id is invalid");
    
    int64_t currentTime = 0;
    napi_get_value_int64(env, args[SECOND_PARAM], &currentTime);

    napi_value promise;
    napi_deferred deferred;
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_create_promise(env, &deferred, &promise), nullptr,
        "SeekVideo: Create promise failed");
    
    auto asyncCallbackInfo = std::make_unique<AsyncCallbackInfo>();
    asyncCallbackInfo->env = env;
    asyncCallbackInfo->asyncWork = nullptr;
    asyncCallbackInfo->deferred = deferred;
    asyncCallbackInfo->sampleInfo.durationTime = currentTime;
    asyncCallbackInfo->addrValue = addrValue;
    
    napi_value resourceName;
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_create_string_latin1(env, "SeekVideo", NAPI_AUTO_LENGTH, &resourceName),
        nullptr, "SeekVideo: Create resourceName failed");
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_create_async_work(env, nullptr, resourceName,
        [](napi_env env, void *data) { SeekVideoWorker(env, data); },
        [](napi_env env, napi_status status, void *data) { DealCallBack(env, data); },
        static_cast<void *>(asyncCallbackInfo.get()), &asyncCallbackInfo->asyncWork), nullptr,
        "SeekVideo: Create async work failed");
    CHECK_AND_RETURN_RET_LOG(napi_ok == napi_queue_async_work(env, asyncCallbackInfo->asyncWork), nullptr,
        "SeekVideo: queue_async_work failed");
    asyncCallbackInfo.release();
    
    return promise;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"createPlayer", nullptr, PlayerNative::CreatePlayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"releasePlayer", nullptr, PlayerNative::ReleasePlayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"play", nullptr, PlayerNative::Play, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pause", nullptr, PlayerNative::Pause, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resume", nullptr, PlayerNative::Resume, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getRenderTime", nullptr, PlayerNative::GetRenderTime, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSpeed", nullptr, PlayerNative::SetSpeed, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"seekVideo", nullptr, PlayerNative::SeekVideo, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"init", nullptr, PlayerNative::Init, nullptr, nullptr, nullptr, napi_default, nullptr}};
    XComponentManager::GetInstance()->Export(env, exports);
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module playerModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "player",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&playerModule); }