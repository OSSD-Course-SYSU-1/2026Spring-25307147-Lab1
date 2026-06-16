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

export class VolumeConfig {
  value: number;
  step: number;
  isMuted: boolean;

  private readonly MIN_VOLUME = 0;
  private readonly MAX_VOLUME = 100;
  private readonly DEFAULT_STEP = 5;

  constructor(value: number = 50, step: number = 5, isMuted: boolean = false) {
    this.value = this.clamp(value);
    this.step = step > 0 ? step : this.DEFAULT_STEP;
    this.isMuted = isMuted;
  }

  clamp(volume: number): number {
    if (volume < this.MIN_VOLUME) {
      return this.MIN_VOLUME;
    }
    if (volume > this.MAX_VOLUME) {
      return this.MAX_VOLUME;
    }
    return volume;
  }

  increase(): number {
    this.value = this.clamp(this.value + this.step);
    if (this.value > 0) {
      this.isMuted = false;
    }
    return this.value;
  }

  decrease(): number {
    this.value = this.clamp(this.value - this.step);
    return this.value;
  }

  setVolume(volume: number): number {
    this.value = this.clamp(volume);
    if (this.value > 0) {
      this.isMuted = false;
    }
    return this.value;
  }

  toggleMute(): boolean {
    this.isMuted = !this.isMuted;
    return this.isMuted;
  }

  toJSON(): string {
    return JSON.stringify({
      value: this.value,
      step: this.step,
      isMuted: this.isMuted
    });
  }

  static fromJSON(jsonStr: string): VolumeConfig {
    const obj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
    return new VolumeConfig(obj.value as number, obj.step as number, obj.isMuted as boolean);
  }
}
