import { AppStateSnapshot, SnapshotMetadata, PageRouteStack, ComponentState, BusinessData } from '../models/AppStateSnapshot';
import { AppState } from '../models/AppState';
import { VideoPlaybackState } from '../models/VideoPlaybackState';
import { DanmakuState } from '../models/DanmakuState';
import { UserPreferences } from '../models/UserPreferences';
import { ISnapshotService, StateCollector, StateRestorer } from '../interfaces/ISnapshotService';
import { DataValidator } from '../utils/DataValidator';
import { createSnapshotMetadata } from '../models/AppStateSnapshot';
import { createDefaultUserPreferences } from '../models/UserPreferences';

export class SnapshotService implements ISnapshotService {
  private appStateCollector: StateCollector<AppState> | null = null;
  private videoStateCollector: StateCollector<VideoPlaybackState> | null = null;
  private danmakuStateCollector: StateCollector<DanmakuState> | null = null;
  private userPreferencesCollector: StateCollector<UserPreferences> | null = null;
  
  private appStateRestorer: StateRestorer<AppState> | null = null;
  private videoStateRestorer: StateRestorer<VideoPlaybackState> | null = null;
  private danmakuStateRestorer: StateRestorer<DanmakuState> | null = null;
  private userPreferencesRestorer: StateRestorer<UserPreferences> | null = null;
  
  private currentDeviceId: string = '';
  
  setCurrentDeviceId(deviceId: string): void {
    this.currentDeviceId = deviceId;
  }
  
  generateSnapshot(): AppStateSnapshot {
    if (!this.appStateCollector || !this.videoStateCollector || !this.danmakuStateCollector) {
      throw new Error('State collectors not registered');
    }
    
    const appState = this.appStateCollector();
    const videoPlaybackState = this.videoStateCollector();
    const danmakuState = this.danmakuStateCollector();
    const userPreferences = this.userPreferencesCollector 
      ? this.userPreferencesCollector() 
      : createDefaultUserPreferences();
    
    const pageRouteStack: PageRouteStack[] = [
      {
        currentPage: 'Index',
        params: {}
      }
    ];
    
    const componentState: ComponentState = {
      isFullScreen: appState.isFullScreen,
      showControls: true,
      volumeSliderVisible: false
    };
    
    const businessData: BusinessData = {
      videoPlaybackState,
      danmakuState,
      userPreferences
    };
    
    const rawData = JSON.stringify(businessData);
    const checksum = DataValidator.calculateChecksum(rawData);
    
    const metadata = createSnapshotMetadata('1.0', this.currentDeviceId, checksum);
    
    return {
      metadata,
      appState,
      pageRouteStack,
      componentState,
      businessData
    };
  }
  
  async restoreSnapshot(snapshot: AppStateSnapshot): Promise<void> {
    if (!DataValidator.validateSnapshot(snapshot)) {
      throw new Error('Invalid snapshot');
    }
    
    if (this.appStateRestorer) {
      this.appStateRestorer(snapshot.appState);
    }
    
    if (this.videoStateRestorer) {
      this.videoStateRestorer(snapshot.businessData.videoPlaybackState);
    }
    
    if (this.danmakuStateRestorer) {
      this.danmakuStateRestorer(snapshot.businessData.danmakuState);
    }
    
    if (this.userPreferencesRestorer) {
      this.userPreferencesRestorer(snapshot.businessData.userPreferences);
    }
  }
  
  serializeSnapshot(snapshot: AppStateSnapshot): string {
    return JSON.stringify(snapshot);
  }
  
  deserializeSnapshot(jsonString: string): AppStateSnapshot {
    if (!DataValidator.validateJSON(jsonString)) {
      throw new Error('Invalid JSON string');
    }
    
    const snapshot = JSON.parse(jsonString) as AppStateSnapshot;
    
    if (!DataValidator.validateSnapshot(snapshot)) {
      throw new Error('Invalid snapshot structure');
    }
    
    return snapshot;
  }
  
  registerAppStateCollector(collector: StateCollector<AppState>): void {
    this.appStateCollector = collector;
  }
  
  registerVideoStateCollector(collector: StateCollector<VideoPlaybackState>): void {
    this.videoStateCollector = collector;
  }
  
  registerDanmakuStateCollector(collector: StateCollector<DanmakuState>): void {
    this.danmakuStateCollector = collector;
  }
  
  registerUserPreferencesCollector(collector: StateCollector<UserPreferences>): void {
    this.userPreferencesCollector = collector;
  }
  
  registerAppStateRestorer(restorer: StateRestorer<AppState>): void {
    this.appStateRestorer = restorer;
  }
  
  registerVideoStateRestorer(restorer: StateRestorer<VideoPlaybackState>): void {
    this.videoStateRestorer = restorer;
  }
  
  registerDanmakuStateRestorer(restorer: StateRestorer<DanmakuState>): void {
    this.danmakuStateRestorer = restorer;
  }
  
  registerUserPreferencesRestorer(restorer: StateRestorer<UserPreferences>): void {
    this.userPreferencesRestorer = restorer;
  }
}
