import { BreakpointType } from '../models/BreakpointType';
import { LayoutStrategy } from '../models/LayoutStrategy';
import { IStrategyMatcher } from '../interfaces/IStrategyMatcher';

export class StrategyMatcher implements IStrategyMatcher {
  private strategies: Map<string, LayoutStrategy> = new Map();
  
  registerStrategy(strategy: LayoutStrategy): void {
    this.strategies.set(strategy.name, strategy);
  }
  
  unregisterStrategy(strategyName: string): void {
    this.strategies.delete(strategyName);
  }
  
  matchStrategy(breakpoint: BreakpointType): LayoutStrategy | undefined {
    const applicableStrategies: LayoutStrategy[] = [];
    
    this.strategies.forEach((strategy) => {
      if (strategy.applicableBreakpoints.includes(breakpoint)) {
        applicableStrategies.push(strategy);
      }
    });
    
    if (applicableStrategies.length === 0) {
      return undefined;
    }
    
    applicableStrategies.sort((a, b) => b.priority - a.priority);
    
    return applicableStrategies[0];
  }
  
  getAllStrategies(): LayoutStrategy[] {
    return Array.from(this.strategies.values());
  }
  
  clearStrategies(): void {
    this.strategies.clear();
  }
}
