import { DeviceCapability } from '../models/DeviceCapability';
import { DeviceType } from '../models/DeviceType';

export type DeviceFilter = (device: DeviceCapability) => boolean;

export interface IDeviceRegistry {
  registerDevice(device: DeviceCapability): void;
  
  unregisterDevice(deviceId: string): void;
  
  getDeviceCapability(deviceId: string): DeviceCapability | undefined;
  
  getAllDevices(): DeviceCapability[];
  
  filterDevices(filter: DeviceFilter): DeviceCapability[];
  
  getDevicesByType(type: DeviceType): DeviceCapability[];
  
  clear(): void;
}
