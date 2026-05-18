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

import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { VideoPlayView } from '../view/VideoPlayView';
import { VideoPlayViewModel } from '../viewmodel/VideoPlayViewModel';

const VIDEO_NAMES = ['1.mp4', '2.mp4', '3.mp4'];
const TAG = 'INDEX';

@Entry
@Component
struct Index {
  @State videoResources : resourceManager.RawFileDescriptor[] = [];
  @State viewModel: VideoPlayViewModel = new VideoPlayViewModel();
  @State isFullScreen: boolean = false;

  aboutToAppear(): void {
    try {
      this.videoResources.length = 0;
      for (let i = 0; i< VIDEO_NAMES.length; i++) {
        let rawDes = this.getUIContext().getHostContext()?.resourceManager.getRawFdSync(VIDEO_NAMES[i]);
        if (rawDes) {
          this.videoResources.push(rawDes);
        }
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `aboutToAppear catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  aboutToDisappear(): void {
    try {
      for (let i = 0; i< VIDEO_NAMES.length; i++) {
        this.getUIContext().getHostContext()?.resourceManager.closeRawFdSync(VIDEO_NAMES[i]);
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `aboutToDisappear catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  onBackPress(): boolean | void {
    if (this.isFullScreen) {
      this.isFullScreen = false;
      return true;
    }
    return false;
  }

  build() {
    Column() {
      VideoPlayView({
        viewModel: this.viewModel,
        videoSources: $videoResources,
        isFullScreen: this.isFullScreen
      });
    }
    .width('100%')
    .height('100%')
  }
}