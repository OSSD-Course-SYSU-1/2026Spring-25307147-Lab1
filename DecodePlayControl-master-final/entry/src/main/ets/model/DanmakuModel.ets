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

export enum DanmakuColor {
  WHITE = '#FFFFFF',
  RED = '#FF0000',
  YELLOW = '#FFFF00',
  BLUE = '#0000FF',
  GREEN = '#00FF00',
  ORANGE = '#FFA500',
  PINK = '#FF69B4',
  CYAN = '#00FFFF'
}

export const DEFAULT_DANMAKU_COLORS: string[] = [
  DanmakuColor.WHITE,
  DanmakuColor.RED,
  DanmakuColor.YELLOW,
  DanmakuColor.BLUE,
  DanmakuColor.GREEN
];

export class DanmakuItem {
  id: string;
  content: string;
  time: number;
  color: string;
  track: number;
  speed: number;

  private readonly MAX_CONTENT_LENGTH = 100;

  constructor(id: string, content: string, time: number, color: string = DanmakuColor.WHITE) {
    this.id = id;
    this.content = this.sanitizeContent(content);
    this.time = time;
    this.color = this.validateColor(color) ? color : DanmakuColor.WHITE;
    this.track = -1;
    this.speed = 1.0;
  }

  sanitizeContent(content: string): string {
    let sanitized = content;
    if (sanitized.length > this.MAX_CONTENT_LENGTH) {
      sanitized = sanitized.substring(0, this.MAX_CONTENT_LENGTH);
    }
    sanitized = sanitized.replace(/</g, '&lt;');
    sanitized = sanitized.replace(/>/g, '&gt;');
    sanitized = sanitized.replace(/"/g, '&quot;');
    sanitized = sanitized.replace(/'/g, '&#39;');
    return sanitized;
  }

  validateColor(color: string): boolean {
    const hexPattern = /^#[0-9A-Fa-f]{6}$/;
    return hexPattern.test(color);
  }

  setTrack(track: number): void {
    this.track = track;
  }

  setSpeed(speed: number): void {
    this.speed = speed > 0 ? speed : 1.0;
  }

  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      content: this.content,
      time: this.time,
      color: this.color,
      track: this.track,
      speed: this.speed
    });
  }

  static fromJSON(jsonStr: string): DanmakuItem {
    const obj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
    const item = new DanmakuItem(obj.id as string, obj.content as string, obj.time as number, obj.color as string);
    item.track = obj.track as number;
    item.speed = obj.speed as number;
    return item;
  }
}
