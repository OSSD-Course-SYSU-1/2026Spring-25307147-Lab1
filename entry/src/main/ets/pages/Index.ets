/*
* Copyright (C) 2026 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import { hilog } from '@kit.PerformanceAnalysisKit';
import { display } from '@kit.ArkUI';
import { WindowUtil } from '../common/WindowUtil';
import { VideoPlayer } from '../view/VideoPlayer';
import { VideoData } from '../common/VideoData';
import CommonConstants from '../constants/CommonConstants';
import { MyDataSource, VideoDataModel } from '../common/VideoDataModel';

const DOMAIN = 0x0000; // Tag domain.

@Entry
@Component
struct Index {
  private swiperController: SwiperController = new SwiperController();
  private windowUtil: WindowUtil = WindowUtil.getInstance(); // Window-related utility class
  @State videoInfoList: Array<VideoDataModel> = []; // Video resource list
  @State isFullLandscapeScreen: boolean = false;
  @State isStart: boolean = true; // Playing or pause
  @State currentIndex: number = 0; // Index of the currently playing video
  @State screenWidth: number = 0; // Screen width

  aboutToAppear() {
    this.videoInfoList = [...VideoData];
    AppStorage.setOrCreate('swiperController', this.swiperController);
    // Get screenWidth
    this.getScreenWidth();
    // Monitor window size changes
    this.windowUtil.registerOnWindowSizeChange((size) => {
      hilog.info(DOMAIN, 'testTag', '%{public}s',
        'registerOnWindowSizeChange:' + ' width:' + size.width + ',height:' + size.height);
      if (size.width > size.height) {
        this.isFullLandscapeScreen = true;
      } else {
        this.isFullLandscapeScreen = false;
      }
      // Update screenWidth
      this.getScreenWidth();
    });
  }

  getScreenWidth() {
    display.getAllDisplays((err: BusinessError, data: Array<display.Display>) => {
      const errCode: number = err.code;
      if (errCode) {
        hilog.error(DOMAIN, 'testTag', '%{public}s',
          `Failed to obtain all the display objects. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      this.screenWidth = this.getUIContext().px2vp(data[0].width);
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'this.screenWidth:' + this.screenWidth);
    });
  }

  build() {
    Column() {
      Stack() {
        Column() {
          // [Start onAnimationStart]
          // [Start cachedCount]
          Swiper(this.swiperController) {
            LazyForEach(new MyDataSource(this.videoInfoList), (item: VideoDataModel, index: number) => {
              VideoPlayer({
                isFullLandscapeScreen: this.isFullLandscapeScreen, // fullLandscapeScreen state
                videoIndex: index, // Video index
                activeIndex: this.currentIndex, // Index of the currently playing video
                screenWidth: this.screenWidth // Screen width
              })
            }, (item: string) => item)
          }
          // [StartExclude onAnimationStart]
          .cachedCount(CommonConstants.CACHED_COUNT)
          // [End cachedCount]
          .vertical(true)
          .loop(true)
          .curve(Curve.Linear)
          .duration(CommonConstants.SWIPER_DURATION)
          .indicator(false)
          // [EndExclude onAnimationStart]
          .onAnimationStart((index: number, targetIndex: number) => {
            hilog.info(DOMAIN, 'testTag', '%{public}s',
              `onAnimationStart index:${index} , targetIndex: ${targetIndex}`);
            this.currentIndex = targetIndex; // Update current video index.
          })

          // [End onAnimationStart]
        }
        .backgroundColor(Color.Black)
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
