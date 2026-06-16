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
import { PlaybackEndState, EndState } from '../model/PlaybackEndModel';

const DOMAIN = 0x0000;
const TAG = 'EndStateHandler';
const DEBOUNCE_INTERVAL = 1000;

export interface IEndStateHandler {
  onPlaybackEnd(isLastEpisode: boolean): void;
  startCountdown(): void;
  cancelCountdown(): void;
  replayCurrent(): void;
  playNext(): void;
  getState(): EndState;
}

export class EndStateHandler implements IEndStateHandler {
  private endState: PlaybackEndState;
  private hasNextEpisode: boolean = false;
  private totalEpisodes: number = 0;
  private currentEpisodeIndex: number = 0;
  private lastEndTime: number = 0;
  
  onReplay: () => void = () => {};
  onPlayNext: () => void = () => {};

  constructor() {
    this.endState = new PlaybackEndState();
  }

  setEpisodeInfo(currentIndex: number, total: number): void {
    this.currentEpisodeIndex = currentIndex;
    this.totalEpisodes = total;
    this.hasNextEpisode = currentIndex < total - 1;
  }

  onPlaybackEnd(isLastEpisode: boolean): void {
    const now = Date.now();
    if (now - this.lastEndTime < DEBOUNCE_INTERVAL) {
      hilog.warn(DOMAIN, TAG, 'Playback end event debounced');
      return;
    }
    this.lastEndTime = now;

    if (this.endState.isCountingDown()) {
      hilog.warn(DOMAIN, TAG, 'Already counting down, ignore end event');
      return;
    }

    this.endState.setEnded(isLastEpisode);
    hilog.info(DOMAIN, TAG, `Playback ended, isLastEpisode: ${isLastEpisode}`);

    if (!isLastEpisode) {
      this.startCountdown();
    }
  }

  startCountdown(): void {
    if (this.endState.isLastEpisode) {
      hilog.info(DOMAIN, TAG, 'Last episode, no countdown');
      return;
    }

    this.endState.startCountdown(
      (countdown: number) => {
        hilog.debug(DOMAIN, TAG, `Countdown: ${countdown}`);
      },
      () => {
        hilog.info(DOMAIN, TAG, 'Countdown completed, playing next');
        this.playNext();
      }
    );
  }

  cancelCountdown(): void {
    this.endState.stopCountdown();
    this.endState.setPlaying();
    hilog.info(DOMAIN, TAG, 'Countdown cancelled');
  }

  replayCurrent(): void {
    this.endState.setReplay();
    this.cancelCountdown();
    hilog.info(DOMAIN, TAG, 'Replaying current episode');
    this.onReplay();
  }

  playNext(): void {
    if (!this.hasNextEpisode) {
      hilog.warn(DOMAIN, TAG, 'No next episode available');
      return;
    }

    this.cancelCountdown();
    hilog.info(DOMAIN, TAG, 'Playing next episode');
    this.onPlayNext();
  }

  getState(): EndState {
    return this.endState.state;
  }

  getCountdown(): number {
    return this.endState.countdown;
  }

  isLastEpisode(): boolean {
    return this.endState.isLastEpisode;
  }

  isCountingDown(): boolean {
    return this.endState.isCountingDown();
  }

  reset(): void {
    this.cancelCountdown();
    this.endState.setPlaying();
  }

  cleanup(): void {
    this.endState.stopCountdown();
  }
}
