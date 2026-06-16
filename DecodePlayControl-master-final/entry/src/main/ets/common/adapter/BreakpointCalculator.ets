import { BreakpointType } from '../models/BreakpointType';
import { BreakpointConfig, DEFAULT_BREAKPOINT_CONFIG } from '../models/BreakpointConfig';
import { IBreakpointCalculator, BreakpointRange } from '../interfaces/IBreakpointCalculator';

export class BreakpointCalculator implements IBreakpointCalculator {
  private config: BreakpointConfig;
  
  constructor(config?: BreakpointConfig) {
    this.config = config || DEFAULT_BREAKPOINT_CONFIG;
  }
  
  calculateBreakpoint(width: number): BreakpointType {
    if (width < this.config.sm) {
      return BreakpointType.SM;
    } else if (width < this.config.md) {
      return BreakpointType.MD;
    } else if (width < this.config.lg) {
      return BreakpointType.LG;
    } else {
      return BreakpointType.XL;
    }
  }
  
  setBreakpointConfig(config: BreakpointConfig): void {
    this.config = config;
  }
  
  getBreakpointConfig(): BreakpointConfig {
    return this.config;
  }
  
  getBreakpointRange(breakpoint: BreakpointType): BreakpointRange {
    switch (breakpoint) {
      case BreakpointType.SM:
        return { min: 0, max: this.config.sm };
      case BreakpointType.MD:
        return { min: this.config.sm, max: this.config.md };
      case BreakpointType.LG:
        return { min: this.config.md, max: this.config.lg };
      case BreakpointType.XL:
        return { min: this.config.lg, max: Number.MAX_SAFE_INTEGER };
      default:
        return { min: 0, max: this.config.sm };
    }
  }
}
