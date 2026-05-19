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

#include <ace/xcomponent/native_interface_xcomponent.h>
#include <cstdint>
#include <hilog/log.h>
#include <string>
#include "XComponentManager.h"

#undef LOG_TAG
#define LOG_TAG "XCOMPONENTMANAGER"

constexpr uint32_t LOG_PRINT_DOMAIN = 0xFF00;
XComponentManager XComponentManager::XComponentManager_;

XComponentManager::~XComponentManager()
{
    OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "Callback", "~XComponentManager");
    for (auto iter = nativeXComponentSet_.begin(); iter != nativeXComponentSet_.end();) {
        if (*iter != nullptr) {
            delete *iter;
            iter = nativeXComponentSet_.erase(iter);
        } else {
            ++iter;
        }
    }
    nativeXComponentSet_.clear();
    
    if (nativeWindow_) {
        delete nativeWindow_;
        nativeWindow_ = nullptr;
    }
}

void XComponentManager::Export(napi_env env, napi_value exports)
{
    if ((env == nullptr) || (exports == nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "XComponentManager", "Export: env or exports is null");
        return;
    }

    napi_value exportInstance = nullptr;
    if (napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance) != napi_ok) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "XComponentManager", "Export: napi_get_named_property fail");
        return;
    }

    OH_NativeXComponent *nativeXComponent = nullptr;
    if (napi_unwrap(env, exportInstance, reinterpret_cast<void **>(&nativeXComponent)) != napi_ok) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "XComponentManager", "Export: napi_unwrap fail");
        return;
    }

    auto context = XComponentManager::GetInstance();
    if ((context != nullptr) && (nativeXComponent != nullptr)) {
        context->SetNativeXComponent(nativeXComponent);
        auto render = context->GetRender(nativeXComponent);
        if (render != nullptr) {
            render->RegisterCallback(nativeXComponent);
            render->Export(env, exports);
        }
    }
}

void XComponentManager::SetNativeXComponent(OH_NativeXComponent *nativeXComponent)
{
    if (nativeXComponent == nullptr) {
        return;
    }

    if (nativeXComponentSet_.find(nativeXComponent) == nativeXComponentSet_.end()) {
        nativeXComponentSet_.insert(nativeXComponent);
    }
}

XComponentRender *XComponentManager::GetRender(OH_NativeXComponent *nativeXComponent)
{
    XComponentRender *instance = XComponentRender::GetInstance(nativeXComponent);
    return instance;
}