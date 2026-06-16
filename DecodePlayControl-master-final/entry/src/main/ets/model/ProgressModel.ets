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

export class ProgressRecord {
  videoId: string;
  episodeIndex: number;
  position: number;
  duration: number;
  timestamp: number;

  constructor(videoId: string, episodeIndex: number, position: number, duration: number) {
    this.videoId = videoId;
    this.episodeIndex = episodeIndex;
    this.position = position;
    this.duration = duration;
    this.timestamp = Date.now();
  }

  getStorageKey(): string {
    return `${this.videoId}_${this.episodeIndex}`;
  }

  getProgressPercent(): number {
    if (this.duration <= 0) {
      return 0;
    }
    const percent = (this.position / this.duration) * 100;
    if (percent > 100) {
      return 100;
    }
    return percent;
  }

  isValid(): boolean {
    return this.videoId !== null &&
           this.videoId !== undefined &&
           this.videoId.length > 0 &&
           this.position >= 0 &&
           this.duration > 0;
  }

  toJSON(): string {
    return JSON.stringify({
      videoId: this.videoId,
      episodeIndex: this.episodeIndex,
      position: this.position,
      duration: this.duration,
      timestamp: this.timestamp
    });
  }

  static fromJSON(jsonStr: string): ProgressRecord {
    const obj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
    const record = new ProgressRecord(obj.videoId as string, obj.episodeIndex as number, obj.position as number, obj.duration as number);
    record.timestamp = obj.timestamp as number;
    return record;
  }
}
