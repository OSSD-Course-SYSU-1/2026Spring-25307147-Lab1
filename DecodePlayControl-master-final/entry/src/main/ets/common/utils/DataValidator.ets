import { BreakpointConfig } from '../models/BreakpointConfig';
import { DeviceCapability } from '../models/DeviceCapability';
import { AppStateSnapshot } from '../models/AppStateSnapshot';

export class DataValidator {
  static validateBreakpointConfig(config: BreakpointConfig): boolean {
    if (!config) {
      return false;
    }
    return config.sm > 0 && config.md > config.sm && config.lg > config.md && config.xl >= config.lg;
  }

  static validateDeviceCapability(device: DeviceCapability): boolean {
    if (!device) {
      return false;
    }
    return !!(device.deviceId && device.deviceName && device.screenSize.width > 0 && device.screenSize.height > 0);
  }

  static validateSnapshot(snapshot: AppStateSnapshot): boolean {
    if (!snapshot) {
      return false;
    }
    if (!snapshot.metadata || !snapshot.appState || !snapshot.businessData) {
      return false;
    }
    if (!snapshot.metadata.version || !snapshot.metadata.sourceDeviceId) {
      return false;
    }
    return true;
  }

  static calculateChecksum(data: string): string {
    let checksum = 0;
    for (let i = 0; i < data.length; i++) {
      checksum = ((checksum << 5) - checksum) + data.charCodeAt(i);
      checksum = checksum & checksum;
    }
    return Math.abs(checksum).toString(16);
  }

  static validateJSON(jsonString: string): boolean {
    try {
      JSON.parse(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
}
