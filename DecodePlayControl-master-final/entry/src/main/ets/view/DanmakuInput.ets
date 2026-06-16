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

import { DanmakuColor, DEFAULT_DANMAKU_COLORS } from '../model/DanmakuModel';

@Component
export struct DanmakuInput {
  @State inputText: string = '';
  @State selectedColor: string = DanmakuColor.WHITE;
  @State isInputVisible: boolean = false;
  @State canSend: boolean = true;
  @State cooldownSeconds: number = 0;
  @Prop currentTime: number = 0;
  @Prop isDanmakuEnabled: boolean = true;
  onSend: (content: string, color: string) => void = () => {};
  onToggleDanmaku: (enabled: boolean) => void = () => {};
  private maxInputLength: number = 100;
  private cooldownTimer: number = -1;

  aboutToDisappear(): void {
    if (this.cooldownTimer !== -1) {
      clearInterval(this.cooldownTimer);
    }
  }

  private startCooldown(): void {
    this.canSend = false;
    this.cooldownSeconds = 2;
    
    this.cooldownTimer = setInterval(() => {
      this.cooldownSeconds--;
      if (this.cooldownSeconds <= 0) {
        this.canSend = true;
        clearInterval(this.cooldownTimer);
        this.cooldownTimer = -1;
      }
    }, 1000);
  }

  private handleSend(): void {
    if (!this.canSend) {
      return;
    }

    const trimmed = this.inputText.trim();
    if (trimmed.length === 0) {
      return;
    }

    this.onSend(trimmed, this.selectedColor);
    this.inputText = '';
    this.startCooldown();
  }

  build() {
    Row() {
      if (this.isDanmakuEnabled) {
        Image($r('app.media.ic_public_play'))
          .width('24vp')
          .height('24vp')
          .onClick(() => {
            this.onToggleDanmaku(!this.isDanmakuEnabled);
          })

        if (this.isInputVisible) {
          Column() {
            Row() {
              TextInput({ text: this.inputText, placeholder: '发送弹幕...' })
                .width('200vp')
                .height('36vp')
                .fontSize('14fp')
                .fontColor(Color.White)
                .placeholderColor('#AAAAAA')
                .backgroundColor('#33FFFFFF')
                .borderRadius('4vp')
                .maxLength(this.maxInputLength)
                .onChange((value: string) => {
                  this.inputText = value;
                })
                .onSubmit(() => {
                  this.handleSend();
                })

              Button('发送')
                .fontSize('14fp')
                .fontColor(Color.White)
                .backgroundColor(this.canSend ? '#F67609' : '#666666')
                .height('36vp')
                .enabled(this.canSend && this.inputText.trim().length > 0)
                .margin({ left: '8vp' })
                .onClick(() => {
                  this.handleSend();
                })

              Row() {
                ForEach(DEFAULT_DANMAKU_COLORS, (color: string) => {
                  Circle()
                    .width('20vp')
                    .height('20vp')
                    .fill(color)
                    .border({
                      width: this.selectedColor === color ? 2 : 0,
                      color: Color.White
                    })
                    .margin({ left: '4vp', right: '4vp' })
                    .onClick(() => {
                      this.selectedColor = color;
                    })
                })
              }
              .margin({ left: '8vp' })

              Text(`${this.inputText.length}/${this.maxInputLength}`)
                .fontSize('10fp')
                .fontColor('#AAAAAA')
                .margin({ left: '8vp' })
            }
            .width('auto')
            .height('auto')
            .padding('8vp')
            .backgroundColor('#CC000000')
            .borderRadius('8vp')

            if (!this.canSend) {
              Text(`发送过快，请等待 ${this.cooldownSeconds} 秒`)
                .fontSize('12fp')
                .fontColor('#FF6600')
                .margin({ top: '4vp' })
            }
          }
          .alignItems(HorizontalAlign.End)
        }

        Image($r('app.media.ic_public_enlarge'))
          .width('24vp')
          .height('24vp')
          .margin({ left: '8vp' })
          .onClick(() => {
            this.isInputVisible = !this.isInputVisible;
          })
      } else {
        Image($r('app.media.ic_public_pause'))
          .width('24vp')
          .height('24vp')
          .onClick(() => {
            this.onToggleDanmaku(!this.isDanmakuEnabled);
          })
      }
    }
    .width('auto')
    .height('auto')
    .justifyContent(FlexAlign.End)
  }
}
