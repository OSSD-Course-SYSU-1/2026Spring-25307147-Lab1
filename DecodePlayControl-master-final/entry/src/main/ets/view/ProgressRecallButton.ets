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

import { getShowTime } from '../common/TimeUtils';

@Component
export struct ProgressRecallButton {
  @Prop lastPosition: number = 0;
  @Prop lastDuration: number = 0;
  @Prop isVisible: boolean = false;
  @Prop hasProgress: boolean = false;
  onRecall: () => void = () => {};
  onDismiss: () => void = () => {};

  private getPositionText(): string {
    if (this.lastDuration > 0) {
      const percent = Math.round((this.lastPosition / this.lastDuration) * 100);
      return `上次播放至 ${getShowTime(this.lastPosition)} (${percent}%)`;
    }
    return `上次播放至 ${getShowTime(this.lastPosition)}`;
  }

  build() {
    if (this.hasProgress && this.isVisible) {
      Row() {
        Text(this.getPositionText())
          .fontSize('12fp')
          .fontColor('#F67609')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button('回溯')
          .fontSize('12fp')
          .fontColor(Color.White)
          .backgroundColor('#F67609')
          .height('28vp')
          .padding({ left: '12vp', right: '12vp' })
          .margin({ left: '8vp' })
          .onClick(() => {
            this.onRecall();
          })

        Image($r('app.media.ic_public_pause'))
          .width('16vp')
          .height('16vp')
          .margin({ left: '8vp' })
          .onClick(() => {
            this.isVisible = false;
            this.onDismiss();
          })
      }
      .width('auto')
      .height('36vp')
      .padding({ left: '12vp', right: '12vp' })
      .backgroundColor('#AA000000')
      .borderRadius('4vp')
      .position({ x: '16vp', y: 'calc(100% - 52vp)' })
      .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
    }
  }
}
