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

import { DanmakuItem } from '../model/DanmakuModel';
import { DanmakuManager } from '../viewmodel/DanmakuManager';

@Component
export struct DanmakuView {
  @Prop danmakuList: DanmakuItem[] = [];
  @Prop currentTime: number = 0;
  @Prop isEnabled: boolean = true;
  @Prop viewWidth: number = 0;
  @Prop viewHeight: number = 0;
  @State private renderingList: DanmakuItem[] = [];
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private lastRenderTime: number = 0;
  private frameInterval: number = 33;

  aboutToAppear(): void {
    this.canvasWidth = this.viewWidth || 300;
    this.canvasHeight = this.viewHeight || 200;
  }

  build() {
    Stack() {
      if (this.isEnabled && this.danmakuList.length > 0) {
        ForEach(this.getVisibleDanmaku(), (item: DanmakuItem) => {
          Text(item.content)
            .fontSize('16fp')
            .fontColor(item.color)
            .opacity(0.8)
            .position({
              x: this.calculateX(item),
              y: this.calculateY(item)
            })
        }, (item: DanmakuItem) => item.id)
      }
    }
    .width('100%')
    .height('100%')
  }

  private getVisibleDanmaku(): DanmakuItem[] {
    return this.danmakuList.filter(item => {
      const elapsed = this.currentTime - item.time;
      return elapsed >= 0 && elapsed <= 6;
    });
  }

  private calculateX(item: DanmakuItem): number {
    const elapsed = (this.currentTime - item.time) * 1000;
    const duration = 6000 / item.speed;
    const progress = elapsed / duration;
    const x = this.canvasWidth * (1 - progress);
    return x;
  }

  private calculateY(item: DanmakuItem): number {
    const trackHeight = 30;
    const baseY = 10;
    return baseY + item.track * trackHeight;
  }
}
