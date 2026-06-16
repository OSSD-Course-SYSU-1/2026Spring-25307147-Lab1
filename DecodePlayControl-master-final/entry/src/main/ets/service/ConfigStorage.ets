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
import { VolumeConfig } from '../model/VolumeModel';
import { QualityLevel } from '../model/QualityModel';

const DOMAIN = 0x0000;
const TAG = 'ConfigStorage';
const STORE_NAME = 'video_config';

export interface DanmakuConfig {
  isEnabled: boolean;
  speed: number;
  fontSize: number;
  opacity: number;
}

export class ConfigStorage extends BaseStorage {
  constructor(context: Context | undefined) {
    super(context, STORE_NAME);
  }

  async saveVolumeConfig(config: VolumeConfig): Promise<boolean> {
    const jsonStr = config.toJSON();
    return await this.set('volume_config', jsonStr);
  }

  async loadVolumeConfig(): Promise<VolumeConfig | null> {
    const jsonStr = await this.get('volume_config', '');

    if (!jsonStr || jsonStr.length === 0) {
      return new VolumeConfig();
    }

    try {
      return VolumeConfig.fromJSON(jsonStr);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Load volume config failed: ${error.message}`);
      return new VolumeConfig();
    }
  }

  async saveQualityLevel(level: QualityLevel): Promise<boolean> {
    return await this.set('quality_level', level.toString());
  }

  async loadQualityLevel(): Promise<QualityLevel> {
    const levelStr = await this.get('quality_level', QualityLevel.AUTO.toString());
    return parseInt(levelStr) as QualityLevel;
  }

  async saveDanmakuConfig(config: DanmakuConfig): Promise<boolean> {
    const jsonStr = JSON.stringify(config);
    return await this.set('danmaku_config', jsonStr);
  }

  async loadDanmakuConfig(): Promise<DanmakuConfig> {
    const jsonStr = await this.get('danmaku_config', '');

    if (!jsonStr || jsonStr.length === 0) {
      return {
        isEnabled: true,
        speed: 1.0,
        fontSize: 16,
        opacity: 0.8
      };
    }

    try {
      return JSON.parse(jsonStr) as DanmakuConfig;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Load danmaku config failed: ${error.message}`);
      return {
        isEnabled: true,
        speed: 1.0,
        fontSize: 16,
        opacity: 0.8
      };
    }
  }
}
