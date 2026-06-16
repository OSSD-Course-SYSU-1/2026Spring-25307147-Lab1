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

import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'BaseStorage';

export abstract class BaseStorage {
  protected dataPreferences: preferences.Preferences | null = null;
  protected context: Context | undefined;
  protected storeName: string;

  constructor(context: Context | undefined, storeName: string) {
    this.context = context;
    this.storeName = storeName;
  }

  async init(): Promise<boolean> {
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'Context is null, init failed');
      return false;
    }

    try {
      this.dataPreferences = await preferences.getPreferences(this.context, this.storeName);
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Init failed: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  async get(key: string, defaultValue: string): Promise<string> {
    if (!this.dataPreferences) {
      return defaultValue;
    }

    try {
      const value = await this.dataPreferences.get(key, defaultValue);
      if (typeof value === 'string') {
        return value;
      }
      return defaultValue;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Get failed: ${error.code}, message: ${error.message}`);
      return defaultValue;
    }
  }

  async set(key: string, value: string): Promise<boolean> {
    if (!this.dataPreferences) {
      return false;
    }

    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Set failed: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  async delete(key: string): Promise<boolean> {
    if (!this.dataPreferences) {
      return false;
    }

    try {
      await this.dataPreferences.delete(key);
      await this.dataPreferences.flush();
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Delete failed: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  async clear(): Promise<boolean> {
    if (!this.dataPreferences) {
      return false;
    }

    try {
      await this.dataPreferences.clear();
      await this.dataPreferences.flush();
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Clear failed: ${error.code}, message: ${error.message}`);
      return false;
    }
  }
}
