import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FlowLogger';
const DOMAIN = 0x0000;

export enum LogLevel {
  DEBUG = 3,
  INFO = 4,
  WARN = 5,
  ERROR = 6
}

export class FlowLogger {
  private static instance: FlowLogger | null = null;
  private logLevel: LogLevel = LogLevel.INFO;
  private performanceMetrics: Map<string, number> = new Map();
  
  private constructor() {}
  
  static getInstance(): FlowLogger {
    if (!FlowLogger.instance) {
      FlowLogger.instance = new FlowLogger();
    }
    return FlowLogger.instance;
  }
  
  setLogLevel(level: LogLevel): void {
    this.logLevel = level;
  }
  
  debug(message: string, ...args: string[]): void {
    if (this.logLevel <= LogLevel.DEBUG) {
      hilog.debug(DOMAIN, TAG, message, ...args);
    }
  }
  
  info(message: string, ...args: string[]): void {
    if (this.logLevel <= LogLevel.INFO) {
      hilog.info(DOMAIN, TAG, message, ...args);
    }
  }
  
  warn(message: string, ...args: string[]): void {
    if (this.logLevel <= LogLevel.WARN) {
      hilog.warn(DOMAIN, TAG, message, ...args);
    }
  }
  
  error(message: string, ...args: string[]): void {
    if (this.logLevel <= LogLevel.ERROR) {
      hilog.error(DOMAIN, TAG, message, ...args);
    }
  }
  
  startPerformanceTrace(traceName: string): void {
    this.performanceMetrics.set(traceName, Date.now());
    this.debug(`Performance trace started: ${traceName}`);
  }
  
  endPerformanceTrace(traceName: string): number {
    const startTime = this.performanceMetrics.get(traceName);
    if (startTime === undefined) {
      this.warn(`Performance trace not found: ${traceName}`);
      return 0;
    }
    
    const duration = Date.now() - startTime;
    this.performanceMetrics.delete(traceName);
    
    this.info(`Performance trace ended: ${traceName}, duration: ${duration}ms`);
    
    return duration;
  }
  
  logBreakpointChange(oldBreakpoint: string, newBreakpoint: string): void {
    this.info(`Breakpoint changed: ${oldBreakpoint} -> ${newBreakpoint}`);
  }
  
  logDeviceDiscovery(deviceCount: number): void {
    this.info(`Device discovery completed, found ${deviceCount} devices`);
  }
  
  logFlowStateChange(oldState: string, newState: string): void {
    this.info(`Flow state changed: ${oldState} -> ${newState}`);
  }
  
  logSnapshotOperation(operation: string, success: boolean): void {
    if (success) {
      this.info(`Snapshot ${operation} succeeded`);
    } else {
      this.error(`Snapshot ${operation} failed`);
    }
  }
  
  logDataTransfer(deviceId: string, dataSize: number, success: boolean): void {
    if (success) {
      this.info(`Data transfer to ${deviceId} succeeded, size: ${dataSize} bytes`);
    } else {
      this.error(`Data transfer to ${deviceId} failed`);
    }
  }
}
