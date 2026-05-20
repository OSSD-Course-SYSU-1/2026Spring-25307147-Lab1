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

export class CommonConstants {
  /**
   * Video speed array.
   */
  static readonly VIDEO_SPEED_ARR: number[] = [3, 2, 1];

  /**
   * Video speed show text array.
   */
  static readonly VIDEO_SPEED_TEXT_ARR: string[] = ['3.0X', '2.0X', '1.0X']

  /**
   * Video default speed.
   */
  static readonly VIDEO_DEFAULT_SPEED: number = 1;

  /**
   * Time interval ms.
   */
  static readonly TIME_INTERVAL: number = 20;

  /**
   * Time ratio us to s.
   */
  static readonly TIME_RATIO: number = 1000000;

  /**
   * Reload wait time after seek ms.
   */
  static readonly RELOAD_TIME: number = 300;
}