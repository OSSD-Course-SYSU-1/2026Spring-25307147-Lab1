import { AppState } from './AppState';
import { VideoPlaybackState } from './VideoPlaybackState';
import { DanmakuState } from './DanmakuState';
import { UserPreferences } from './UserPreferences';

export interface SnapshotMetadata {
  readonly version: string;
  readonly timestamp: number;
  readonly sourceDeviceId: string;
  readonly checksum: string;
}

export interface PageRouteStack {
  readonly currentPage: string;
  readonly params: Record<string, string>;
}

export interface ComponentState {
  readonly isFullScreen: boolean;
  readonly showControls: boolean;
  readonly volumeSliderVisible: boolean;
}

export interface BusinessData {
  readonly videoPlaybackState: VideoPlaybackState;
  readonly danmakuState: DanmakuState;
  readonly userPreferences: UserPreferences;
}

export interface AppStateSnapshot {
  readonly metadata: SnapshotMetadata;
  readonly appState: AppState;
  readonly pageRouteStack: PageRouteStack[];
  readonly componentState: ComponentState;
  readonly businessData: BusinessData;
}

export function createSnapshotMetadata(
  version: string = '1.0',
  sourceDeviceId: string,
  checksum: string
): SnapshotMetadata {
  return {
    version,
    timestamp: Date.now(),
    sourceDeviceId,
    checksum
  };
}
