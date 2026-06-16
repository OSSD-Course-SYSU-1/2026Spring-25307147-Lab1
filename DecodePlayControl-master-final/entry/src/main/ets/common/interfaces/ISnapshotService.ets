import { AppStateSnapshot } from '../models/AppStateSnapshot';
import { AppState } from '../models/AppState';
import { VideoPlaybackState } from '../models/VideoPlaybackState';
import { DanmakuState } from '../models/DanmakuState';

export type StateCollector<T> = () => T;

export type StateRestorer<T> = (state: T) => void;

export interface ISnapshotService {
  generateSnapshot(): AppStateSnapshot;
  
  restoreSnapshot(snapshot: AppStateSnapshot): Promise<void>;
  
  serializeSnapshot(snapshot: AppStateSnapshot): string;
  
  deserializeSnapshot(jsonString: string): AppStateSnapshot;
  
  registerAppStateCollector(collector: StateCollector<AppState>): void;
  
  registerVideoStateCollector(collector: StateCollector<VideoPlaybackState>): void;
  
  registerDanmakuStateCollector(collector: StateCollector<DanmakuState>): void;
  
  registerAppStateRestorer(restorer: StateRestorer<AppState>): void;
  
  registerVideoStateRestorer(restorer: StateRestorer<VideoPlaybackState>): void;
  
  registerDanmakuStateRestorer(restorer: StateRestorer<DanmakuState>): void;
}
