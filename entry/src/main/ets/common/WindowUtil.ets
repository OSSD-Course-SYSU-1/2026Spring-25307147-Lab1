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

import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = '[WindowUtil]';

export class WindowUtil {
  private static instance: WindowUtil;
  private windowStage?: window.WindowStage;
  private mainWindowClass?: window.Window;

  private constructor() {}

  public static getInstance() {
    if (!WindowUtil.instance) {
      WindowUtil.instance = new WindowUtil();
    }
    return WindowUtil.instance;
  }

  public setWindowStage(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
    this.windowStage.getMainWindow((err: BusinessError, windowClass: window.Window) => {
      if (err.code) {
        hilog.error(0x0000, TAG, `Failed to obtain the main window. Code:${err.code}, message:${err.message}`);
        return;
      }
      this.mainWindowClass = windowClass;
    });
  }

  setMainWindowOrientation(orientation: window.Orientation, callback?: Function): void {
    if (this.mainWindowClass === undefined) {
      hilog.error(0x0000, TAG, 'MainWindowClass is undefined');
      return;
    }
    this.mainWindowClass.setPreferredOrientation(orientation).then(() => {
      callback?.();
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG,
        `Failed to set the ${orientation} of main window. Code:${err.code}, message:${err.message}`);
    });
  }

  disableWindowSystemBar(): void {
    if (!this.mainWindowClass) {
      hilog.error(0x0000, TAG, 'MainWindowClass is undefined');
      return;
    }
    this.mainWindowClass.setWindowSystemBarEnable([]).catch(() => {
      hilog.error(0x0000, TAG, 'setWindowSystemBarEnable is failed');
    });
  }

  enableWindowSystemBar(): void {
    if (!this.mainWindowClass) {
      hilog.error(0x0000, TAG, 'MainWindowClass is undefined');
      return;
    }
    this.mainWindowClass.setWindowSystemBarEnable(['status', 'navigation']).catch(() => {
      hilog.error(0x0000, TAG, 'setWindowSystemBarEnable is failed');
    });
  }

  setLandscapeMultiWindow(enable: boolean) {
    if (!this.mainWindowClass) {
      hilog.error(0x0000, TAG, 'MainWindowClass is undefined');
      return;
    }
    if (enable) {
      this.mainWindowClass.enableLandscapeMultiWindow().catch(() => {
        hilog.error(0x0000, TAG, 'enableLandscapeMultiWindow is failed');
      });
    } else {
      this.mainWindowClass.disableLandscapeMultiWindow().catch(() => {
        hilog.error(0x0000, TAG, 'disableLandscapeMultiWindow is failed');
      });
    }
  }

  registerOnWindowSizeChange(callback?: (size: window.Size) => void) {
    if (!this.mainWindowClass) {
      hilog.error(0x0000, TAG, 'MainWindowClass is undefined');
      return;
    }
    this.mainWindowClass.off('windowSizeChange');
    this.mainWindowClass.on('windowSizeChange', (size) => {
      callback?.(size);
    });
  }

  registerOffWindowSizeChange() {
    if (!this.mainWindowClass) {
      hilog.error(0x0000, TAG, 'MainWindowClass is undefined');
      return;
    }
    this.mainWindowClass.off('windowSizeChange');
  }

  // Full screen mode back to normal mode.
  public handleFullScreenExit(isLandscape: boolean) {
    if (isLandscape) {
      return;
    }
    this.enableWindowSystemBar();
    this.setLandscapeMultiWindow(false);
    this.setMainWindowOrientation(window.Orientation.USER_ROTATION_PORTRAIT);
  }

  // Enter full screen mode.
  public handleFullScreen(isLandscape: boolean) {
    if (isLandscape) {
      this.disableWindowSystemBar();
      this.setLandscapeMultiWindow(true);
      this.setMainWindowOrientation(window.Orientation.USER_ROTATION_LANDSCAPE);
    }
  }
}