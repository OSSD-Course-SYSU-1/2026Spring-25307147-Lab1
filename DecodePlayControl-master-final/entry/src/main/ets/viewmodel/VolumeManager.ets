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
import { VolumeConfig } from '../model/VolumeModel';
import { ConfigStorage } from '../service/ConfigStorage';

const DOMAIN = 0x0000;
const TAG = 'VolumeManager';

export interface IVolumeManager {
  setVolume(volume: number): Promise<boolean>;
  getVolume(): number;
  toggleMute(): Promise<boolean>;
  increaseVolume(): Promise<number>;
  decreaseVolume(): Promise<number>;
  isMuted(): boolean;
}

export class VolumeManager implements IVolumeManager {
  private volumeConfig: VolumeConfig;
  private configStorage: ConfigStorage;
  private saveDebounceTimer: number = -1;

  constructor(configStorage: ConfigStorage) {
    this.configStorage = configStorage;
    this.volumeConfig = new VolumeConfig();
  }

  async initialize(): Promise<void> {
    try {
      const savedConfig = await this.configStorage.loadVolumeConfig();
      if (savedConfig) {
        this.volumeConfig = savedConfig;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Init failed: ${error.message}`);
    }
  }

  async setVolume(volume: number): Promise<boolean> {
    try {
      const clampedVolume = this.volumeConfig.setVolume(volume);
      
      this.saveVolumeDebounced();
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Set volume failed: ${error.message}`);
      return false;
    }
  }

  getVolume(): number {
    return this.volumeConfig.value;
  }

  async toggleMute(): Promise<boolean> {
    const isMuted = this.volumeConfig.toggleMute();
    
    this.saveVolumeDebounced();
    return isMuted;
  }

  async increaseVolume(): Promise<number> {
    const newVolume = this.volumeConfig.increase();
    await this.setVolume(newVolume);
    return newVolume;
  }

  async decreaseVolume(): Promise<number> {
    const newVolume = this.volumeConfig.decrease();
    await this.setVolume(newVolume);
    return newVolume;
  }

  isMuted(): boolean {
    return this.volumeConfig.isMuted;
  }

  getConfig(): VolumeConfig {
    return this.volumeConfig;
  }

  private saveVolumeDebounced(): void {
    if (this.saveDebounceTimer !== -1) {
      clearTimeout(this.saveDebounceTimer);
    }
    
    this.saveDebounceTimer = setTimeout(() => {
      this.configStorage.saveVolumeConfig(this.volumeConfig);
      this.saveDebounceTimer = -1;
    }, 500);
  }

  cleanup(): void {
    if (this.saveDebounceTimer !== -1) {
      clearTimeout(this.saveDebounceTimer);
      this.saveDebounceTimer = -1;
    }
    
    this.configStorage.saveVolumeConfig(this.volumeConfig);
  }
}
