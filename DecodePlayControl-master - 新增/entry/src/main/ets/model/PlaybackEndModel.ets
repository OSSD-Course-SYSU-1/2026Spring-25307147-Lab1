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

export enum EndState {
  PLAYING = 0,
  ENDED = 1,
  COUNTDOWN = 2,
  REPLAY = 3
}

export class PlaybackEndState {
  state: EndState;
  countdown: number;
  isLastEpisode: boolean;

  private readonly DEFAULT_COUNTDOWN = 10;
  private countdownTimer: number = -1;

  constructor() {
    this.state = EndState.PLAYING;
    this.countdown = this.DEFAULT_COUNTDOWN;
    this.isLastEpisode = false;
  }

  setPlaying(): void {
    this.state = EndState.PLAYING;
    this.countdown = this.DEFAULT_COUNTDOWN;
  }

  setEnded(isLastEpisode: boolean): void {
    this.state = EndState.ENDED;
    this.isLastEpisode = isLastEpisode;
  }

  startCountdown(onTick: (countdown: number) => void, onComplete: () => void): void {
    this.state = EndState.COUNTDOWN;
    this.countdown = this.DEFAULT_COUNTDOWN;
    
    this.countdownTimer = setInterval(() => {
      this.countdown--;
      onTick(this.countdown);
      
      if (this.countdown <= 0) {
        this.stopCountdown();
        onComplete();
      }
    }, 1000);
  }

  stopCountdown(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
    this.countdown = this.DEFAULT_COUNTDOWN;
  }

  setReplay(): void {
    this.state = EndState.REPLAY;
    this.stopCountdown();
  }

  isPlaying(): boolean {
    return this.state === EndState.PLAYING;
  }

  isEnded(): boolean {
    return this.state === EndState.ENDED;
  }

  isCountingDown(): boolean {
    return this.state === EndState.COUNTDOWN;
  }

  toJSON(): string {
    return JSON.stringify({
      state: this.state,
      countdown: this.countdown,
      isLastEpisode: this.isLastEpisode
    });
  }
}
