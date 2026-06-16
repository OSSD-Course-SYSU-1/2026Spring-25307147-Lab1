import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { DeviceCapability, CompatibilityResult, ScreenSize } from '../models/DeviceCapability';
import { DeviceType } from '../models/DeviceType';
import { PerformanceLevel } from '../models/PerformanceLevel';
import { DeviceRegistry } from './DeviceRegistry';

interface DeviceBasicInfo {
  deviceId: string;
  deviceName: string;
  deviceType?: string;
  screenWidth?: number;
  screenHeight?: number;
  apiVersion?: number;
  state?: string;
}

interface DeviceInfo {
  bundleName: string;
  abilityName: string;
}

export class DeviceDiscoveryService {
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private registry: DeviceRegistry;
  private discoveryCallback: ((devices: DeviceCapability[]) => void) | null = null;
  
  constructor(registry: DeviceRegistry) {
    this.registry = registry;
  }
  
  async init(): Promise<void> {
    try {
      const deviceInfo: DeviceInfo = {
        bundleName: 'com.huawei.decodeplaycontrol',
        abilityName: 'EntryAbility'
      };
      
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.huawei.decodeplaycontrol');
    } catch (error) {
      console.error('DeviceDiscoveryService init failed:', error);
      throw new Error('DeviceDiscoveryService init failed');
    }
  }
  
  private handleDeviceStateChange(deviceInfo: DeviceBasicInfo): void {
    const capability = this.convertToDeviceCapability(deviceInfo);
    
    if (deviceInfo.state === 'ONLINE') {
      this.registry.registerDevice(capability);
    } else {
      this.registry.unregisterDevice(capability.deviceId);
    }
    
    if (this.discoveryCallback) {
      this.discoveryCallback(this.registry.getAllDevices());
    }
  }
  
  private convertToDeviceCapability(deviceInfo: DeviceBasicInfo): DeviceCapability {
    const screenSize: ScreenSize = {
      width: deviceInfo.screenWidth || 1080,
      height: deviceInfo.screenHeight || 1920
    };
    
    const deviceType = this.inferDeviceType(deviceInfo);
    const performanceLevel = this.inferPerformanceLevel(deviceInfo);
    
    return {
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      deviceType,
      screenSize,
      apiVersion: deviceInfo.apiVersion || 9,
      performanceLevel,
      supportsVideoPlayback: true,
      supportsScreenMirroring: deviceType !== DeviceType.WEARABLE,
      supportsDanmaku: deviceType !== DeviceType.WEARABLE
    };
  }
  
  private inferDeviceType(deviceInfo: DeviceBasicInfo): DeviceType {
    if (!deviceInfo.deviceType) {
      return DeviceType.PHONE;
    }
    
    switch (deviceInfo.deviceType) {
      case 'PHONE':
        return DeviceType.PHONE;
      case 'TABLET':
        return DeviceType.TABLET;
      case 'TV':
        return DeviceType.TV;
      case 'WEARABLE':
        return DeviceType.WEARABLE;
      default:
        return DeviceType.PHONE;
    }
  }
  
  private inferPerformanceLevel(deviceInfo: DeviceBasicInfo): PerformanceLevel {
    const width: number = deviceInfo.screenWidth || 1080;
    
    if (width >= 2560) {
      return PerformanceLevel.HIGH;
    } else if (width >= 1920) {
      return PerformanceLevel.MEDIUM;
    } else {
      return PerformanceLevel.LOW;
    }
  }
  
  checkCompatibility(sourceDevice: DeviceCapability, targetDevice: DeviceCapability): CompatibilityResult {
    const warnings: string[] = [];
    
    if (!targetDevice.supportsVideoPlayback) {
      return {
        isCompatible: false,
        reason: 'Target device does not support video playback'
      };
    }
    
    if (targetDevice.apiVersion < sourceDevice.apiVersion - 2) {
      warnings.push('API version difference may cause compatibility issues');
    }
    
    if (targetDevice.performanceLevel === PerformanceLevel.LOW && 
        sourceDevice.performanceLevel === PerformanceLevel.HIGH) {
      warnings.push('Target device has lower performance');
    }
    
    if (!targetDevice.supportsDanmaku && sourceDevice.supportsDanmaku) {
      warnings.push('Danmaku feature will be disabled on target device');
    }
    
    return {
      isCompatible: true,
      warnings
    };
  }
  
  setDiscoveryCallback(callback: (devices: DeviceCapability[]) => void): void {
    this.discoveryCallback = callback;
  }
  
  async discoverDevices(): Promise<DeviceCapability[]> {
    if (!this.deviceManager) {
      return [];
    }
    
    try {
      const devices: DeviceBasicInfo[] = this.deviceManager.getAvailableDeviceListSync();
      devices.forEach((device: DeviceBasicInfo) => {
        const capability = this.convertToDeviceCapability(device);
        this.registry.registerDevice(capability);
      });
      
      return this.registry.getAllDevices();
    } catch (error) {
      console.error('Discover devices failed:', error);
      return [];
    }
  }
  
  destroy(): void {
    if (this.deviceManager) {
      if (this.deviceManager) {
        distributedDeviceManager.releaseDeviceManager(this.deviceManager);
      }
      this.deviceManager = null;
    }
    this.discoveryCallback = null;
  }
}
