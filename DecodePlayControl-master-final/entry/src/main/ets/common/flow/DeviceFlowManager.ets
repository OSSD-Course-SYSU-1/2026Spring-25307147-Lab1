import { DeviceCapability, CompatibilityResult } from '../models/DeviceCapability';
import { FlowState } from '../models/FlowState';
import { AppStateSnapshot } from '../models/AppStateSnapshot';
import { FlowRecord, createFlowRecord, generateUUID } from '../models/FlowRecord';
import { IDeviceFlow, FlowStateChangeListener } from '../interfaces/IDeviceFlow';
import { DeviceRegistry } from '../device/DeviceRegistry';
import { DeviceDiscoveryService } from '../device/DeviceDiscoveryService';
import { SnapshotService } from '../snapshot/SnapshotService';

export class DeviceFlowManager implements IDeviceFlow {
  private registry: DeviceRegistry;
  private discoveryService: DeviceDiscoveryService;
  private snapshotService: SnapshotService;
  
  private currentFlowState: FlowState = FlowState.IDLE;
  private flowStateListeners: Set<FlowStateChangeListener> = new Set();
  private currentFlowRecord: FlowRecord | null = null;
  private currentDeviceId: string = '';
  
  private flowTimeout: number = 10000;
  private retryCount: number = 3;
  
  constructor(
    registry: DeviceRegistry,
    discoveryService: DeviceDiscoveryService,
    snapshotService: SnapshotService
  ) {
    this.registry = registry;
    this.discoveryService = discoveryService;
    this.snapshotService = snapshotService;
  }
  
  setCurrentDeviceId(deviceId: string): void {
    this.currentDeviceId = deviceId;
    this.snapshotService.setCurrentDeviceId(deviceId);
  }
  
  async discoverDevices(): Promise<DeviceCapability[]> {
    this.setFlowState(FlowState.DISCOVERING);
    
    try {
      const devices = await this.discoveryService.discoverDevices();
      this.setFlowState(FlowState.IDLE);
      return devices;
    } catch (error) {
      console.error('Discover devices failed:', error);
      this.setFlowState(FlowState.IDLE);
      return [];
    }
  }
  
  async checkDeviceCompatibility(targetDevice: DeviceCapability): Promise<CompatibilityResult> {
    const sourceDevice = this.registry.getDeviceCapability(this.currentDeviceId);
    
    if (!sourceDevice) {
      return {
        isCompatible: false,
        reason: 'Source device not found'
      };
    }
    
    return this.discoveryService.checkCompatibility(sourceDevice, targetDevice);
  }
  
  async executeDeviceFlow(targetDeviceId: string): Promise<boolean> {
    const targetDevice = this.registry.getDeviceCapability(targetDeviceId);
    
    if (!targetDevice) {
      console.error('Target device not found');
      return false;
    }
    
    const compatibility = await this.checkDeviceCompatibility(targetDevice);
    if (!compatibility.isCompatible) {
      console.error('Device not compatible:', compatibility.reason);
      return false;
    }
    
    const flowId = generateUUID();
    this.currentFlowRecord = createFlowRecord(
      flowId,
      this.currentDeviceId,
      targetDeviceId,
      FlowState.PREPARING
    );
    
    this.setFlowState(FlowState.PREPARING);
    
    try {
      const snapshot = await this.getSnapshotForFlow();
      
      this.setFlowState(FlowState.TRANSFERRING);
      
      const success = await this.transferSnapshot(targetDeviceId, snapshot);
      
      if (success) {
        this.setFlowState(FlowState.COMPLETED);
        return true;
      } else {
        this.setFlowState(FlowState.FAILED);
        return false;
      }
    } catch (error) {
      console.error('Device flow failed:', error);
      this.setFlowState(FlowState.FAILED);
      return false;
    }
  }
  
  private async transferSnapshot(
    targetDeviceId: string, 
    snapshot: AppStateSnapshot
  ): Promise<boolean> {
    for (let i = 0; i < this.retryCount; i++) {
      try {
        const snapshotString = this.snapshotService.serializeSnapshot(snapshot);
        
        await this.sendDataToTarget(targetDeviceId, snapshotString);
        
        return true;
      } catch (error) {
        console.error(`Transfer attempt ${i + 1} failed:`, error);
        
        if (i < this.retryCount - 1) {
          await this.delay(1000 * (i + 1));
        }
      }
    }
    
    return false;
  }
  
  private async sendDataToTarget(targetDeviceId: string, data: string): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const sessionId = generateUUID();
        
        console.log(`Sending data to device ${targetDeviceId}, sessionId: ${sessionId}`);
        
        setTimeout(() => {
          resolve();
        }, 1000);
      } catch (error) {
        reject(error);
      }
    });
  }
  
  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  
  async cancelCurrentFlow(): Promise<void> {
    if (this.currentFlowState !== FlowState.IDLE) {
      this.setFlowState(FlowState.IDLE);
      this.currentFlowRecord = null;
    }
  }
  
  getCurrentFlowState(): FlowState {
    return this.currentFlowState;
  }
  
  private setFlowState(state: FlowState): void {
    this.currentFlowState = state;
    this.notifyFlowStateChange(state);
  }
  
  onFlowStateChange(listener: FlowStateChangeListener): void {
    this.flowStateListeners.add(listener);
  }
  
  offFlowStateChange(listener: FlowStateChangeListener): void {
    this.flowStateListeners.delete(listener);
  }
  
  private notifyFlowStateChange(state: FlowState): void {
    this.flowStateListeners.forEach((listener) => {
      try {
        listener(state);
      } catch (error) {
        console.error('FlowStateChangeListener error:', error);
      }
    });
  }
  
  async getSnapshotForFlow(): Promise<AppStateSnapshot> {
    return this.snapshotService.generateSnapshot();
  }
  
  async restoreFromSnapshot(snapshot: AppStateSnapshot): Promise<void> {
    this.setFlowState(FlowState.RESTORING);
    
    try {
      await this.snapshotService.restoreSnapshot(snapshot);
      this.setFlowState(FlowState.COMPLETED);
    } catch (error) {
      console.error('Restore snapshot failed:', error);
      this.setFlowState(FlowState.FAILED);
      throw new Error('Restore snapshot failed');
    }
  }
  
  setFlowTimeout(timeout: number): void {
    this.flowTimeout = timeout;
  }
  
  setRetryCount(count: number): void {
    this.retryCount = count;
  }
  
  destroy(): void {
    this.discoveryService.destroy();
    this.flowStateListeners.clear();
    this.currentFlowRecord = null;
  }
}
