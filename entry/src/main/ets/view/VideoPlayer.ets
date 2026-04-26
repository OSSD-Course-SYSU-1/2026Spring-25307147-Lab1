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

import { hilog } from '@kit.PerformanceAnalysisKit';
import { WindowUtil } from '../common/WindowUtil';
import { VideoDataModel } from '../common/VideoDataModel';
import { formatVideoTime } from '../common/TimeUtils';
import { SetVolume } from '../view/SetVolume';
import { VideoData } from '../common/VideoData';
import CommonConstants from '../constants/CommonConstants';

const DOMAIN = 0x0000; // Tag domain.

@Component
export struct VideoPlayer {
  // [Start isForeGround]
  @Watch('foregroundStatus') @StorageLink('isForeGround') isForeGround: boolean = false;
  // [End isForeGround]
  // [Start activeIndexChange]
  @Prop @Watch('activeIndexChange') activeIndex: number = 0; // Index of the currently playing video
  // [End activeIndexChange]
  @Prop isFullLandscapeScreen: boolean = false; // FullLandscapeScreen state
  @Prop videoIndex: number = 0; // Video index
  @Prop screenWidth: number = 0; // Screen width
  @State swiperController: SwiperController | undefined = undefined;
  @State currentTime: number = 0; // Current play time point
  @State durationTime: number = 0; // Video total time
  @State isStart: boolean = true; // Video state
  @State volume: number = 5; // Video volume
  @State volumeVisible: boolean = false; // AVVolumePanel visibility state
  @State windowHeight: number = 300; // Window height
  @State videoInfoList: Array<VideoDataModel> = []; // Video resource list
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X; // Video play speed
  @State isAccelerate: boolean = false; // SpeedDialog visibility state
  @State leftRateOpacity: number = 0; // SpeedDialog left opacity
  @State rightRateOpacity: number = 1; // SpeedDialog right opacity
  private windowUtil: WindowUtil = WindowUtil.getInstance(); // Window-related utility class
  private controller: VideoController = new VideoController();

  aboutToAppear(): void {
    this.videoInfoList = [...VideoData];
    this.swiperController = AppStorage.get('swiperController');
  }

  // [Start activeIndexChange_func]
  // Monitor the change of activeIndex when the onchange event occurs.
  activeIndexChange() {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'activeIndexChange.' + this.activeIndex);
    this.currentTime = 0; // Reset currentTime
    this.controller.reset(); // Reset VideoController
    this.controller.start(); // Start playing
  }

  // [End activeIndexChange_func]

  // [Start foregroundStatus_func]
  // Perception of foreground and background.
  foregroundStatus() {
    if (this.isForeGround) {
      this.controller.start(); // Start playing when in the foreground.
      this.isStart = true;
    } else {
      this.controller.pause(); // Pause playback when in the background.
      this.isStart = false;
    }
  }

  // [End foregroundStatus_func]

  @Builder
  showFeatureIconInColumn(src: ResourceStr, content?: ResourceStr) {
    Column() {
      Image(src)
        .width(30)
      if (content) {
        Text(content)
          .fontSize(14)
          .lineHeight(19)
          .fontColor(Color.White)
          .margin({ top: 5 })
      }
    }
  }

  @Builder
  showFeatureIconInRow(src: ResourceStr, content?: ResourceStr) {
    Row({ space: 3 }) {
      Image(src)
        .width(22)
      if (content) {
        Text(content)
          .fontSize(14)
          .lineHeight(19)
          .fontColor(Color.White)
      }
    }
  }

  // SpeedGesture custom column component
  @Builder
  SpeedGestureColumn() {
    // [Start SpeedGestureColumn]
    Column()
      .width('20%')
      .height('100%')
      .gesture(
        LongPressGesture({ repeat: true })
          .onAction((event: GestureEvent | undefined) => {
            // The fast forward icon changes between visible and invisible states.
            this.leftRateOpacity = 1;
            this.rightRateOpacity = 0;
            if (!event) {
              return;
            }
            if (event.repeat) {
              this.isAccelerate = true;
              this.curRate = PlaybackSpeed.Speed_Forward_2_00_X;
              if (!this.isStart) {
                this.isStart = true;
                this.controller.start();
              }
            }
          })
          .onActionEnd(() => {
            this.isAccelerate = false;
            this.curRate = PlaybackSpeed.Speed_Forward_1_00_X;
          })
      );
    // [End SpeedGestureColumn]
  }

  // Use longPressGesture on both sides of the video screen to acceleration.
  @Builder
  SpeedGesture() {
    Row() {
      this.SpeedGestureColumn()
      Blank();
      this.SpeedGestureColumn()
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .height('100%');
  }

  // Show dialog when accelerating.
  @Builder
  SpeedDialog() {
    Row() {
      Image($r('app.media.double_rate'))
        .width(10)
        .height(13)
        .opacity(this.leftRateOpacity)
        .animation({
          duration: 500,
          curve: Curve.Linear,
          delay: 500,
          iterations: -1,
          playMode: PlayMode.Alternate,
          expectedFrameRateRange: {
            min: 0,
            max: 1,
            expected: 1,
          }
        });
      Image($r('app.media.double_rate'))
        .width(10)
        .height(13)
        .opacity(this.rightRateOpacity)
        .animation({
          duration: 500,
          curve: Curve.Linear,
          delay: 500,
          iterations: -1,
          playMode: PlayMode.Alternate,
          expectedFrameRateRange: {
            min: 0,
            max: 1,
            expected: 0,
          }
        });

      Text($r('app.string.fast_forwarding'))
        .fontColor(Color.White);
    }
    .width(140)
    .height(32)
    .padding({
      left: 16,
      right: 16
    })
    .backgroundColor('rgba(31, 31, 38, 0.5)')
    .borderRadius(16)
    .visibility(this.isAccelerate ? Visibility.Visible : Visibility.Hidden)
    .position({
      left: (this.screenWidth - CommonConstants.RATE_DIALOG_WIDTH) / 2,
      top: 100
    });
  }

  // Playback progress bar.
  @Builder
  PlaybackProgressBar() {
    Row() {
      Text(formatVideoTime(this.currentTime))
        .fontColor(Color.White)
        .fontSize(12)
      Slider({
        value: this.currentTime,
        min: 0,
        max: this.durationTime
      })
        .trackColor(Color.White)
        .opacity(0.6)
        .onChange((value: number) => {
          // Set the video playback progress to jump to the value.
          this.controller.setCurrentTime(value, SeekMode.Accurate);
        })
        .layoutWeight(1)
      Text(formatVideoTime(this.durationTime))
        .fontColor(Color.White)
        .fontSize(12)

      Stack() {
        Image($r('app.media.ic_video_menu_landscape_fullscreen'))
          .fillColor($r('sys.color.white'))
          .width($r('app.float.size_25'))
          .height($r('app.float.size_25'))
          .margin({ left: 20 })
      }
      .width(30)
      .height(30)
      .onClick(() => {
        this.windowUtil.handleFullScreen(true); // Set full screen.
      })
      .visibility(this.isFullLandscapeScreen ? Visibility.None : Visibility.Visible)
    }
    .padding({
      left: 25,
      right: 25
    })
    .zIndex(1)
    .height('auto')
    .width('100%')
    .position({ y: this.isFullLandscapeScreen ? 310 : 776 })
  }

  build() {
    Stack() {
      if (this.activeIndex === this.videoIndex) {
        // [Start currentProgressRate]
        Video({
          src: this.videoInfoList[this.activeIndex].uri,
          controller: this.controller,
          currentProgressRate: this.curRate
        })
        // [End currentProgressRate]
          .autoPlay(true)
          .loop(false)
          .controls(false)
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
          .onPrepared((event) => {
            if (event) {
              this.durationTime = event.duration;
            }
          })
          .onUpdate((event) => {
            if (event) {
              this.currentTime = event.time;
            }
          })
          // [Start showNext]
          .onFinish(() => {
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'onFinish and showNext.');
            this.swiperController?.showNext();
          })
        // [End showNext]
      } else {
        Video({})
          .controls(false)
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
      }

      // Start and stop button.
      Button({ stateEffect: true }) {
        Image($r('app.media.play'))
      }
      .height(56)
      .aspectRatio(1)
      .opacity(0.2)
      .backgroundColor(Color.Transparent)
      .visibility(this.isStart ? Visibility.Hidden : Visibility.Visible)

      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .fillColor(Color.White)
          .width($r('app.float.size_24'))
          .height($r('app.float.size_24'))
      }
      .width($r('app.float.button_back_size'))
      .height($r('app.float.button_back_size'))
      .backgroundColor('rgba(255,255,255,0.1)')
      .position({
        x: $r('app.float.size_25'),
        y: $r('app.float.size_25')
      })
      .zIndex(1)
      .onClick(() => {
        this.windowUtil.handleFullScreenExit(false); // Exit full screen
      })
      .visibility(this.isFullLandscapeScreen ? Visibility.Visible : Visibility.Hidden)

      this.PlaybackProgressBar() // The playback progress bar component

      RelativeContainer() {
        Column({ space: 20 }) {
          Image($r('app.media.menu_icon_user_avatar')).width(44)
          this.showFeatureIconInColumn($r('app.media.menu_icon_like'), '1557')
          this.showFeatureIconInColumn($r('app.media.menu_icon_comment'), '566')
          this.showFeatureIconInColumn($r('app.media.menu_icon_share'), '147')
          Image($r('app.media.menu_icon_music_cover')).width(32)
        }
        .alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End },
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
        .margin({ right: 8, bottom: 90 })
        .visibility(this.isFullLandscapeScreen ? Visibility.None : Visibility.Visible)
      }

      Row({ space: 18 }) {
        this.showFeatureIconInRow($r('app.media.menu_icon_like'), '1557')
        this.showFeatureIconInRow($r('app.media.menu_icon_comment'), '566')
        this.showFeatureIconInRow($r('app.media.menu_icon_share'), '147')
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .position({
        x: $r('app.float.size_25'),
        y: 348
      })
      .visibility(this.isFullLandscapeScreen ? Visibility.Visible : Visibility.None)

      SetVolume({
        volume: this.volume,
        volumeVisible: this.volumeVisible,
        isFullLandscapeScreen: this.isFullLandscapeScreen
      }) // Volume setting component
      this.SpeedGesture(); // Speed adjustment gesture component
      this.SpeedDialog(); // Speed adjustment dialog
    }
    .backgroundColor('#D8D8D8')
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .onClick(() => {
      // Click the button to play or pause the video.
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'onClick,' + 'activeIndex:' + this.activeIndex);
      this.isStart ? this.controller.pause() : this.controller.start();
      this.isStart = !this.isStart;
    })
    .gesture(
      // Combined gesture: LongPressGesture and PanGesture.
      GestureGroup(GestureMode.Sequence,
        // [Start LongPressGesture]
        LongPressGesture({ repeat: true })
          .onAction((event: GestureEvent | undefined) => {
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'LongPressGesture:' + event);
            if (event) {
              this.volumeVisible = true;
            }
          })
          .onActionEnd(() => {
            this.volumeVisible = false;
          }),
        // [End LongPressGesture]
        // [Start PanGesture]
        // When dragging after a long press, the PanGesture gesture is triggered.
        PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event: GestureEvent) => {
            let curVolume = this.volume - this.getUIContext().vp2px(event.offsetY) / this.windowHeight;
            curVolume = curVolume >= 15.0 ? 15.0 : curVolume;
            curVolume = curVolume <= 0.0 ? 0.0 : curVolume;
            this.volume = curVolume;
          })
          .onActionEnd(() => {
            setTimeout(() => {
              this.volumeVisible = false;
            }, 5000)
          })
        // [End PanGesture]
      )
    )
  }
}