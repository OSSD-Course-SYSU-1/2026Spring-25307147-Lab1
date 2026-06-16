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
import { QualityManager } from './QualityManager';
import { VolumeManager } from './VolumeManager';
import { ProgressTracker } from './ProgressTracker';
import { DanmakuManager } from './DanmakuManager';
import { EndStateHandler } from './EndStateHandler';
import { ProgressStorage } from '../service/ProgressStorage';
import { ConfigStorage } from '../service/ConfigStorage';
import { QualityItem, QualityLevel } from '../model/QualityModel';
import { DanmakuItem } from '../model/DanmakuModel';

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

  @Track qualityList: QualityItem[] = [];
  @Track currentQuality: QualityItem | null = null;
  @Track isQualityVisible: boolean = false;
  @Track isQualitySwitching: boolean = false;

  @Track volume: number = 50;
  @Track isMuted: boolean = false;
  @Track isVolumeVisible: boolean = false;

  @Track hasProgress: boolean = false;
  @Track isProgressRecallVisible: boolean = false;
  @Track lastProgressPosition: number = 0;
  @Track lastProgressDuration: number = 0;

  @Track danmakuList: DanmakuItem[] = [];
  @Track isDanmakuEnabled: boolean = true;
  @Track isDanmakuInputVisible: boolean = false;

  @Track isPlaybackEndVisible: boolean = false;
  @Track endCountdown: number = 10;
  @Track isLastEpisode: boolean = false;

  public videoSources: resourceManager.RawFileDescriptor[] = [];
  public nativePlayerObj: bigint = BigInt(0);
  
  private timerId: number = -1;
  private hostContext: Context | undefined = undefined;

  private qualityManager: QualityManager | null = null;
  private volumeManager: VolumeManager | null = null;
  private progressTracker: ProgressTracker | null = null;
  private danmakuManager: DanmakuManager | null = null;
  private endStateHandler: EndStateHandler | null = null;
  private progressStorage: ProgressStorage | null = null;
  private configStorage: ConfigStorage | null = null;
  
  private currentVideoId: string = 'default_video';

  setUIContext(uiContext: UIContext): void {
    this.hostContext = uiContext.getHostContext();
  }

  async initialize(): Promise<void> {
    try {
      await this.setWindowProperties();
      this.registerEventListeners();
      await this.initializeManagers();
      this.startTimer();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `initialize catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  private async initializeManagers(): Promise<void> {
    if (!this.hostContext) {
      return;
    }

    this.configStorage = new ConfigStorage(this.hostContext);
    this.progressStorage = new ProgressStorage(this.hostContext);
    
    await this.configStorage.init();
    await this.progressStorage.init();

    this.qualityManager = new QualityManager(this.configStorage);
    this.volumeManager = new VolumeManager(this.configStorage);
    this.progressTracker = new ProgressTracker(this.progressStorage);
    this.danmakuManager = new DanmakuManager(this.configStorage);
    this.endStateHandler = new EndStateHandler();

    await this.qualityManager.initialize();
    await this.volumeManager.initialize();
    await this.danmakuManager.initialize();

    this.qualityList = await this.qualityManager.loadQualityList();
    this.currentQuality = this.qualityManager.getCurrentQuality();
    
    const volumeConfig = this.volumeManager.getConfig();
    this.volume = volumeConfig.value;
    this.isMuted = volumeConfig.isMuted;

    this.isDanmakuEnabled = this.danmakuManager.isEnabled();

    this.setupEndStateCallbacks();

    hilog.info(DOMAIN, TAG, 'All managers initialized');
  }

  private setupEndStateCallbacks(): void {
    if (this.endStateHandler) {
      this.endStateHandler.onReplay = () => {
        this.replayCurrentVideo();
      };
      this.endStateHandler.onPlayNext = () => {
        this.playNextEpisode();
      };
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
          
          if (this.progressTracker) {
            this.progressTracker.updatePosition(this.currentTime, this.durationTime);
          }
          
          if (this.danmakuManager) {
            this.danmakuList = this.danmakuManager.getVisibleDanmaku(this.currentTime);
          }
        } catch (error) {
          hilog.error(DOMAIN, TAG, `getRenderTime failed: ${error.code}, message: ${error.message}`);
        }
      }
      
      if (this.endStateHandler && this.endStateHandler.isCountingDown()) {
        this.endCountdown = this.endStateHandler.getCountdown();
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
      
      if (this.progressTracker) {
        this.progressTracker.cleanup();
      }
      if (this.volumeManager) {
        this.volumeManager.cleanup();
      }
      if (this.danmakuManager) {
        this.danmakuManager.cleanup();
      }
      if (this.endStateHandler) {
        this.endStateHandler.cleanup();
      }
      
      await this.releasePlayer();
    } catch (error) {
      hilog.error(0x0000, TAG, `cleanup catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  async onQualitySelected(qualityId: QualityLevel): Promise<void> {
    if (!this.qualityManager || this.isQualitySwitching) {
      return;
    }

    this.isQualitySwitching = true;
    const success = await this.qualityManager.switchQuality(qualityId);
    
    if (success) {
      this.currentQuality = this.qualityManager.getCurrentQuality();
    }
    
    this.isQualitySwitching = false;
    this.isQualityVisible = false;
  }

  toggleQualitySelector(): void {
    this.isQualityVisible = !this.isQualityVisible;
  }

  async onVolumeChange(newVolume: number): Promise<void> {
    this.volume = newVolume;
    if (this.volumeManager) {
      await this.volumeManager.setVolume(newVolume);
    }
  }

  async toggleMute(): Promise<void> {
    if (this.volumeManager) {
      const muted = await this.volumeManager.toggleMute();
      this.isMuted = muted;
    }
  }

  async increaseVolume(): Promise<void> {
    if (this.volumeManager) {
      const newVolume = await this.volumeManager.increaseVolume();
      this.volume = newVolume;
    }
  }

  async decreaseVolume(): Promise<void> {
    if (this.volumeManager) {
      const newVolume = await this.volumeManager.decreaseVolume();
      this.volume = newVolume;
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
    
    if (this.progressTracker) {
      this.progressTracker.stopTracking();
    }
    
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
        
        if (this.qualityManager) {
          this.qualityManager.setNativePlayer(this.nativePlayerObj);
        }
        
        await this.loadVideoProgress();
        
        if (this.progressTracker) {
          this.progressTracker.setVideoInfo(this.currentVideoId, index);
          this.progressTracker.startTracking();
        }
        
        if (this.danmakuManager) {
          this.danmakuList = await this.danmakuManager.loadDanmaku(this.currentVideoId);
        }
        
        if (this.endStateHandler) {
          this.endStateHandler.setEpisodeInfo(index, this.videoSources.length);
        }
        
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

  private async loadVideoProgress(): Promise<void> {
    if (!this.progressTracker) {
      return;
    }

    const record = await this.progressTracker.loadProgress();
    if (record && record.position > 0) {
      this.lastProgressPosition = record.position;
      this.lastProgressDuration = record.duration;
      this.hasProgress = true;
      this.isProgressRecallVisible = true;
    } else {
      this.hasProgress = false;
      this.isProgressRecallVisible = false;
    }
  }

  async recallToLastProgress(): Promise<void> {
    if (this.lastProgressPosition > 0 && this.nativePlayerObj !== BigInt(0)) {
      await this.performSeek(this.lastProgressPosition);
      this.isProgressRecallVisible = false;
    }
  }

  dismissProgressRecall(): void {
    this.isProgressRecallVisible = false;
    this.hasProgress = false;
  }

  async sendDanmaku(content: string, color: string): Promise<void> {
    if (!this.danmakuManager) {
      return;
    }

    const danmaku = await this.danmakuManager.sendDanmaku(content, this.currentTime, color);
    if (danmaku) {
      this.danmakuList = [...this.danmakuList, danmaku];
    }
  }

  toggleDanmaku(): void {
    if (this.danmakuManager) {
      this.danmakuManager.toggleVisibility();
      this.isDanmakuEnabled = this.danmakuManager.isEnabled();
    }
  }

  onPlaybackEnd(): void {
    if (this.endStateHandler) {
      const isLast = this.chooseNumber >= this.videoSources.length - 1;
      this.isLastEpisode = isLast;
      this.endStateHandler.onPlaybackEnd(isLast);
      this.isPlaybackEndVisible = true;
    }
  }

  replayCurrentVideo(): void {
    this.isPlaybackEndVisible = false;
    if (this.nativePlayerObj !== BigInt(0)) {
      player.seekVideo(this.nativePlayerObj, 0);
      player.play(this.nativePlayerObj);
      this.playState = PlayerState.PLAYING;
    }
  }

  playNextEpisode(): void {
    this.isPlaybackEndVisible = false;
    if (this.chooseNumber < this.videoSources.length - 1) {
      const nextIndex = this.chooseNumber + 1;
      const nextRawDes = this.videoSources[nextIndex];
      if (nextRawDes) {
        this.onVideoSelected(nextIndex, nextRawDes);
      }
    }
  }

  dismissPlaybackEnd(): void {
    if (this.endStateHandler) {
      this.endStateHandler.cancelCountdown();
    }
    this.isPlaybackEndVisible = false;
  }
}
