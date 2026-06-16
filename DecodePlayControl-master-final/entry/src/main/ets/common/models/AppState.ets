import { BreakpointType } from './BreakpointType';
import { FlowState } from './FlowState';
import { FoldStatus } from './FoldStatus';

export interface AppState {
  readonly currentBreakpoint: BreakpointType;
  readonly isFullScreen: boolean;
  readonly foldStatus: FoldStatus;
  readonly flowState: FlowState;
  readonly orientation: 'portrait' | 'landscape';
}

export function createDefaultAppState(): AppState {
  return {
    currentBreakpoint: BreakpointType.SM,
    isFullScreen: false,
    foldStatus: FoldStatus.UNFOLDED,
    flowState: FlowState.IDLE,
    orientation: 'portrait'
  };
}
