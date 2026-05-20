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

import { VolumeManager } from '../viewmodel/VolumeManager';

@Component
export struct VolumeControl {
  @Prop volume: number = 50;
  @Prop isMuted: boolean = false;
  @Prop isVolumeVisible: boolean = false;
  volumeManager: VolumeManager | null = null;
  onVolumeChange: (volume: number) => void = () => {};
  onMuteChange: (muted: boolean) => void = () => {};
  onVisibilityChange: (visible: boolean) => void = () => {};

  private getVolumeIcon(): Resource {
    if (this.isMuted || this.volume === 0) {
      return $r('app.media.ic_public_pause');
    } else if (this.volume < 50) {
      return $r('app.media.ic_public_play');
    } else {
      return $r('app.media.ic_public_play');
    }
  }

  build() {
    Row() {
      Image(this.getVolumeIcon())
        .width('24vp')
        .height('24vp')
        .onClick(async () => {
          if (this.volumeManager) {
            const muted = await this.volumeManager.toggleMute();
            this.onMuteChange(muted);
          }
        })

      if (this.isVolumeVisible) {
        Column() {
          Slider({
            value: this.volume,
            min: 0,
            max: 100
          })
            .width('100vp')
            .height('4vp')
            .selectedColor('#F67609')
            .trackColor('#464642')
            .blockColor('#FFFFFF')
            .onChange(async (value: number, mode: SliderChangeMode) => {
              const newVolume = Math.round(value);
              if (mode === SliderChangeMode.End || mode === SliderChangeMode.Moving) {
                if (this.volumeManager) {
                  await this.volumeManager.setVolume(newVolume);
                }
                this.onVolumeChange(newVolume);
              }
            })

          Text(`${this.volume}%`)
            .fontSize('12fp')
            .fontColor(Color.White)
            .margin({ top: '4vp' })
        }
        .width('120vp')
        .padding({ left: '8vp', right: '8vp', top: '4vp', bottom: '4vp' })
        .backgroundColor('#CC000000')
        .borderRadius('4vp')
        .margin({ left: '8vp' })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }
    }
    .width('auto')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onVisibilityChange(!this.isVolumeVisible);
    })
  }
}
