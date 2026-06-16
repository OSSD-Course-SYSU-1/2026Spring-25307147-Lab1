import { BreakpointType } from '../models/BreakpointType';
import { LayoutStrategy } from '../models/LayoutStrategy';

export interface IStrategyMatcher {
  registerStrategy(strategy: LayoutStrategy): void;
  
  unregisterStrategy(strategyName: string): void;
  
  matchStrategy(breakpoint: BreakpointType): LayoutStrategy | undefined;
  
  getAllStrategies(): LayoutStrategy[];
  
  clearStrategies(): void;
}
