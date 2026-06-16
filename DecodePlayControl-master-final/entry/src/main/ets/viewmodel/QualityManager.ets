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
import { QualityItem, QualityLevel, DEFAULT_QUALITY_LIST } from '../model/QualityModel';
import { ConfigStorage } from '../service/ConfigStorage';

const DOMAIN = 0x0000;
const TAG = 'QualityManager';
const SWITCH_TIMEOUT = 2000;

export interface IQualityManager {
  loadQualityList(): Promise<QualityItem[]>;
  switchQuality(qualityId: QualityLevel): Promise<boolean>;
  getCurrentQuality(): QualityItem;
  isQualitySwitchSupported(): boolean;
}

export class QualityManager implements IQualityManager {
  private qualityList: QualityItem[] = DEFAULT_QUALITY_LIST;
  private currentQuality: QualityItem;
  private configStorage: ConfigStorage;
  private nativePlayerObj: bigint = BigInt(0);
  private isSupported: boolean = true;

  constructor(configStorage: ConfigStorage) {
    this.configStorage = configStorage;
    this.currentQuality = this.qualityList[0];
  }

  setNativePlayer(playerObj: bigint): void {
    this.nativePlayerObj = playerObj;
  }

  async initialize(): Promise<void> {
    const savedLevel = await this.configStorage.loadQualityLevel();
    const item = this.qualityList.find(q => q.id === savedLevel);
    if (item) {
      this.currentQuality = item;
    }
  }

  async loadQualityList(): Promise<QualityItem[]> {
    return this.qualityList;
  }

  async switchQuality(qualityId: QualityLevel): Promise<boolean> {
    const targetQuality = this.qualityList.find(q => q.id === qualityId);
    if (!targetQuality) {
      hilog.error(DOMAIN, TAG, `Quality not found: ${qualityId}`);
      return false;
    }

    if (this.nativePlayerObj === BigInt(0)) {
      hilog.error(DOMAIN, TAG, 'Native player not initialized');
      return false;
    }

    try {
      const switchPromise = new Promise<boolean>((resolve) => {
        hilog.info(DOMAIN, TAG, `Switching quality to: ${targetQuality.name}`);
        setTimeout(() => {
          this.currentQuality = targetQuality;
          this.configStorage.saveQualityLevel(qualityId);
          resolve(true);
        }, 500);
      });

      const timeoutPromise = new Promise<boolean>((resolve) => {
        setTimeout(() => resolve(false), SWITCH_TIMEOUT);
      });

      const result = await Promise.race([switchPromise, timeoutPromise]);
      
      if (!result) {
        hilog.error(DOMAIN, TAG, 'Quality switch timeout');
        return false;
      }

      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Switch quality failed: ${error.message}`);
      return false;
    }
  }

  getCurrentQuality(): QualityItem {
    return this.currentQuality;
  }

  isQualitySwitchSupported(): boolean {
    return this.isSupported && this.qualityList.length > 1;
  }

  setQualitySupported(supported: boolean): void {
    this.isSupported = supported;
  }

  setCustomQualityList(list: QualityItem[]): void {
    if (list && list.length > 0) {
      this.qualityList = list;
      this.currentQuality = list[0];
    }
  }
}
