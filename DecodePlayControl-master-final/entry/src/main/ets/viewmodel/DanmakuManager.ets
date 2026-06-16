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

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DanmakuItem, DanmakuColor } from '../model/DanmakuModel';
import { DanmakuTrackManager } from './DanmakuTrackManager';
import { ConfigStorage, DanmakuConfig } from '../service/ConfigStorage';

const DOMAIN = 0x0000;
const TAG = 'DanmakuManager';
const SEND_COOLDOWN = 2000;
const MAX_SEND_LENGTH = 100;

export interface IDanmakuManager {
  loadDanmaku(videoId: string): Promise<DanmakuItem[]>;
  sendDanmaku(content: string, time: number, color: string): Promise<DanmakuItem | null>;
  toggleVisibility(): void;
  setSpeed(speed: number): void;
  getVisibleDanmaku(currentTime: number): DanmakuItem[];
}

export class DanmakuManager implements IDanmakuManager {
  private danmakuList: DanmakuItem[] = [];
  private trackManager: DanmakuTrackManager;
  private configStorage: ConfigStorage;
  private config: DanmakuConfig;
  private lastSendTime: number = 0;
  private localDanmakuCache: Map<string, DanmakuItem[]> = new Map();

  constructor(configStorage: ConfigStorage) {
    this.configStorage = configStorage;
    this.trackManager = new DanmakuTrackManager();
    this.config = {
      isEnabled: true,
      speed: 1.0,
      fontSize: 16,
      opacity: 0.8
    };
  }

  async initialize(): Promise<void> {
    this.config = await this.configStorage.loadDanmakuConfig();
  }

  async loadDanmaku(videoId: string): Promise<DanmakuItem[]> {
    const cached = this.localDanmakuCache.get(videoId);
    if (cached) {
      this.danmakuList = cached;
      return cached;
    }

    this.danmakuList = [];
    return this.danmakuList;
  }

  async sendDanmaku(content: string, time: number, color: string): Promise<DanmakuItem | null> {
    const now = Date.now();
    if (now - this.lastSendTime < SEND_COOLDOWN) {
      hilog.warn(DOMAIN, TAG, 'Send danmaku too fast');
      return null;
    }

    if (!content || content.trim().length === 0) {
      hilog.warn(DOMAIN, TAG, 'Danmaku content is empty');
      return null;
    }

    const trimmedContent = content.trim();
    if (trimmedContent.length > MAX_SEND_LENGTH) {
      hilog.warn(DOMAIN, TAG, 'Danmaku content too long');
      return null;
    }

    const id = `local_${Date.now()}_${Math.random()}`;
    const danmaku = new DanmakuItem(id, trimmedContent, time, color);
    danmaku.setSpeed(this.config.speed);

    const track = this.trackManager.allocateTrack(id, time);
    danmaku.setTrack(track);

    this.danmakuList.push(danmaku);
    this.lastSendTime = now;

    hilog.info(DOMAIN, TAG, `Danmaku sent: ${trimmedContent}`);
    return danmaku;
  }

  toggleVisibility(): void {
    this.config.isEnabled = !this.config.isEnabled;
    this.configStorage.saveDanmakuConfig(this.config);
    hilog.info(DOMAIN, TAG, `Danmaku visibility: ${this.config.isEnabled}`);
  }

  setSpeed(speed: number): void {
    this.config.speed = speed;
    this.danmakuList.forEach(d => d.setSpeed(speed));
    this.configStorage.saveDanmakuConfig(this.config);
  }

  setFontSize(fontSize: number): void {
    this.config.fontSize = fontSize;
    this.configStorage.saveDanmakuConfig(this.config);
  }

  setOpacity(opacity: number): void {
    this.config.opacity = opacity;
    this.configStorage.saveDanmakuConfig(this.config);
  }

  getVisibleDanmaku(currentTime: number): DanmakuItem[] {
    if (!this.config.isEnabled) {
      return [];
    }

    const windowSize = 5;
    return this.danmakuList.filter(d => {
      const timeDiff = Math.abs(d.time - currentTime);
      return timeDiff <= windowSize;
    });
  }

  isEnabled(): boolean {
    return this.config.isEnabled;
  }

  getConfig(): DanmakuConfig {
    return this.config;
  }

  cleanup(): void {
    this.trackManager.reset();
    this.danmakuList = [];
  }
}
