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
import { BaseStorage } from './BaseStorage';
import { ProgressRecord } from '../model/ProgressModel';

const DOMAIN = 0x0000;
const TAG = 'ProgressStorage';
const STORE_NAME = 'video_progress';
const EXPIRE_DAYS = 30;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export class ProgressStorage extends BaseStorage {
  constructor(context: Context | undefined) {
    super(context, STORE_NAME);
  }

  async saveProgress(record: ProgressRecord): Promise<boolean> {
    if (!record.isValid()) {
      hilog.error(DOMAIN, TAG, 'Invalid progress record');
      return false;
    }

    const key = record.getStorageKey();
    const jsonStr = record.toJSON();
    return await this.set(key, jsonStr);
  }

  async loadProgress(videoId: string, episodeIndex: number): Promise<ProgressRecord | null> {
    const key = `${videoId}_${episodeIndex}`;
    const jsonStr = await this.get(key, '');

    if (!jsonStr || jsonStr.length === 0) {
      return null;
    }

    try {
      const record = ProgressRecord.fromJSON(jsonStr);
      
      const now = Date.now();
      const daysPassed = (now - record.timestamp) / MS_PER_DAY;
      if (daysPassed > EXPIRE_DAYS) {
        await this.delete(key);
        hilog.info(DOMAIN, TAG, `Progress expired and deleted: ${key}`);
        return null;
      }

      return record;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Load progress failed: ${error.message}`);
      return null;
    }
  }

  async clearProgress(videoId: string, episodeIndex: number): Promise<boolean> {
    const key = `${videoId}_${episodeIndex}`;
    return await this.delete(key);
  }

  async clearAllProgress(): Promise<boolean> {
    return await this.clear();
  }

  async cleanupExpiredRecords(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Cleanup expired records completed');
  }
}
