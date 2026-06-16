import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FlowError';
const DOMAIN = 0x0000;

export enum ErrorCode {
  BREAKPOINT_CALCULATION_ERROR = 1001,
  DEVICE_DISCOVERY_ERROR = 2001,
  DEVICE_COMPATIBILITY_ERROR = 2002,
  FLOW_EXECUTION_ERROR = 2003,
  SNAPSHOT_GENERATION_ERROR = 3001,
  SNAPSHOT_RESTORATION_ERROR = 3002,
  DATA_TRANSFER_ERROR = 4001,
  TIMEOUT_ERROR = 5001
}

export class FlowError extends Error {
  code: ErrorCode;
  
  constructor(code: ErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = 'FlowError';
  }
}

export class ErrorHandler {
  static handle(error: Error): void {
    if (error instanceof FlowError) {
      this.handleFlowError(error);
    } else {
      this.handleGenericError(error);
    }
  }
  
  private static handleFlowError(error: FlowError): void {
    hilog.error(DOMAIN, TAG, `FlowError [${error.code}]: ${error.message}`);
    
    switch (error.code) {
      case ErrorCode.BREAKPOINT_CALCULATION_ERROR:
        this.handleBreakpointError(error);
        break;
      case ErrorCode.DEVICE_DISCOVERY_ERROR:
        this.handleDeviceDiscoveryError(error);
        break;
      case ErrorCode.FLOW_EXECUTION_ERROR:
        this.handleFlowExecutionError(error);
        break;
      case ErrorCode.SNAPSHOT_GENERATION_ERROR:
      case ErrorCode.SNAPSHOT_RESTORATION_ERROR:
        this.handleSnapshotError(error);
        break;
      case ErrorCode.DATA_TRANSFER_ERROR:
        this.handleTransferError(error);
        break;
      default:
        hilog.error(DOMAIN, TAG, 'Unknown error type');
    }
  }
  
  private static handleGenericError(error: Error): void {
    hilog.error(DOMAIN, TAG, `Generic error: ${error.message}`);
  }
  
  private static handleBreakpointError(error: FlowError): void {
    hilog.warn(DOMAIN, TAG, 'Using default breakpoint configuration');
  }
  
  private static handleDeviceDiscoveryError(error: FlowError): void {
    hilog.warn(DOMAIN, TAG, 'Device discovery failed, please check network connection');
  }
  
  private static handleFlowExecutionError(error: FlowError): void {
    hilog.warn(DOMAIN, TAG, 'Flow execution failed, please try again');
  }
  
  private static handleSnapshotError(error: FlowError): void {
    hilog.warn(DOMAIN, TAG, 'Snapshot operation failed');
  }
  
  private static handleTransferError(error: FlowError): void {
    hilog.warn(DOMAIN, TAG, 'Data transfer failed, please check target device status');
  }
}

export class FallbackStrategy {
  static getDefaultBreakpoint(): number {
    return 600;
  }
  
  static getEmptyDeviceList(): never[] {
    return [];
  }
  
  static getEmptySnapshot(): null {
    return null;
  }
}
