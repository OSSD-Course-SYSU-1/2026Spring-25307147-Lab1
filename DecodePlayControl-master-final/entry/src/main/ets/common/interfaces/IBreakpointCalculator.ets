import { BreakpointType } from '../models/BreakpointType';
import { BreakpointConfig } from '../models/BreakpointConfig';

export interface BreakpointRange {
  readonly min: number;
  readonly max: number;
}

export interface IBreakpointCalculator {
  calculateBreakpoint(width: number): BreakpointType;
  
  setBreakpointConfig(config: BreakpointConfig): void;
  
  getBreakpointConfig(): BreakpointConfig;
  
  getBreakpointRange(breakpoint: BreakpointType): BreakpointRange;
}
