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
import { ProgressRecord } from '../model/ProgressModel';
import { ProgressStorage } from '../service/ProgressStorage';

const DOMAIN = 0x0000;
const TAG = 'ProgressTracker';
const AUTO_SAVE_INTERVAL = 10000;
const MIN_SAVE_INTERVAL = 5000;

export interface IProgressTracker {
  startTracking(): void;
  stopTracking(): void;
  saveProgress(): Promise<boolean>;
  loadProgress(): Promise<ProgressRecord | null>;
  hasProgress(): boolean;
}

export class ProgressTracker implements IProgressTracker {
  private progressStorage: ProgressStorage;
  private currentVideoId: string = '';
  private currentEpisodeIndex: number = 0;
  private currentPosition: number = 0;
  private currentDuration: number = 0;
  private autoSaveTimer: number = -1;
  private lastSaveTime: number = 0;
  private lastSavedPosition: number = 0;

  constructor(progressStorage: ProgressStorage) {
    this.progressStorage = progressStorage;
  }

  setVideoInfo(videoId: string, episodeIndex: number): void {
    this.currentVideoId = videoId;
    this.currentEpisodeIndex = episodeIndex;
  }

  updatePosition(position: number, duration: number): void {
    this.currentPosition = position;
    this.currentDuration = duration;
  }

  startTracking(): void {
    this.stopTracking();
    
    this.autoSaveTimer = setInterval(() => {
      if (this.shouldSave()) {
        this.saveProgress();
      }
    }, AUTO_SAVE_INTERVAL);
    
    hilog.info(DOMAIN, TAG, 'Progress tracking started');
  }

  stopTracking(): void {
    if (this.autoSaveTimer !== -1) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = -1;
      hilog.info(DOMAIN, TAG, 'Progress tracking stopped');
    }
  }

  private shouldSave(): boolean {
    if (this.currentPosition === 0 || this.currentDuration === 0) {
      return false;
    }
    
    const now = Date.now();
    if (now - this.lastSaveTime < MIN_SAVE_INTERVAL) {
      return false;
    }
    
    const positionDelta = Math.abs(this.currentPosition - this.lastSavedPosition);
    const threshold = this.currentDuration * 0.05;
    if (positionDelta < threshold && this.lastSavedPosition > 0) {
      return false;
    }
    
    return true;
  }

  async saveProgress(): Promise<boolean> {
    if (this.currentVideoId.length === 0 || this.currentDuration === 0) {
      return false;
    }

    const percent = this.currentPosition / this.currentDuration;
    if (percent > 0.95) {
      hilog.info(DOMAIN, TAG, 'Skip saving: video nearly completed');
      return false;
    }

    const record = new ProgressRecord(
      this.currentVideoId,
      this.currentEpisodeIndex,
      this.currentPosition,
      this.currentDuration
    );

    const success = await this.progressStorage.saveProgress(record);
    
    if (success) {
      this.lastSaveTime = Date.now();
      this.lastSavedPosition = this.currentPosition;
      hilog.info(DOMAIN, TAG, `Progress saved: ${this.currentPosition}/${this.currentDuration}`);
    }
    
    return success;
  }

  async loadProgress(): Promise<ProgressRecord | null> {
    if (this.currentVideoId.length === 0) {
      return null;
    }

    const record = await this.progressStorage.loadProgress(
      this.currentVideoId,
      this.currentEpisodeIndex
    );

    if (record) {
      hilog.info(DOMAIN, TAG, `Progress loaded: ${record.position}/${record.duration}`);
    }

    return record;
  }

  hasProgress(): boolean {
    return this.lastSavedPosition > 0;
  }

  async clearProgress(): Promise<boolean> {
    return await this.progressStorage.clearProgress(
      this.currentVideoId,
      this.currentEpisodeIndex
    );
  }

  cleanup(): void {
    this.stopTracking();
    this.saveProgress();
  }
}
