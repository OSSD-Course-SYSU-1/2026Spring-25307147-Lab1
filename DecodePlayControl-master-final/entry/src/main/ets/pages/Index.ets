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

import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { VideoPlayView } from '../view/VideoPlayView';
import { VideoPlayViewModel } from '../viewmodel/VideoPlayViewModel';
import { FeatureManager } from '../common/FeatureManager';
import { BreakpointType } from '../common/models/BreakpointType';
import { FlowState } from '../common/models/FlowState';
import { DeviceCapability } from '../common/models/DeviceCapability';
import { AppState, createDefaultAppState } from '../common/models/AppState';
import { VideoPlaybackState, createVideoPlaybackState } from '../common/models/VideoPlaybackState';
import { DanmakuState, createDanmakuState } from '../common/models/DanmakuState';
import { DeviceSelectorPanel } from '../view/DeviceSelectorPanel';
import { ResponsiveContainer } from '../view/ResponsiveContainer';

const VIDEO_NAMES = ['1.mp4', '2.mp4', '3.mp4'];
const TAG = 'INDEX';

@Entry
@Component
struct Index {
  @State videoResources : resourceManager.RawFileDescriptor[] = [];
  @State viewModel: VideoPlayViewModel = new VideoPlayViewModel();
  @State isFullScreen: boolean = false;
  
  @State currentBreakpoint: BreakpointType = BreakpointType.SM;
  @State flowState: FlowState = FlowState.IDLE;
  @State availableDevices: DeviceCapability[] = [];
  @State selectedDeviceId: string = '';
  @State showDevicePanel: boolean = false;
  
  @State appState: AppState = createDefaultAppState();
  @State videoPlaybackState: VideoPlaybackState = createVideoPlaybackState();
  @State danmakuState: DanmakuState = createDanmakuState();
  
  private featureManager: FeatureManager = FeatureManager.getInstance();
  private isFeatureInitialized: boolean = false;

  aboutToAppear(): void {
    try {
      this.videoResources.length = 0;
      for (let i = 0; i< VIDEO_NAMES.length; i++) {
        let rawDes = this.getUIContext().getHostContext()?.resourceManager.getRawFdSync(VIDEO_NAMES[i]);
        if (rawDes) {
          this.videoResources.push(rawDes);
        }
      }
      
      this.initFeatureManager();
    } catch (error) {
      hilog.error(0x0000, TAG, `aboutToAppear catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message}`);
    }
  }
  
  async initFeatureManager(): Promise<void> {
    if (this.isFeatureInitialized) {
      return;
    }
    
    try {
      const context = this.getUIContext().getHostContext();
      if (context) {
        await this.featureManager.init(context as common.UIAbilityContext, 'current-device');
        
        this.featureManager.getResponsiveLayout().onBreakpointChange((breakpoint: BreakpointType) => {
          this.currentBreakpoint = breakpoint;
          hilog.info(0x0000, TAG, `Breakpoint changed to: ${breakpoint}`);
        });
        
        this.featureManager.getDeviceFlow().onFlowStateChange((state: FlowState) => {
          this.flowState = state;
          hilog.info(0x0000, TAG, `Flow state changed to: ${state}`);
        });
        
        this.registerStateCollectors();
        this.registerStateRestorers();
        
        this.isFeatureInitialized = true;
        hilog.info(0x0000, TAG, 'FeatureManager initialized successfully');
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize FeatureManager: ${(error as Error).message}`);
    }
  }
  
  registerStateCollectors(): void {
    this.featureManager.registerStateCollectors(
      () => this.appState,
      () => this.videoPlaybackState,
      () => this.danmakuState
    );
  }
  
  registerStateRestorers(): void {
    this.featureManager.registerStateRestorers(
      (state: AppState) => {
        this.appState = state;
        this.isFullScreen = state.isFullScreen;
      },
      (state: VideoPlaybackState) => {
        this.videoPlaybackState = state;
      },
      (state: DanmakuState) => {
        this.danmakuState = state;
      }
    );
  }
  
  async discoverDevices(): Promise<void> {
    try {
      this.availableDevices = await this.featureManager.getDeviceFlow().discoverDevices();
      hilog.info(0x0000, TAG, `Discovered ${this.availableDevices.length} devices`);
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to discover devices: ${(error as Error).message}`);
    }
  }
  
  async executeFlow(): Promise<void> {
    if (this.selectedDeviceId === '') {
      hilog.warn(0x0000, TAG, 'No device selected');
      return;
    }
    
    try {
      const success = await this.featureManager.getDeviceFlow().executeDeviceFlow(this.selectedDeviceId);
      if (success) {
        hilog.info(0x0000, TAG, 'Device flow executed successfully');
      } else {
        hilog.error(0x0000, TAG, 'Device flow execution failed');
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to execute device flow: ${(error as Error).message}`);
    }
  }

  aboutToDisappear(): void {
    try {
      for (let i = 0; i< VIDEO_NAMES.length; i++) {
        this.getUIContext().getHostContext()?.resourceManager.closeRawFdSync(VIDEO_NAMES[i]);
      }
      
      if (this.isFeatureInitialized) {
        this.featureManager.destroy();
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `aboutToDisappear catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message}`);
    }
  }

  onBackPress(): boolean | void {
    if (this.isFullScreen) {
      this.isFullScreen = false;
      return true;
    }
    return false;
  }

  build() {
    Column() {
      ResponsiveContainer({ currentBreakpoint: this.currentBreakpoint }) {
        Stack() {
          VideoPlayView({
            viewModel: this.viewModel,
            videoSources: $videoResources,
            isFullScreen: this.isFullScreen
          });
          
          if (!this.isFullScreen && this.currentBreakpoint !== BreakpointType.SM) {
            this.FlowControlButton();
          }
          
          if (this.showDevicePanel) {
            this.DevicePanelOverlay();
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  FlowControlButton() {
    Button('流转')
      .width(60)
      .height(40)
      .fontSize(14)
      .position({ x: '80%', y: 20 })
      .onClick(async () => {
        await this.discoverDevices();
        this.showDevicePanel = true;
      })
  }
  
  @Builder
  DevicePanelOverlay() {
    Column() {
      Blank()
        .layoutWeight(1)
        .onClick(() => {
          this.showDevicePanel = false;
        })
      
      Column() {
        Row() {
          Text('设备流转')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          
          Button('关闭')
            .width(60)
            .height(32)
            .fontSize(14)
            .onClick(() => {
              this.showDevicePanel = false;
            })
        }
        .width('100%')
        .margin({ bottom: 16 })
        
        DeviceSelectorPanel({ 
          devices: this.availableDevices,
          currentFlowState: this.flowState,
          selectedDeviceId: $selectedDeviceId
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
  }
}