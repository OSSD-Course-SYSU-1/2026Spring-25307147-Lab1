import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

export type SizeChangeListener = (width: number, height: number) => void;

export class WindowSizeListener {
  private windowInstance: window.Window | null = null;
  private listeners: Set<SizeChangeListener> = new Set();
  private isInitialized: boolean = false;
  
  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.windowInstance = await window.getLastWindow(context);
      
      this.windowInstance.on('windowSizeChange', (size: window.Size) => {
        this.notifyListeners(size.width, size.height);
      });
      
      this.isInitialized = true;
    } catch (error) {
      console.error('WindowSizeListener init failed:', error);
      throw new Error('WindowSizeListener init failed');
    }
  }
  
  registerListener(listener: SizeChangeListener): void {
    this.listeners.add(listener);
  }
  
  unregisterListener(listener: SizeChangeListener): void {
    this.listeners.delete(listener);
  }
  
  private notifyListeners(width: number, height: number): void {
    this.listeners.forEach((listener) => {
      try {
        listener(width, height);
      } catch (error) {
        console.error('SizeChangeListener error:', error);
      }
    });
  }
  
  getCurrentSize(): window.Size | null {
    if (!this.windowInstance) {
      return null;
    }
    return {
      width: this.windowInstance.getWindowProperties().windowRect.width,
      height: this.windowInstance.getWindowProperties().windowRect.height
    };
  }
  
  destroy(): void {
    if (this.windowInstance) {
      this.windowInstance.off('windowSizeChange');
      this.windowInstance = null;
    }
    this.listeners.clear();
    this.isInitialized = false;
  }
}
