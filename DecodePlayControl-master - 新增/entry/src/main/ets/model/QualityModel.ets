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

export enum QualityLevel {
  AUTO = -1,
  SMOOTH = 0,
  STANDARD = 1,
  HIGH = 2,
  SUPER = 3
}

export class QualityItem {
  id: QualityLevel;
  name: string;
  resolution: string;
  bitrate: number;

  constructor(id: QualityLevel, name: string, resolution: string, bitrate: number) {
    this.id = id;
    this.name = name;
    this.resolution = resolution;
    this.bitrate = bitrate;
  }

  isValid(): boolean {
    return this.name !== null && this.name !== undefined && this.name.length > 0;
  }

  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      name: this.name,
      resolution: this.resolution,
      bitrate: this.bitrate
    });
  }

  static fromJSON(jsonStr: string): QualityItem {
    const obj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
    return new QualityItem(obj.id as QualityLevel, obj.name as string, obj.resolution as string, obj.bitrate as number);
  }
}

export const DEFAULT_QUALITY_LIST: QualityItem[] = [
  new QualityItem(QualityLevel.AUTO, '自动', '自动', 0),
  new QualityItem(QualityLevel.SMOOTH, '流畅', '480P', 500),
  new QualityItem(QualityLevel.STANDARD, '标清', '720P', 1000),
  new QualityItem(QualityLevel.HIGH, '高清', '1080P', 2000),
  new QualityItem(QualityLevel.SUPER, '超清', '4K', 4000)
];
