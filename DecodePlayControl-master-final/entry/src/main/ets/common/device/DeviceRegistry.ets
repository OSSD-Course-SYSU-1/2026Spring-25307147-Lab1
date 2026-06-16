import { DeviceCapability, CompatibilityResult } from '../models/DeviceCapability';
import { IDeviceRegistry, DeviceFilter } from '../interfaces/IDeviceRegistry';
import { DeviceType } from '../models/DeviceType';

export class DeviceRegistry implements IDeviceRegistry {
  private devices: Map<string, DeviceCapability> = new Map();
  
  registerDevice(device: DeviceCapability): void {
    if (!device.deviceId) {
      throw new Error('Device ID is required');
    }
    this.devices.set(device.deviceId, device);
  }
  
  unregisterDevice(deviceId: string): void {
    this.devices.delete(deviceId);
  }
  
  getDeviceCapability(deviceId: string): DeviceCapability | undefined {
    return this.devices.get(deviceId);
  }
  
  getAllDevices(): DeviceCapability[] {
    return Array.from(this.devices.values());
  }
  
  filterDevices(filter: DeviceFilter): DeviceCapability[] {
    const result: DeviceCapability[] = [];
    this.devices.forEach((device) => {
      if (filter(device)) {
        result.push(device);
      }
    });
    return result;
  }
  
  getDevicesByType(type: DeviceType): DeviceCapability[] {
    return this.filterDevices((device) => device.deviceType === type);
  }
  
  clear(): void {
    this.devices.clear();
  }
}
