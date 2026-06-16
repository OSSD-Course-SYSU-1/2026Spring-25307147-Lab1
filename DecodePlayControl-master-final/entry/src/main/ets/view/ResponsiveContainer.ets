import { BreakpointType } from '../common/models/BreakpointType';

@Component
export struct ResponsiveContainer {
  @Prop currentBreakpoint: BreakpointType = BreakpointType.SM;
  @BuilderParam content: () => void;
  
  build() {
    Column() {
      this.content();
    }
    .width(this.getContainerWidth())
    .height(this.getContainerHeight())
    .padding(this.getContainerPadding())
  }
  
  private getContainerWidth(): string | number {
    switch (this.currentBreakpoint) {
      case BreakpointType.SM:
        return '100%';
      case BreakpointType.MD:
        return '90%';
      case BreakpointType.LG:
        return '80%';
      case BreakpointType.XL:
        return '70%';
      default:
        return '100%';
    }
  }
  
  private getContainerHeight(): string {
    return '100%';
  }
  
  private getContainerPadding(): number {
    switch (this.currentBreakpoint) {
      case BreakpointType.SM:
        return 8;
      case BreakpointType.MD:
        return 16;
      case BreakpointType.LG:
        return 24;
      case BreakpointType.XL:
        return 32;
      default:
        return 8;
    }
  }
}
