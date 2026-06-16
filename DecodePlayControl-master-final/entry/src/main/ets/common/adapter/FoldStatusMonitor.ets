import { display } from '@kit.ArkUI';
import { FoldStatus } from '../models/FoldStatus';

export type FoldStatusChangeListener = (status: FoldStatus) => void;

export class FoldStatusMonitor {
  private displayInstance: display.Display | null = null;
  private currentStatus: FoldStatus = FoldStatus.UNFOLDED;
  private listeners: Set<FoldStatusChangeListener> = new Set();
  private isInitialized: boolean = false;
  
  async init(): Promise<void> {
    try {
      const displays = await display.getAllDisplays();
      if (displays && displays.length > 0) {
        this.displayInstance = displays[0];
        this.updateFoldStatus(this.displayInstance);
        
        display.on('change', async () => {
          const currentDisplays = await display.getAllDisplays();
          if (currentDisplays && currentDisplays.length > 0) {
            this.updateFoldStatus(currentDisplays[0]);
          }
        });
      }
      
      this.isInitialized = true;
    } catch (error) {
      console.error('FoldStatusMonitor init failed:', error);
      throw new Error('FoldStatusMonitor init failed');
    }
  }
  
  private updateFoldStatus(displayInfo: display.Display): void {
    const width = displayInfo.width;
    const height = displayInfo.height;
    const ratio = Math.max(width, height) / Math.min(width, height);
    
    let newStatus: FoldStatus;
    if (ratio > 2.0) {
      newStatus = FoldStatus.HALF_FOLDED;
    } else if (ratio > 1.5) {
      newStatus = FoldStatus.UNFOLDED;
    } else {
      newStatus = FoldStatus.FOLDED;
    }
    
    if (newStatus !== this.currentStatus) {
      this.currentStatus = newStatus;
      this.notifyListeners(newStatus);
    }
  }
  
  getCurrentFoldStatus(): FoldStatus {
    return this.currentStatus;
  }
  
  registerListener(listener: FoldStatusChangeListener): void {
    this.listeners.add(listener);
  }
  
  unregisterListener(listener: FoldStatusChangeListener): void {
    this.listeners.delete(listener);
  }
  
  private notifyListeners(status: FoldStatus): void {
    this.listeners.forEach((listener) => {
      try {
        listener(status);
      } catch (error) {
        console.error('FoldStatusChangeListener error:', error);
      }
    });
  }
  
  destroy(): void {
    display.off('change');
    this.listeners.clear();
    this.displayInstance = null;
    this.isInitialized = false;
  }
}
