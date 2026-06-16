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

const SECOND_TO_MIN: number = 60;
const DECIMAL: number = 10;
const APPROX: number = 0.9;

export function getShowTime(times: number): string {
  if (times <= 0) {
    return '00:00';
  } else {
    // One minute has 60 seconds.
    let minStr = Math.floor(times / SECOND_TO_MIN);
    let secStr = times % SECOND_TO_MIN;
    secStr = secStr % 1 > APPROX ? Math.ceil(secStr) : Math.floor(secStr);
    // When the time has only a single digit, add 0 to the tens place.
    return (minStr < DECIMAL ? '0' + minStr : minStr) + ':' + (secStr < DECIMAL ? '0' + secStr : secStr);
  }
}