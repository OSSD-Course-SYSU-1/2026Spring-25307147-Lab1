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

#include <cstdint>
#include <hilog/log.h>
#include <js_native_api.h>
#include <js_native_api_types.h>
#include <string>
#include "XComponentManager.h"
#include "XComponentRender.h"

#undef LOG_TAG
#define LOG_TAG "XCOMPONENTRENDER"

constexpr uint32_t LOG_PRINT_DOMAIN = 0xFF00;

void OnSurfaceCreatedCB(OH_NativeXComponent *nativeXComponent, void *window)
{
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "Callback", "OnSurfaceCreatedCB");
    if ((nativeXComponent == nullptr) || (window == nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "Callback",
                     "OnSurfaceCreatedCB: component or window is null");
        return;
    }
    auto render = XComponentRender::GetInstance(nativeXComponent);
    uint64_t width;
    uint64_t height;
    int32_t xSize = OH_NativeXComponent_GetXComponentSize(nativeXComponent, window, &width, &height);
    if ((xSize == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) && (render != nullptr)) {
        auto context = XComponentManager::GetInstance();
        context->nativeWindow_ = (OHNativeWindow *)window;
        OH_NativeWindow_NativeWindowSetScalingModeV2(context->nativeWindow_, OH_SCALING_MODE_SCALE_FIT_V2);
    }
}

void OnSurfaceChangedCB(OH_NativeXComponent *nativeXComponent, void *window)
{
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "Callback", "OnSurfaceChangedCB");
    if ((nativeXComponent == nullptr) || (window == nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "Callback",
                     "OnSurfaceChangedCB: component or window is null");
        return;
    }
    auto render = XComponentRender::GetInstance(nativeXComponent);
    if (render != nullptr) {
        render->OnSurfaceChanged(nativeXComponent, window);
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "Callback", "surface changed");
    }
}

void OnSurfaceDestroyedCB(OH_NativeXComponent *nativeXComponent, void *window)
{
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "Callback", "OnSurfaceDestroyedCB");
    if ((nativeXComponent == nullptr) || (window == nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "Callback",
                     "OnSurfaceDestroyedCB: component or window is null");
        return;
    }
    
    XComponentRender::Release(nativeXComponent);
}

void DispatchTouchEventCB(OH_NativeXComponent *nativeXComponent, void *window)
{
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "Callback", "DispatchTouchEventCB");
    if ((nativeXComponent == nullptr) || (window == nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "Callback",
                     "DispatchTouchEventCB: component or window is null");
        return;
    }
    XComponentRender *render = XComponentRender::GetInstance(nativeXComponent);
    if (render != nullptr) {
        render->OnTouchEvent(nativeXComponent, window);
    } else {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "Callback", "DispatchTouchEventCB: render is nullptr");
    }
}

std::unordered_map<OH_NativeXComponent *, XComponentRender *> XComponentRender::instance_;
int32_t XComponentRender::hasDraw_ = 0;
int32_t XComponentRender::hasChangeColor_ = 0;

XComponentRender *XComponentRender::GetInstance(OH_NativeXComponent *nativeXComponent)
{
    if (instance_.find(nativeXComponent) == instance_.end()) {
        XComponentRender *instance = new XComponentRender();
        instance_[nativeXComponent] = instance;
        return instance;
    } else {
        return instance_[nativeXComponent];
    }
}

void XComponentRender::Export(napi_env env, napi_value exports)
{
    if ((env == nullptr) || (exports == nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "XComponentRender", "Export: env or exports is null");
        return;
    }

    napi_property_descriptor desc[] = {};
    if (napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc) != napi_ok) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "XComponentRender", "Export: napi_define_properties failed");
    }
}

void XComponentRender::Release(OH_NativeXComponent *nativeXComponent)
{
    auto it = instance_.find(nativeXComponent);
    if (it != instance_.end()) {
        delete it->second;
        it->second = nullptr;
        instance_.erase(it);
    }
}

void XComponentRender::OnSurfaceChanged(OH_NativeXComponent *nativeXComponent, void *window)
{
    double offsetX;
    double offsetY;
    OH_NativeXComponent_GetXComponentOffset(nativeXComponent, window, &offsetX, &offsetY);
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "OH_NativeXComponent_GetXComponentOffset",
                 "offsetX = %{public}lf, offsetY = %{public}lf", offsetX, offsetY);
    uint64_t width;
    uint64_t height;
    OH_NativeXComponent_GetXComponentSize(nativeXComponent, window, &width, &height);
}

void XComponentRender::OnTouchEvent(OH_NativeXComponent *nativeXComponent, void *window)
{
    OH_NativeXComponent_TouchEvent touchEvent;
    OH_NativeXComponent_GetTouchEvent(nativeXComponent, window, &touchEvent);
    float tiltX = 0.0f;
    float tiltY = 0.0f;
    OH_NativeXComponent_TouchPointToolType toolType =
        OH_NativeXComponent_TouchPointToolType::OH_NATIVEXCOMPONENT_TOOL_TYPE_UNKNOWN;
    OH_NativeXComponent_GetTouchPointToolType(nativeXComponent, 0, &toolType);
    OH_NativeXComponent_GetTouchPointTiltX(nativeXComponent, 0, &tiltX);
    OH_NativeXComponent_GetTouchPointTiltY(nativeXComponent, 0, &tiltY);
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "OnTouchEvent",
                 "touch info: toolType = %{public}d, tiltX = %{public}lf, tiltY = %{public}lf", toolType, tiltX, tiltY);
}

void XComponentRender::RegisterCallback(OH_NativeXComponent *nativeXComponent)
{
    renderCallback_.OnSurfaceCreated = OnSurfaceCreatedCB;
    renderCallback_.OnSurfaceChanged = OnSurfaceChangedCB;
    renderCallback_.OnSurfaceDestroyed = OnSurfaceDestroyedCB;
    renderCallback_.DispatchTouchEvent = DispatchTouchEventCB;
    OH_NativeXComponent_RegisterCallback(nativeXComponent, &renderCallback_);
}