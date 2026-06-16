import { common } from '@kit.AbilityKit';
import { ResponsiveLayoutManager } from './adapter/ResponsiveLayoutManager';
import { DeviceFlowManager } from './flow/DeviceFlowManager';
import { SnapshotService } from './snapshot/SnapshotService';
import { DeviceRegistry } from './device/DeviceRegistry';
import { DeviceDiscoveryService } from './device/DeviceDiscoveryService';
import { BreakpointType } from './models/BreakpointType';
import { FlowState } from './models/FlowState';
import { AppState } from './models/AppState';
import { VideoPlaybackState } from './models/VideoPlaybackState';
import { DanmakuState } from './models/DanmakuState';

export class FeatureManager {
  private static instance: FeatureManager | null = null;
  
  private responsiveLayout: ResponsiveLayoutManager;
  private deviceFlow: DeviceFlowManager;
  private snapshotService: SnapshotService;
  private deviceRegistry: DeviceRegistry;
  private discoveryService: DeviceDiscoveryService;
  
  private isInitialized: boolean = false;
  
  private constructor() {
    this.deviceRegistry = new DeviceRegistry();
    this.snapshotService = new SnapshotService();
    this.discoveryService = new DeviceDiscoveryService(this.deviceRegistry);
    this.responsiveLayout = new ResponsiveLayoutManager();
    this.deviceFlow = new DeviceFlowManager(
      this.deviceRegistry,
      this.discoveryService,
      this.snapshotService
    );
  }
  
  static getInstance(): FeatureManager {
    if (!FeatureManager.instance) {
      FeatureManager.instance = new FeatureManager();
    }
    return FeatureManager.instance;
  }
  
  async init(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      await this.responsiveLayout.init(context);
      await this.discoveryService.init();
      
      this.deviceFlow.setCurrentDeviceId(deviceId);
      
      this.isInitialized = true;
    } catch (error) {
      console.error('FeatureManager init failed:', error);
      throw new Error('FeatureManager init failed');
    }
  }
  
  getResponsiveLayout(): ResponsiveLayoutManager {
    return this.responsiveLayout;
  }
  
  getDeviceFlow(): DeviceFlowManager {
    return this.deviceFlow;
  }
  
  getSnapshotService(): SnapshotService {
    return this.snapshotService;
  }
  
  getDeviceRegistry(): DeviceRegistry {
    return this.deviceRegistry;
  }
  
  getCurrentBreakpoint(): BreakpointType {
    return this.responsiveLayout.getCurrentBreakpoint();
  }
  
  getCurrentFlowState(): FlowState {
    return this.deviceFlow.getCurrentFlowState();
  }
  
  registerStateCollectors(
    appStateCollector: () => AppState,
    videoStateCollector: () => VideoPlaybackState,
    danmakuStateCollector: () => DanmakuState
  ): void {
    this.snapshotService.registerAppStateCollector(appStateCollector);
    this.snapshotService.registerVideoStateCollector(videoStateCollector);
    this.snapshotService.registerDanmakuStateCollector(danmakuStateCollector);
  }
  
  registerStateRestorers(
    appStateRestorer: (state: AppState) => void,
    videoStateRestorer: (state: VideoPlaybackState) => void,
    danmakuStateRestorer: (state: DanmakuState) => void
  ): void {
    this.snapshotService.registerAppStateRestorer(appStateRestorer);
    this.snapshotService.registerVideoStateRestorer(videoStateRestorer);
    this.snapshotService.registerDanmakuStateRestorer(danmakuStateRestorer);
  }
  
  destroy(): void {
    this.responsiveLayout.destroy();
    this.deviceFlow.destroy();
    this.isInitialized = false;
    FeatureManager.instance = null;
  }
}
