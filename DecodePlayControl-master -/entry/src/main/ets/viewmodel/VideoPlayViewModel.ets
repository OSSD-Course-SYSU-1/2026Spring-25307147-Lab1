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
import { window } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { PlayerState } from '../model/PlayerStateModel';
import { CommonConstants as Const } from '../common/CommonConstants';
import player from 'libplayer.so';

const DOMAIN = 0x0000;
const TAG = 'VideoPlayViewModel';

@Observed
export class VideoPlayViewModel {
  @Track chooseNumber: number = -1;
  @Track chooseSpeed: number = Const.VIDEO_DEFAULT_SPEED;
  @Track isUse: boolean = false;
  @Track isSpeedListVisible: boolean = false;
  @Track isSwitchEnable: boolean = true;
  @Track currentTime: number = 0;
  @Track durationTime: number = 0;
  @Track speedText: string | Resource = $r('app.string.Default_speed_text');
  @Track isSeek: boolean = false;
  @Track playState: PlayerState = PlayerState.IDLE;

  public videoSources: resourceManager.RawFileDescriptor[] = [];
  public nativePlayerObj: bigint = BigInt(0);
  
  private timerId: number = -1;
  private hostContext: Context | undefined = undefined;

  setUIContext(uiContext: UIContext): void {
    this.hostContext = uiContext.getHostContext();
  }

  async initialize(): Promise<void> {
    try {
      await this.setWindowProperties();
      this.registerEventListeners();
      this.startTimer();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `initialize catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  async setWindowProperties(): Promise<void> {
    if (!this.hostContext) {
      return;
    }
    
    try {
      const topWindow = await window.getLastWindow(this.hostContext);
      await topWindow.setWindowSystemBarProperties({
        statusBarContentColor: '#FFFFFF'
      });
      
      await topWindow.setWindowKeepScreenOn(true);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to set window properties. Cause: ${error.code}, message: ${error.message}`);
    }
  }

  registerEventListeners(): void {
    if (!this.hostContext) {
      return;
    }
    
    this.hostContext.eventHub.on('onBackground', () => this.onBackground());
    this.hostContext.eventHub.on('onForeground', () => this.onForeground());
  }

  unregisterEventListeners(): void {
    if (!this.hostContext) {
      return;
    }
    
    this.hostContext.eventHub.off('onBackground');
    this.hostContext.eventHub.off('onForeground');
  }

  startTimer(): void {
    this.stopTimer();
    this.timerId = setInterval(() => {
      if (this.nativePlayerObj === BigInt(0)) {
        return;
      }
      if (!this.isSeek) {
        try {
          const renderTime = player.getRenderTime(this.nativePlayerObj);
          this.currentTime = renderTime / Const.TIME_RATIO;
        } catch (error) {
          hilog.error(DOMAIN, TAG, `getRenderTime failed: ${error.code}, message: ${error.message}`);
        }
      }
    }, Const.TIME_INTERVAL);
  }

  stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  onBackground(): void {
    if (this.nativePlayerObj !== BigInt(0)) {
      player.pause(this.nativePlayerObj);
    }
  }

  onForeground(): void {
    if (this.playState === PlayerState.PLAYING) {
      if (this.nativePlayerObj !== BigInt(0)) {
        player.resume(this.nativePlayerObj);
      }
    }
  }

  togglePlayPause(playState: PlayerState): PlayerState {
    if (this.nativePlayerObj === BigInt(0)) {
      return playState;
    }
    
    if (playState === PlayerState.PLAYING) {
      player.pause(this.nativePlayerObj);
      return PlayerState.PAUSE;
    } else if (playState === PlayerState.PAUSE) {
      player.resume(this.nativePlayerObj);
      return PlayerState.PLAYING;
    }
    return playState;
  }

  onSliderChange(value: number, mode: SliderChangeMode): void {
    this.currentTime = value;
    
    if (this.durationTime > 0) {
      if (mode === SliderChangeMode.Begin) {
        this.isSeek = true;
      }
      
      if (mode === SliderChangeMode.End) {
        this.performSeek(value);
      }
    }
  }

  async performSeek(value: number): Promise<void> {
    if (this.nativePlayerObj === BigInt(0)) {
      return;
    }
    
    try {
      await player.seekVideo(this.nativePlayerObj, value);
      setTimeout(() => {
        this.isSeek = false;
      }, Const.RELOAD_TIME);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Seek failed: ${error.code}, message: ${error.message}`);
    }
  }

  toggleSpeedList(): void {
    this.isSpeedListVisible = true;
  }

  hideSpeedList(): void {
    if (this.isSpeedListVisible) {
      this.isSpeedListVisible = false;
    }
  }

  onSpeedSelected(speed: number, index: number): void {
    if (this.chooseSpeed !== speed) {
      this.chooseSpeed = speed;
      if (this.nativePlayerObj !== BigInt(0)) {
        player.setSpeed(this.nativePlayerObj, speed);
      }
      this.speedText = Const.VIDEO_SPEED_TEXT_ARR[index];
      this.isSpeedListVisible = false;
    }
  }

  async onVideoSelected(index: number, rawDes: resourceManager.RawFileDescriptor): Promise<PlayerState | null> {
    if (this.chooseNumber === index) {
      return null;
    }
    
    this.isSwitchEnable = false;
    this.durationTime = 0;
    this.chooseNumber = index;
    this.isUse = false;
    this.chooseSpeed = Const.VIDEO_DEFAULT_SPEED;
    this.speedText = $r('app.string.Default_speed_text');
    
    if (!rawDes) {
      hilog.error(DOMAIN, TAG, 'player inputFile is null');
      this.isSwitchEnable = true;
      return null;
    }
    
    try {
      await this.releasePlayer();
      this.nativePlayerObj = player.createPlayer();
      const data = await player.init(this.nativePlayerObj, rawDes.fd, rawDes.offset, rawDes.length);
      this.isSeek = false;
      
      if (data.code === 0) {
        this.durationTime = data.durationTime / Const.TIME_RATIO;
        this.isUse = true;
        this.isSwitchEnable = true;
        
        player.play(this.nativePlayerObj);
        return PlayerState.PLAYING;
      } else {
        hilog.error(DOMAIN, TAG, 'player init failed, err code is ' + data.code);
        await this.releasePlayer();
      }
      
      this.isSwitchEnable = true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Switch video failed: ${error.code}, message: ${error.message}`);
      await this.releasePlayer();
      this.isSwitchEnable = true;
    }
    
    return null;
  }

  async releasePlayer(): Promise<void> {
    if (this.nativePlayerObj !== BigInt(0)) {
      try {
        player.releasePlayer(this.nativePlayerObj);
        this.nativePlayerObj = BigInt(0);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Release player failed: ${error.code}, message: ${error.message}`);
      }
    }
  }

  async cleanup(): Promise<void> {
    try {
      this.stopTimer();
      this.unregisterEventListeners();
      await this.releasePlayer();
    } catch (error) {
      hilog.error(0x0000, TAG, `cleanup catch error, code: ${error.code}, message: ${error.message}`);
    }
  }
}
