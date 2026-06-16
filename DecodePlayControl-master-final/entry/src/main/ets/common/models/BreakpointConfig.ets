import { BreakpointType } from './BreakpointType';

export interface BreakpointConfig {
  readonly sm: number;
  readonly md: number;
  readonly lg: number;
  readonly xl: number;
}

export const DEFAULT_BREAKPOINT_CONFIG: BreakpointConfig = {
  sm: 600,
  md: 840,
  lg: 1024,
  xl: 1024
};

export function createBreakpointConfig(
  sm: number = 600,
  md: number = 840,
  lg: number = 1024,
  xl: number = 1024
): BreakpointConfig {
  if (sm >= md || md >= lg || lg > xl) {
    throw new Error('Invalid breakpoint config: must satisfy sm < md < lg <= xl');
  }
  return {
    sm,
    md,
    lg,
    xl
  };
}
