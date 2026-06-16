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

const DOMAIN = 0x0000;
const TAG = 'DanmakuTrackManager';

export interface IDanmakuTrackManager {
  allocateTrack(danmakuId: string, startTime: number): number;
  releaseTrack(danmakuId: string): void;
  getTrackPosition(track: number): number;
  reset(): void;
}

interface TrackInfo {
  danmakuId: string;
  releaseTime: number;
}

export class DanmakuTrackManager implements IDanmakuTrackManager {
  private maxTracks: number = 10;
  private trackHeight: number = 30;
  private tracks: Map<number, TrackInfo> = new Map();

  constructor(maxTracks: number = 10, trackHeight: number = 30) {
    this.maxTracks = maxTracks;
    this.trackHeight = trackHeight;
  }

  allocateTrack(danmakuId: string, startTime: number): number {
    const now = Date.now();
    
    const trackIds = Array.from(this.tracks.keys());
    for (let i = 0; i < trackIds.length; i++) {
      const trackId = trackIds[i];
      const info = this.tracks.get(trackId);
      if (info && now > info.releaseTime) {
        this.tracks.delete(trackId);
      }
    }

    for (let i = 0; i < this.maxTracks; i++) {
      if (!this.tracks.has(i)) {
        const releaseTime = now + 6000;
        this.tracks.set(i, { danmakuId: danmakuId, releaseTime: releaseTime });
        hilog.debug(DOMAIN, TAG, `Allocated track ${i} for danmaku ${danmakuId}`);
        return i;
      }
    }

    let earliestTrack = 0;
    let earliestTime = this.tracks.get(0)?.releaseTime || 0;
    
    const allTrackIds = Array.from(this.tracks.keys());
    for (let i = 0; i < allTrackIds.length; i++) {
      const trackId = allTrackIds[i];
      const info = this.tracks.get(trackId);
      if (info && info.releaseTime < earliestTime) {
        earliestTime = info.releaseTime;
        earliestTrack = trackId;
      }
    }

    this.tracks.set(earliestTrack, { danmakuId: danmakuId, releaseTime: now + 6000 });
    hilog.debug(DOMAIN, TAG, `Reallocated track ${earliestTrack} for danmaku ${danmakuId}`);
    return earliestTrack;
  }

  releaseTrack(danmakuId: string): void {
    const trackIds = Array.from(this.tracks.keys());
    for (let i = 0; i < trackIds.length; i++) {
      const trackId = trackIds[i];
      const info = this.tracks.get(trackId);
      if (info && info.danmakuId === danmakuId) {
        this.tracks.delete(trackId);
        hilog.debug(DOMAIN, TAG, `Released track ${trackId} for danmaku ${danmakuId}`);
        break;
      }
    }
  }

  getTrackPosition(track: number): number {
    if (track < 0 || track >= this.maxTracks) {
      return 0;
    }
    return track * this.trackHeight + 10;
  }

  reset(): void {
    this.tracks.clear();
    hilog.info(DOMAIN, TAG, 'All tracks reset');
  }

  setMaxTracks(maxTracks: number): void {
    this.maxTracks = maxTracks;
  }

  setTrackHeight(height: number): void {
    this.trackHeight = height;
  }
}
