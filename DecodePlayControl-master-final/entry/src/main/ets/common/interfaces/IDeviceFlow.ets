import { DeviceCapability, CompatibilityResult } from '../models/DeviceCapability';
import { FlowState } from '../models/FlowState';
import { AppStateSnapshot } from '../models/AppStateSnapshot';

export type FlowStateChangeListener = (state: FlowState) => void;

export interface IDeviceFlow {
  discoverDevices(): Promise<DeviceCapability[]>;
  
  checkDeviceCompatibility(targetDevice: DeviceCapability): Promise<CompatibilityResult>;
  
  executeDeviceFlow(targetDeviceId: string): Promise<boolean>;
  
  cancelCurrentFlow(): Promise<void>;
  
  getCurrentFlowState(): FlowState;
  
  onFlowStateChange(listener: FlowStateChangeListener): void;
  
  offFlowStateChange(listener: FlowStateChangeListener): void;
  
  getSnapshotForFlow(): Promise<AppStateSnapshot>;
}
