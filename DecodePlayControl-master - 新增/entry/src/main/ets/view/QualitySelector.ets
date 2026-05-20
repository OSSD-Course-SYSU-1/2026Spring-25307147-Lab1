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

import { QualityItem, QualityLevel } from '../model/QualityModel';

@Component
export struct QualitySelector {
  @Prop qualityList: QualityItem[] = [];
  @Prop currentQuality: QualityItem | null = null;
  @Prop isVisible: boolean = false;
  @Prop isSwitching: boolean = false;
  onQualitySelected: (qualityId: QualityLevel) => void = () => {};
  onVisibilityChange: (visible: boolean) => void = () => {};

  build() {
    Column() {
      Column() {
        Text('画质选择')
          .fontSize('16fp')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: '12vp' })

        List({ space: 0 }) {
          ForEach(this.qualityList, (item: QualityItem) => {
            ListItem() {
              Row() {
                Text(item.name)
                  .fontSize('14fp')
                  .fontColor(this.currentQuality?.id === item.id ? '#F67609' : '#FFFFFF')
                  .fontWeight(this.currentQuality?.id === item.id ? FontWeight.Bold : FontWeight.Normal)

                if (this.currentQuality?.id === item.id) {
                  Text('✓')
                    .fontSize('14fp')
                    .fontColor('#F67609')
                    .margin({ left: '8vp' })
                }
              }
              .width('100%')
              .height('48vp')
              .padding({ left: '16vp', right: '16vp' })
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => {
                if (!this.isSwitching && this.currentQuality?.id !== item.id) {
                  this.onQualitySelected(item.id);
                }
              })
            }
          }, (item: QualityItem) => item.id.toString())
        }
        .width('100%')
        .divider({
          strokeWidth: 0.5,
          color: '#444444'
        })
      }
      .width('180vp')
      .backgroundColor('#CC000000')
      .borderRadius('8vp')
      .padding({ top: '16vp', bottom: '16vp' })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .padding({ right: '16vp', bottom: '16vp' })
    .visibility(this.isVisible ? Visibility.Visible : Visibility.Hidden)
    .onClick(() => {
      this.onVisibilityChange(false);
    })
  }
}
