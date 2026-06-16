import { DeviceType } from './DeviceType';
import { PerformanceLevel } from './PerformanceLevel';

export interface ScreenSize {
  readonly width: number;
  readonly height: number;
}

export interface DeviceCapability {
  readonly deviceId: string;
  readonly deviceName: string;
  readonly deviceType: DeviceType;
  readonly screenSize: ScreenSize;
  readonly apiVersion: number;
  readonly performanceLevel: PerformanceLevel;
  readonly supportsVideoPlayback: boolean;
  readonly supportsScreenMirroring: boolean;
  readonly supportsDanmaku: boolean;
}

export interface CompatibilityResult {
  readonly isCompatible: boolean;
  readonly reason?: string;
  readonly warnings?: string[];
}

export function createCompatibilityResult(
  isCompatible: boolean,
  reason?: string,
  warnings?: string[]
): CompatibilityResult {
  return {
    isCompatible,
    reason,
    warnings
  };
}
