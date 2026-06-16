import { FlowState } from './FlowState';

export interface FlowRecord {
  readonly flowId: string;
  readonly sourceDeviceId: string;
  readonly targetDeviceId: string;
  readonly flowState: FlowState;
  readonly startTime: number;
  readonly endTime?: number;
  readonly errorMessage?: string;
}

export function createFlowRecord(
  flowId: string,
  sourceDeviceId: string,
  targetDeviceId: string,
  flowState: FlowState = FlowState.IDLE
): FlowRecord {
  return {
    flowId,
    sourceDeviceId,
    targetDeviceId,
    flowState,
    startTime: Date.now()
  };
}

export function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
