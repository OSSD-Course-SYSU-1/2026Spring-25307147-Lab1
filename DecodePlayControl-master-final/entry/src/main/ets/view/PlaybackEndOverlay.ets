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

@Component
export struct PlaybackEndOverlay {
  @Prop countdown: number = 10;
  @Prop isLastEpisode: boolean = false;
  @Prop isVisible: boolean = false;
  onReplay: () => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    if (this.isVisible) {
      Column() {
        Column() {
          Text('本集已播完')
            .fontSize('24fp')
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: '24vp' })

          Button('重新播放')
            .width('180vp')
            .height('48vp')
            .fontSize('18fp')
            .fontColor(Color.White)
            .backgroundColor('#F67609')
            .borderRadius('24vp')
            .onClick(() => {
              this.onReplay();
            })

          if (!this.isLastEpisode) {
            Column() {
              Text(`${this.countdown}秒后自动播放下一集`)
                .fontSize('16fp')
                .fontColor('#AAAAAA')
                .margin({ top: '24vp' })

              Progress({
                value: 10 - this.countdown,
                total: 10,
                type: ProgressType.Linear
              })
                .width('180vp')
                .height('4vp')
                .color('#F67609')
                .backgroundColor('#333333')
                .margin({ top: '8vp' })
            }
          } else {
            Text('已是最后一集')
              .fontSize('16fp')
              .fontColor('#AAAAAA')
              .margin({ top: '24vp' })
          }
        }
        .width('280vp')
        .padding('32vp')
        .backgroundColor('#DD000000')
        .borderRadius('16vp')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#66000000')
      .onClick(() => {
        this.onDismiss();
      })
      .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
    }
  }
}
