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
import { resourceManager } from '@kit.LocalizationKit';
import { window } from '@kit.ArkUI';
import { getShowTime } from '../common/TimeUtils';
import { PlayerState } from '../model/PlayerStateModel';
import { CommonConstants as Const } from '../common/CommonConstants';
import { VideoPlayViewModel } from '../viewmodel/VideoPlayViewModel';
import { QualitySelector } from './QualitySelector';
import { VolumeControl } from './VolumeControl';
import { ProgressRecallButton } from './ProgressRecallButton';
import { DanmakuView } from './DanmakuView';
import { DanmakuInput } from './DanmakuInput';
import { PlaybackEndOverlay } from './PlaybackEndOverlay';
import { QualityLevel } from '../model/QualityModel';

const DOMAIN = 0xFF00;
const TAG = 'VideoPlayView';
const FULL_SIZE = '100%';
const NORMAL_SIZE = '100%';
const WIDTH_SIZE = '100%';

@Component
export struct VideoPlayView {
  @ObjectLink viewModel: VideoPlayViewModel;
  @Link videoSources: resourceManager.RawFileDescriptor[];
  // [Start isFullScreen]
  // The horizontal full-screen playback state flag.
  @Watch('fullScreenSet') @Link isFullScreen: boolean;
  // [End isFullScreen]

  aboutToAppear(): void {
    this.viewModel.videoSources = this.videoSources;
    this.viewModel.setUIContext(this.getUIContext());
    this.viewModel.initialize();
  }

  aboutToDisappear(): void {
    this.viewModel.cleanup();
  }

  // [Start fullScreenSet]
  fullScreenSet() {
    // Change window orientation and layout when setting full screen.
    window.getLastWindow(this.getUIContext().getHostContext()).then((topWindow) => {
      topWindow.setPreferredOrientation(this.isFullScreen ?
        window.Orientation.AUTO_ROTATION_LANDSCAPE : window.Orientation.PORTRAIT).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to setPreferredOrientation. Cause: ${error.code}, message: ${error.message}`);
      });
      topWindow.setWindowLayoutFullScreen(this.isFullScreen ? true : false).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG,
          `Failed to setWindowLayoutFullScreen. Cause: ${error.code}, message: ${error.message}`);
      });
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to getLastWindow. Cause: ${error.code}, message: ${error.message}`);
    });
  }
  // [End fullScreenSet]

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        this.XComponentView()
        this.DanmakuOverlay()
        this.ControlOverlay()
        this.SpeedListOverlay()
        this.QualitySelectorOverlay()
        this.ProgressRecallOverlay()
        this.PlaybackEndOverlayView()
      }
      .width('100%')
      .height(this.isFullScreen ? '100%' : '35%')

      this.VideoSelectionView()
      this.VideoPlaceholderView()
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  XComponentView() {
    // [Start XComponent]
    XComponent({
      id: 'playerXC',
      type: XComponentType.SURFACE,
      libraryname: 'player'
    })
      .width(WIDTH_SIZE)
      .height(this.isFullScreen ? NORMAL_SIZE : FULL_SIZE)
    // [End XComponent]
  }

  @Builder
  ControlOverlay() {
    Column() {
      this.FullScreenHeaderView()
      Blank()
        .width('100%')
        .height('60%')
      this.PlaybackControls()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .padding({ left: '16vp', right: '16vp' })
    .visibility(this.viewModel.isUse ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  FullScreenHeaderView() {
    Row() {
      Image($r('app.media.back'))
        .width('40vp')
        .height('40vp')
        .onClick(() => {
          this.isFullScreen = false;
        })

      Text($r('app.string.Video_name'))
        .fontColor(Color.White)
        .fontSize('20fp')
        .fontWeight(FontWeight.Medium)
        .margin({ left: '12vp' })
    }
    .width('100%')
    .height('24%')
    .justifyContent(FlexAlign.Start)
    .padding({ left: '36vp' })
    .visibility(this.isFullScreen ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  PlaybackControls() {
    Row() {
      this.PlayPauseButton()
      this.TimeSlider()
      this.SpeedButton()
      this.QualityButton()
      this.VolumeButton()
      this.DanmakuInputView()
      this.FullScreenButton()
    }
    .width('100%')
    .height('16%')
    .padding(this.isFullScreen ? { left: '36vp', right: '36vp' } : 0)
    .justifyContent(FlexAlign.SpaceBetween)
    .visibility(this.viewModel.isSpeedListVisible || this.viewModel.isQualityVisible ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  PlayPauseButton() {
    Row() {
      Image(this.viewModel.playState === PlayerState.PLAYING ?
        $r('app.media.ic_public_pause') : $r('app.media.ic_public_play'))
        .width('25vp')
        .height('25vp')
        .onClick(() => {
          this.viewModel.playState = this.viewModel.togglePlayPause(this.viewModel.playState);
        })
    }
    .width('25vp')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TimeSlider() {
    Row() {
      Text(getShowTime(this.viewModel.currentTime))
        .fontColor(Color.White)
        .fontSize('12fp')

      Slider({
        value: this.viewModel.currentTime,
        min: 0,
        max: this.viewModel.durationTime
      })
        .width(this.isFullScreen ? '90%' : '70%')
        .selectedColor('#F67609')
        .trackColor('#464642')
        .enabled(!this.viewModel.isSeek)
        .onChange((value: number, mode: SliderChangeMode) => {
          this.viewModel.onSliderChange(value, mode);
        })

      Text(getShowTime(this.viewModel.durationTime))
        .fontColor(Color.White)
        .fontSize('12fp')
    }
    .width(this.isFullScreen ? '90%' : '70%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SpeedButton() {
    Row() {
      Text(this.viewModel.speedText)
        .fontColor(Color.White)
        .fontSize('14fp')
    }
    .width(this.isFullScreen ? '5%' : '14%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.viewModel.toggleSpeedList();
    })
  }

  @Builder
  QualityButton() {
    if (this.viewModel.qualityList.length > 1) {
      Row() {
        Text(this.viewModel.currentQuality?.name || '画质')
          .fontSize('14fp')
          .fontColor(Color.White)
      }
      .width(this.isFullScreen ? '8%' : '14%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.viewModel.toggleQualitySelector();
      })
    }
  }

  @Builder
  VolumeButton() {
    VolumeControl({
      volume: this.viewModel.volume,
      isMuted: this.viewModel.isMuted,
      isVolumeVisible: this.viewModel.isVolumeVisible,
      volumeManager: null,
      onVolumeChange: (vol: number) => {
        this.viewModel.onVolumeChange(vol);
      },
      onMuteChange: (muted: boolean) => {
        this.viewModel.isMuted = muted;
      },
      onVisibilityChange: (visible: boolean) => {
        this.viewModel.isVolumeVisible = visible;
      }
    })
  }

  @Builder
  FullScreenButton() {
    if (!this.isFullScreen) {
      Row() {
        Image($r('app.media.ic_public_enlarge'))
          .width('25vp')
          .height('25vp')
      }
      .width('8%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.isFullScreen = !this.isFullScreen;
      })
    }
  }

  @Builder
  SpeedListOverlay() {
    Row() {
      Column() {
        List({ space: 0, initialIndex: 2 }) {
          ForEach(Const.VIDEO_SPEED_ARR, (item: number, index: number) => {
            ListItem() {
              Column() {
                Text(Const.VIDEO_SPEED_TEXT_ARR[index])
                  .fontSize('16fp')
                  .fontColor(this.viewModel.chooseSpeed === item ? '#F67609' : '#FFFFFF')
              }
              .width('100%')
              .height('50vp')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.viewModel.onSpeedSelected(item, index);
              })
            }
          }, (item: number, index: number) => {
            return 'item: ' + item.toString() + 'index: ' + index.toString();
          })
        }
        .width('100%')
        .height('100%')
        .stackFromEnd(true)
        .divider({
          strokeWidth: 0.1,
          color: '#EEEEEE',
          endMargin: 16,
          startMargin: 16
        })
      }
      .width(this.isFullScreen ? '180vp' : '120vp')
      .height('100%')
      .padding({ top: '16vp', bottom: '36vp' })
      .justifyContent(FlexAlign.End)
      .backgroundColor('#08ffffff')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .visibility(this.viewModel.isSpeedListVisible ? Visibility.Visible : Visibility.Hidden)
    .onClick(() => {
      this.viewModel.hideSpeedList();
    })
  }

  @Builder
  VideoSelectionView() {
    Column() {
      Row() {
        Text($r('app.string.Video_name'))
          .fontSize('24fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height('25%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: '20vp', right: '20vp' })

      Row() {
        Text($r('app.string.Episodes'))
          .fontSize('16fp')
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
      }
      .width('100%')
      .height('20%')
      .padding({ left: '20vp', right: '20vp' })

      Row() {
        List({ space: '16vp', initialIndex: 0 }) {
          ForEach(this.videoSources, (item: resourceManager.RawFileDescriptor, index: number) => {
            ListItem() {
              Column() {
                Text((index + 1).toString())
                  .fontSize('20fp')
                  .fontColor(this.viewModel.chooseNumber === index && this.viewModel.isUse ? '#F67609' : '#FFFFFF')
              }
              .width(40)
              .height(40)
              .backgroundColor('#3B3A37')
              .borderRadius($r('sys.float.corner_radius_level5'))
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .borderColor(this.viewModel.chooseNumber === index && this.viewModel.isUse ? '#F67609' : '#3B3A37')
              .borderWidth(1)
              .onClick(() => {
                this.onVideoSelected(index, item);
              })
            }
          }, (item: resourceManager.RawFileDescriptor, index: number) => {
            return 'item: ' + item.toString() + 'index: ' + index.toString();
          })
        }
        .width('100%')
        .height('100%')
        .listDirection(Axis.Horizontal)
        .enabled(this.viewModel.isSwitchEnable)
      }
      .width('100%')
      .height('30%')
      .padding({ left: '20vp', right: '20vp' })
    }
    .width('100%')
    .height('35%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[0x1b1a1c, 0], [0x000000, 0.5]]
    })
    .visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  VideoPlaceholderView() {
    Blank()
      .width('100%')
      .height('55%')
      .backgroundColor(Color.Black)
      .visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  DanmakuOverlay() {
    DanmakuView({
      danmakuList: this.viewModel.danmakuList,
      currentTime: this.viewModel.currentTime,
      isEnabled: this.viewModel.isDanmakuEnabled,
      viewWidth: 300,
      viewHeight: 200
    })
  }

  @Builder
  QualitySelectorOverlay() {
    QualitySelector({
      qualityList: this.viewModel.qualityList,
      currentQuality: this.viewModel.currentQuality,
      isVisible: this.viewModel.isQualityVisible,
      isSwitching: this.viewModel.isQualitySwitching,
      onQualitySelected: (qualityId: QualityLevel) => {
        this.viewModel.onQualitySelected(qualityId);
      },
      onVisibilityChange: (visible: boolean) => {
        this.viewModel.isQualityVisible = visible;
      }
    })
  }

  @Builder
  ProgressRecallOverlay() {
    ProgressRecallButton({
      lastPosition: this.viewModel.lastProgressPosition,
      lastDuration: this.viewModel.lastProgressDuration,
      isVisible: this.viewModel.isProgressRecallVisible,
      hasProgress: this.viewModel.hasProgress,
      onRecall: () => {
        this.viewModel.recallToLastProgress();
        this.viewModel.isProgressRecallVisible = false;
      },
      onDismiss: () => {
        this.viewModel.dismissProgressRecall();
      }
    })
  }

  @Builder
  PlaybackEndOverlayView() {
    PlaybackEndOverlay({
      countdown: this.viewModel.endCountdown,
      isLastEpisode: this.viewModel.isLastEpisode,
      isVisible: this.viewModel.isPlaybackEndVisible,
      onReplay: () => {
        this.viewModel.replayCurrentVideo();
        this.viewModel.isPlaybackEndVisible = false;
      },
      onDismiss: () => {
        this.viewModel.dismissPlaybackEnd();
      }
    })
  }

  @Builder
  DanmakuInputView() {
    DanmakuInput({
      currentTime: this.viewModel.currentTime,
      isDanmakuEnabled: this.viewModel.isDanmakuEnabled,
      onSend: (content: string, color: string) => {
        this.viewModel.sendDanmaku(content, color);
      },
      onToggleDanmaku: (enabled: boolean) => {
        this.viewModel.isDanmakuEnabled = enabled;
      }
    })
  }

  private async onVideoSelected(index: number, rawDes: resourceManager.RawFileDescriptor): Promise<void> {
    const newState = await this.viewModel.onVideoSelected(index, rawDes);
    if (newState !== null) {
      this.viewModel.playState = newState;
    }
  }
}