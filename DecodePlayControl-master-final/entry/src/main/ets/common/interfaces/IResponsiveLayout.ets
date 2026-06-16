import { BreakpointType } from '../models/BreakpointType';
import { FoldStatus } from '../models/FoldStatus';
import { LayoutStrategy, ResponsiveStyle } from '../models/LayoutStrategy';

export type BreakpointChangeListener = (breakpoint: BreakpointType) => void;

export interface IResponsiveLayout {
  getCurrentBreakpoint(): BreakpointType;
  
  onBreakpointChange(listener: BreakpointChangeListener): void;
  
  offBreakpointChange(listener: BreakpointChangeListener): void;
  
  getResponsiveStyles(componentId: string): ResponsiveStyle | undefined;
  
  registerComponentStrategies(componentId: string, strategies: LayoutStrategy[]): void;
  
  unregisterComponentStrategies(componentId: string): void;
  
  isFoldableDevice(): boolean;
  
  getFoldStatus(): FoldStatus;
  
  destroy(): void;
}
