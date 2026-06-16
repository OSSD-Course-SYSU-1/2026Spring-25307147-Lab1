import { BreakpointType } from '../models/BreakpointType';
import { BreakpointConfig, DEFAULT_BREAKPOINT_CONFIG } from '../models/BreakpointConfig';
import { FoldStatus } from '../models/FoldStatus';
import { LayoutStrategy, ResponsiveStyle } from '../models/LayoutStrategy';
import { IResponsiveLayout, BreakpointChangeListener } from '../interfaces/IResponsiveLayout';
import { BreakpointCalculator } from './BreakpointCalculator';
import { StrategyMatcher } from './StrategyMatcher';
import { WindowSizeListener } from './WindowSizeListener';
import { FoldStatusMonitor } from './FoldStatusMonitor';
import { common } from '@kit.AbilityKit';

export class ResponsiveLayoutManager implements IResponsiveLayout {
  private breakpointCalculator: BreakpointCalculator;
  private strategyMatcher: StrategyMatcher;
  private windowSizeListener: WindowSizeListener;
  private foldStatusMonitor: FoldStatusMonitor;
  private currentBreakpoint: BreakpointType = BreakpointType.SM;
  private breakpointListeners: Set<BreakpointChangeListener> = new Set();
  private componentStrategies: Map<string, LayoutStrategy[]> = new Map();
  private isInitialized: boolean = false;
  
  constructor(config?: BreakpointConfig) {
    this.breakpointCalculator = new BreakpointCalculator(config || DEFAULT_BREAKPOINT_CONFIG);
    this.strategyMatcher = new StrategyMatcher();
    this.windowSizeListener = new WindowSizeListener();
    this.foldStatusMonitor = new FoldStatusMonitor();
  }
  
  async init(context: common.UIAbilityContext): Promise<void> {
    await this.windowSizeListener.init(context);
    await this.foldStatusMonitor.init();
    
    const currentSize = this.windowSizeListener.getCurrentSize();
    if (currentSize) {
      this.currentBreakpoint = this.breakpointCalculator.calculateBreakpoint(currentSize.width);
    }
    
    this.windowSizeListener.registerListener((width: number, height: number) => {
      const newBreakpoint = this.breakpointCalculator.calculateBreakpoint(width);
      if (newBreakpoint !== this.currentBreakpoint) {
        this.currentBreakpoint = newBreakpoint;
        this.notifyBreakpointChange(newBreakpoint);
      }
    });
    
    this.isInitialized = true;
  }
  
  getCurrentBreakpoint(): BreakpointType {
    return this.currentBreakpoint;
  }
  
  onBreakpointChange(listener: BreakpointChangeListener): void {
    this.breakpointListeners.add(listener);
  }
  
  offBreakpointChange(listener: BreakpointChangeListener): void {
    this.breakpointListeners.delete(listener);
  }
  
  private notifyBreakpointChange(breakpoint: BreakpointType): void {
    this.breakpointListeners.forEach((listener) => {
      try {
        listener(breakpoint);
      } catch (error) {
        console.error('BreakpointChangeListener error:', error);
      }
    });
  }
  
  getResponsiveStyles(componentId: string): ResponsiveStyle | undefined {
    const strategies = this.componentStrategies.get(componentId);
    if (!strategies || strategies.length === 0) {
      return undefined;
    }
    
    for (const strategy of strategies) {
      if (strategy.applicableBreakpoints.includes(this.currentBreakpoint)) {
        return strategy.style;
      }
    }
    
    return undefined;
  }
  
  registerComponentStrategies(componentId: string, strategies: LayoutStrategy[]): void {
    this.componentStrategies.set(componentId, strategies);
  }
  
  unregisterComponentStrategies(componentId: string): void {
    this.componentStrategies.delete(componentId);
  }
  
  isFoldableDevice(): boolean {
    try {
      const currentStatus = this.foldStatusMonitor.getCurrentFoldStatus();
      return currentStatus !== FoldStatus.UNFOLDED;
    } catch (error) {
      return false;
    }
  }
  
  getFoldStatus(): FoldStatus {
    return this.foldStatusMonitor.getCurrentFoldStatus();
  }
  
  registerGlobalStrategy(strategy: LayoutStrategy): void {
    this.strategyMatcher.registerStrategy(strategy);
  }
  
  unregisterGlobalStrategy(strategyName: string): void {
    this.strategyMatcher.unregisterStrategy(strategyName);
  }
  
  matchGlobalStrategy(breakpoint: BreakpointType): LayoutStrategy | undefined {
    return this.strategyMatcher.matchStrategy(breakpoint);
  }
  
  destroy(): void {
    this.windowSizeListener.destroy();
    this.foldStatusMonitor.destroy();
    this.breakpointListeners.clear();
    this.componentStrategies.clear();
    this.strategyMatcher.clearStrategies();
    this.isInitialized = false;
  }
}
