import { DeviceCapability } from '../common/models/DeviceCapability';
import { FlowState } from '../common/models/FlowState';

@Component
export struct DeviceSelectorPanel {
  @Prop devices: DeviceCapability[] = [];
  @Prop currentFlowState: FlowState = FlowState.IDLE;
  @Link selectedDeviceId: string;
  
  private onDeviceSelected?: (device: DeviceCapability) => void;
  private onFlowTriggered?: () => void;
  
  build() {
    Column() {
      Text('可用设备')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
      
      if (this.devices.length === 0) {
        Text('未发现可用设备')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20, bottom: 20 })
      } else {
        List() {
          ForEach(this.devices, (device: DeviceCapability) => {
            ListItem() {
              this.DeviceItem(device)
            }
          }, (device: DeviceCapability) => device.deviceId)
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ bottom: 16 })
      }
      
      this.FlowButton()
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
  
  @Builder
  DeviceItem(device: DeviceCapability) {
    Row() {
      Column() {
        Text(device.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        
        Text(`${device.deviceType} | ${device.screenSize.width}x${device.screenSize.height}`)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Radio({ value: device.deviceId, group: 'deviceGroup' })
        .checked(this.selectedDeviceId === device.deviceId)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedDeviceId = device.deviceId;
            if (this.onDeviceSelected) {
              this.onDeviceSelected(device);
            }
          }
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.selectedDeviceId === device.deviceId ? '#E3F2FD' : '#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
  }
  
  @Builder
  FlowButton() {
    Button(this.getFlowButtonText())
      .width('100%')
      .height(44)
      .enabled(this.canExecuteFlow())
      .onClick(() => {
        if (this.onFlowTriggered) {
          this.onFlowTriggered();
        }
      })
  }
  
  private getFlowButtonText(): string {
    switch (this.currentFlowState) {
      case FlowState.IDLE:
        return '开始流转';
      case FlowState.DISCOVERING:
        return '发现设备中...';
      case FlowState.PREPARING:
        return '准备流转...';
      case FlowState.TRANSFERRING:
        return '传输中...';
      case FlowState.RESTORING:
        return '恢复中...';
      case FlowState.COMPLETED:
        return '流转完成';
      case FlowState.FAILED:
        return '流转失败';
      default:
        return '开始流转';
    }
  }
  
  private canExecuteFlow(): boolean {
    return this.currentFlowState === FlowState.IDLE && 
           this.selectedDeviceId !== '' &&
           this.devices.length > 0;
  }
  
  setOnDeviceSelected(callback: (device: DeviceCapability) => void): void {
    this.onDeviceSelected = callback;
  }
  
  setOnFlowTriggered(callback: () => void): void {
    this.onFlowTriggered = callback;
  }
}
