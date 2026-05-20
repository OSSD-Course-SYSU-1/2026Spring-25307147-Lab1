# **1. 实现模型**

## **1.1 上下文视图**

视频播放控制增强组件位于鸿蒙应用ArkTS层，通过XComponent与Native层（libplayer.so）交互，向上为用户提供视频播放增强功能，向下调用系统服务和本地存储。

```plantuml
@startuml
!define RECTANGLE class

rectangle "鸿蒙视频播放应用" {
    rectangle "视频播放控制增强组件" as Component {
        rectangle "画质调节模块" as QualityModule
        rectangle "音量控制模块" as VolumeModule
        rectangle "进度记忆模块" as ProgressModule
        rectangle "弹幕功能模块" as DanmakuModule
        rectangle "播放结束处理模块" as EndHandlerModule
    }
    rectangle "UI视图层" as UIView
    rectangle "视图模型层" as ViewModel
}

actor "视频观看用户" as User
rectangle "Native播放器层\n(libplayer.so)" as NativePlayer
rectangle "系统音量管理器" as VolumeManager
rectangle "本地存储服务\n(Preferences)" as StorageService
rectangle "弹幕数据服务" as DanmakuService

User --> UIView : 用户交互
UIView --> ViewModel : 状态绑定
ViewModel --> Component : 功能调用
Component --> NativePlayer : 播放控制指令
Component --> VolumeManager : 音量设置
Component --> StorageService : 进度/配置存储
Component --> DanmakuService : 弹幕数据交互
NativePlayer --> ViewModel : 播放状态回调

@enduml
```

## **1.2 服务/组件总体架构**

### **1.2.1 分层架构**

本系统采用分层架构设计，从上到下分为三层：

| 层次 | 名称 | 职责 | 关键组件 |
|------|------|------|----------|
| 表现层 | UI视图层 | 用户界面渲染与交互 | VideoPlayView、DanmakuView、ControlPanel |
| 业务层 | 视图模型层 | 业务逻辑处理与状态管理 | VideoPlayViewModel、各功能管理器 |
| 数据层 | 数据服务层 | 数据持久化与外部服务交互 | StorageService、NativePlayerBridge |

### **1.2.2 模块划分**

```plantuml
@startuml
package "视频播放控制增强组件" {
    package "核心播放控制" {
        [PlayerController] as PC
        [PlayerStateManager] as PSM
    }
    
    package "画质调节" {
        [QualitySelector] as QS
        [QualityManager] as QM
    }
    
    package "音量控制" {
        [VolumeSlider] as VS
        [VolumeManager] as VM
    }
    
    package "进度记忆" {
        [ProgressTracker] as PT
        [ProgressStorage] as PS
    }
    
    package "弹幕功能" {
        [DanmakuRenderer] as DR
        [DanmakuSender] as DS
        [DanmakuTrackManager] as DTM
    }
    
    package "播放结束处理" {
        [EndStateHandler] as ESH
        [AutoPlayManager] as APM
    }
}

PC --> PSM
QS --> QM
VS --> VM
PT --> PS
DR --> DTM
DS --> DTM
ESH --> APM

@enduml
```

## **1.3 实现设计文档**

### **1.3.1 画质调节功能实现**

#### **组件设计**

**QualitySelector组件**：画质选择器UI组件
- 位置：`entry/src/main/ets/view/QualitySelector.ets`
- 职责：展示画质选项列表，处理用户选择事件
- 状态：`@Prop qualityList: QualityItem[]`、`@Prop currentQuality: string`、`@Link isVisible: boolean`

**QualityManager类**：画质管理器
- 位置：`entry/src/main/ets/viewmodel/QualityManager.ets`
- 职责：管理画质列表、执行画质切换、处理切换结果
- 关键方法：
  - `loadQualityList(videoId: string): Promise<QualityItem[]>`
  - `switchQuality(targetQuality: string): Promise<void>`
  - `getCurrentQuality(): string`

#### **实现流程**

1. 视频加载时调用`loadQualityList`获取可用画质列表
2. 若列表长度 > 1，显示画质选择按钮；否则隐藏
3. 用户选择画质后，调用Native层`player.setQuality()`接口
4. 等待2秒超时，若未返回则取消切换并提示失败
5. 切换成功后更新当前画质标识

#### **关键技术点**

- 使用`@Watch`装饰器监听画质列表变化，动态更新UI
- 切换超时控制：使用`setTimeout` + `Promise.race`实现
- Native交互：通过已有的`player`模块扩展`setQuality`方法

### **1.3.2 音量控制功能实现**

#### **组件设计**

**VolumeControl组件**：音量控制UI组件
- 位置：`entry/src/main/ets/view/VolumeControl.ets`
- 职责：音量滑块、音量图标、静音切换
- 状态：`@Link volume: number`、`@Link isMuted: boolean`

**VolumeManager类**：音量管理器
- 位置：`entry/src/main/ets/viewmodel/VolumeManager.ets`
- 职责：操作系统音量、持久化音量设置、处理音量键事件
- 关键方法：
  - `setVolume(value: number): Promise<void>`
  - `getVolume(): Promise<number>`
  - `toggleMute(): void`
  - `saveVolume(value: number): void`

#### **实现流程**

1. 组件初始化时从Preferences加载上次音量设置
2. 用户拖动滑块时，实时调用`AVVolumePanel.setVolume()`
3. 音量变化时更新图标状态（静音/非静音）
4. 音量调节后异步保存到Preferences
5. 监听系统音量键事件，同步更新滑块位置

#### **关键技术点**

- 使用鸿蒙`@ohos.multimedia.audio`的`AudioVolumeManager`接口
- Preferences持久化：使用`@ohos.data.preferences`存储音量值
- 音量键监听：通过`@ohos.multimedia.audio`的音量变化事件
- 响应式更新：使用`@State`驱动UI实时刷新

### **1.3.3 进度记忆与回溯功能实现**

#### **组件设计**

**ProgressRecallButton组件**：进度回溯按钮
- 位置：`entry/src/main/ets/view/ProgressRecallButton.ets`
- 职责：显示"上次播放至XX:XX"提示，处理回溯点击
- 状态：`@Prop lastPosition: number`、`@Link isVisible: boolean`

**ProgressTracker类**：进度追踪器
- 位置：`entry/src/main/ets/viewmodel/ProgressTracker.ets`
- 职责：定时保存进度、加载历史进度、管理多集进度
- 关键方法：
  - `startTracking(videoId: string, episodeIndex: number): void`
  - `saveProgress(): void`
  - `loadProgress(videoId: string, episodeIndex: number): Promise<number | null>`
  - `stopTracking(): void`

**ProgressStorage类**：进度存储服务
- 位置：`entry/src/main/ets/service/ProgressStorage.ets`
- 职责：进度数据持久化、加密存储
- 关键方法：
  - `save(data: ProgressData): Promise<void>`
  - `load(videoId: string, episodeIndex: number): Promise<ProgressData | null>`

#### **实现流程**

1. 视频切换时调用`loadProgress`检查历史进度
2. 若存在历史进度，显示回溯按钮（左下角）
3. 用户点击回溯按钮，调用`player.seek()`跳转
4. 播放过程中启动定时器，每10秒调用`saveProgress`
5. 应用退出或视频切换时，立即保存当前进度

#### **关键技术点**

- 定时保存：使用`setInterval`实现10秒自动保存
- 数据加密：使用`@ohos.security.cryptoFramework`加密进度数据
- 多集管理：使用复合键`videoId_episodeIndex`区分不同集数
- 生命周期管理：在`aboutToDisappear`中保存进度

### **1.3.4 弹幕功能实现**

#### **组件设计**

**DanmakuView组件**：弹幕渲染视图
- 位置：`entry/src/main/ets/view/DanmakuView.ets`
- 职责：弹幕渲染、轨道管理、滚动动画
- 状态：`@Prop danmakuList: DanmakuItem[]`、`@Link isVisible: boolean`

**DanmakuInput组件**：弹幕输入组件
- 位置：`entry/src/main/ets/view/DanmakuInput.ets`
- 职责：弹幕输入框、颜色选择器、发送按钮
- 状态：`@State inputText: string`、`@State selectedColor: string`

**DanmakuManager类**：弹幕管理器
- 位置：`entry/src/main/ets/viewmodel/DanmakuManager.ets`
- 职责：弹幕数据管理、发送频率限制、轨道分配
- 关键方法：
  - `loadDanmaku(videoId: string): Promise<DanmakuItem[]>`
  - `sendDanmaku(content: string, color: string): Promise<void>`
  - `allocateTrack(danmaku: DanmakuItem): number`
  - `toggleVisibility(): void`

**DanmakuTrackManager类**：弹幕轨道管理器
- 位置：`entry/src/main/ets/viewmodel/DanmakuTrackManager.ets`
- 职责：计算弹幕轨道位置、避免重叠
- 关键方法：
  - `findAvailableTrack(time: number): number`
  - `releaseTrack(trackId: number): void`

#### **实现流程**

1. 视频加载时从弹幕服务获取弹幕数据
2. 根据弹幕时间戳排序，建立时间索引
3. 播放过程中，根据当前时间查找并渲染弹幕
4. 使用Canvas绘制弹幕，应用滚动动画
5. 用户发送弹幕时校验长度和频率，通过后发送并立即显示

#### **关键技术点**

- 高性能渲染：使用Canvas组件绘制弹幕，避免频繁DOM操作
- 轨道分配算法：贪心算法分配轨道，优先选择最早释放的轨道
- 帧率控制：使用`requestAnimationFrame`保证30fps渲染
- 频率限制：记录上次发送时间戳，计算间隔判断
- 敏感词过滤：可选集成敏感词过滤服务

### **1.3.5 播放结束处理功能实现**

#### **组件设计**

**PlaybackEndOverlay组件**：播放结束覆盖层
- 位置：`entry/src/main/ets/view/PlaybackEndOverlay.ets`
- 职责：显示重新播放按钮、倒计时提示
- 状态：`@Prop countdown: number`、`@Prop isLastEpisode: boolean`、`@Link isVisible: boolean`

**EndStateHandler类**：播放结束状态处理器
- 位置：`entry/src/main/ets/viewmodel/EndStateHandler.ets`
- 职责：监听播放结束事件、管理倒计时、触发自动播放
- 关键方法：
  - `onPlaybackEnd(): void`
  - `startCountdown(): void`
  - `cancelCountdown(): void`
  - `playNext(): Promise<void>`

**AutoPlayManager类**：自动播放管理器
- 位置：`entry/src/main/ets/viewmodel/AutoPlayManager.ets`
- 职责：判断是否有下一集、加载下一集视频
- 关键方法：
  - `hasNextEpisode(): boolean`
  - `loadNextEpisode(): Promise<void>`

#### **实现流程**

1. Native播放器检测到播放结束，发送`onCompletion`事件
2. `EndStateHandler`接收事件，判断是否为最后一集
3. 若非最后一集，显示重新播放按钮并启动10秒倒计时
4. 倒计时期间用户可点击重新播放，取消倒计时
5. 倒计时结束，自动调用`loadNextEpisode`播放下一集
6. 若为最后一集，仅显示重新播放按钮

#### **关键技术点**

- 事件监听：扩展Native播放器回调，增加`onCompletion`事件
- 倒计时精度：使用`setInterval`配合时间戳校准，保证误差<100ms
- 状态互斥：使用状态机管理，避免重复触发结束处理
- 防抖处理：忽略短时间内的重复结束事件

# **2. 接口设计**

## **2.1 总体设计**

### **2.1.1 接口分层原则**

- **UI组件接口**：面向视图层，提供状态绑定和事件回调
- **ViewModel接口**：面向业务层，提供业务方法调用
- **Service接口**：面向数据层，提供数据读写能力
- **Native接口**：面向底层能力，通过libplayer.so提供

### **2.1.2 异步处理策略**

- 所有耗时操作采用`Promise`异步模式
- UI更新通过`@State`、`@Link`驱动响应式刷新
- 错误通过`try-catch`捕获并记录日志，不影响主流程

## **2.2 接口清单**

### **2.2.1 画质调节接口**

```typescript
// QualityManager.ets
interface QualityItem {
  id: string;           // 画质唯一标识
  name: string;         // 显示名称（如"高清"）
  resolution: number;   // 分辨率
  bitrate: number;      // 码率(kbps)
}

interface IQualityManager {
  // 加载画质列表
  loadQualityList(videoId: string): Promise<QualityItem[]>;
  
  // 切换画质
  switchQuality(targetQualityId: string): Promise<void>;
  
  // 获取当前画质
  getCurrentQuality(): QualityItem | null;
  
  // 检查是否支持画质切换
  isQualitySwitchSupported(): boolean;
}
```

### **2.2.2 音量控制接口**

```typescript
// VolumeManager.ets
interface IVolumeManager {
  // 设置音量（0-100）
  setVolume(value: number): Promise<void>;
  
  // 获取当前音量
  getVolume(): Promise<number>;
  
  // 切换静音状态
  toggleMute(): Promise<void>;
  
  // 获取静音状态
  isMuted(): boolean;
  
  // 增加音量（步进值）
  increaseVolume(step?: number): Promise<void>;
  
  // 减少音量（步进值）
  decreaseVolume(step?: number): Promise<void>;
}
```

### **2.2.3 进度记忆接口**

```typescript
// ProgressTracker.ets
interface ProgressData {
  videoId: string;           // 视频唯一标识
  episodeIndex: number;      // 集数索引
  position: number;          // 播放位置（秒）
  duration: number;          // 视频总时长（秒）
  timestamp: number;         // 保存时间戳
}

interface IProgressTracker {
  // 开始追踪进度
  startTracking(videoId: string, episodeIndex: number): void;
  
  // 停止追踪
  stopTracking(): void;
  
  // 保存进度
  saveProgress(): Promise<void>;
  
  // 加载历史进度
  loadProgress(videoId: string, episodeIndex: number): Promise<number | null>;
  
  // 清除进度
  clearProgress(videoId: string, episodeIndex: number): Promise<void>;
}
```

### **2.2.4 弹幕功能接口**

```typescript
// DanmakuManager.ets
interface DanmakuItem {
  id: string;              // 弹幕唯一标识
  content: string;         // 弹幕内容
  time: number;            // 出现时间（秒）
  color: string;           // 颜色（#RRGGBB）
  track: number;           // 轨道索引
  speed: number;           // 滚动速度（像素/秒）
  sender?: string;         // 发送者标识
}

interface IDanmakuManager {
  // 加载弹幕数据
  loadDanmaku(videoId: string): Promise<DanmakuItem[]>;
  
  // 发送弹幕
  sendDanmaku(content: string, color: string, time: number): Promise<DanmakuItem>;
  
  // 切换显示状态
  toggleVisibility(): void;
  
  // 获取显示状态
  isVisible(): boolean;
  
  // 设置弹幕速度
  setSpeed(speed: number): void;
}

// DanmakuTrackManager.ets
interface IDanmakuTrackManager {
  // 分配轨道
  allocateTrack(danmaku: DanmakuItem): number;
  
  // 释放轨道
  releaseTrack(trackId: number): void;
  
  // 获取轨道位置
  getTrackPosition(trackId: number): number;
}
```

### **2.2.5 播放结束处理接口**

```typescript
// EndStateHandler.ets
interface IEndStateHandler {
  // 处理播放结束
  onPlaybackEnd(): void;
  
  // 开始倒计时
  startCountdown(seconds: number): void;
  
  // 取消倒计时
  cancelCountdown(): void;
  
  // 重新播放当前视频
  replayCurrent(): Promise<void>;
  
  // 播放下一集
  playNext(): Promise<void>;
}

// AutoPlayManager.ets
interface IAutoPlayManager {
  // 检查是否有下一集
  hasNextEpisode(): boolean;
  
  // 获取下一集索引
  getNextEpisodeIndex(): number;
  
  // 加载并播放下一集
  loadAndPlayNext(): Promise<void>;
  
  // 设置自动播放开关
  setAutoPlayEnabled(enabled: boolean): void;
}
```

### **2.2.6 Native层扩展接口**

```typescript
// libplayer.so扩展接口（需Native层实现）
interface INativePlayerExtension {
  // 设置画质
  setQuality(playerHandle: bigint, qualityId: string): Promise<number>;
  
  // 获取支持的画质列表
  getSupportedQualities(playerHandle: bigint): Promise<QualityItem[]>;
  
  // 注册播放结束回调
  registerCompletionCallback(callback: () => void): void;
}
```

# **3. 数据模型**

## **3.1 设计目标**

- **类型安全**：使用TypeScript强类型定义所有数据结构
- **数据校验**：在模型层面提供数据校验方法
- **持久化友好**：支持序列化/反序列化，便于存储
- **扩展性**：预留扩展字段，支持功能迭代

## **3.2 模型实现**

### **3.2.1 画质数据模型**

```typescript
// model/QualityModel.ets
export class QualityItem {
  id: string = '';
  name: string = '';
  resolution: number = 480;
  bitrate: number = 500;
  
  constructor(id: string, name: string, resolution: number, bitrate: number) {
    this.id = id;
    this.name = name;
    this.resolution = resolution;
    this.bitrate = bitrate;
  }
  
  // 校验方法
  isValid(): boolean {
    return this.id.length > 0 && 
           this.name.length > 0 &&
           this.resolution >= 480 && 
           this.resolution <= 4096 &&
           this.bitrate >= 500 && 
           this.bitrate <= 20000;
  }
  
  // 序列化
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      name: this.name,
      resolution: this.resolution,
      bitrate: this.bitrate
    });
  }
  
  // 反序列化
  static fromJSON(json: string): QualityItem {
    const obj = JSON.parse(json);
    return new QualityItem(obj.id, obj.name, obj.resolution, obj.bitrate);
  }
}

export class QualityConfig {
  qualityList: QualityItem[] = [];
  currentQualityIndex: number = 0;
  
  getCurrentQuality(): QualityItem | null {
    return this.qualityList[this.currentQualityIndex] || null;
  }
  
  setCurrentQuality(index: number): boolean {
    if (index >= 0 && index < this.qualityList.length) {
      this.currentQualityIndex = index;
      return true;
    }
    return false;
  }
}
```

### **3.2.2 音量数据模型**

```typescript
// model/VolumeModel.ets
export class VolumeConfig {
  private static readonly MIN_VOLUME = 0;
  private static readonly MAX_VOLUME = 100;
  private static readonly DEFAULT_STEP = 5;
  
  value: number = 50;
  step: number = VolumeConfig.DEFAULT_STEP;
  isMuted: boolean = false;
  
  // 校验并约束音量值
  clamp(volume: number): number {
    return Math.max(VolumeConfig.MIN_VOLUME, 
                    Math.min(VolumeConfig.MAX_VOLUME, volume));
  }
  
  // 设置音量
  setVolume(volume: number): void {
    this.value = this.clamp(volume);
    this.isMuted = this.value === 0;
  }
  
  // 增加音量
  increase(step?: number): void {
    const actualStep = step || this.step;
    this.setVolume(this.value + actualStep);
  }
  
  // 减少音量
  decrease(step?: number): void {
    const actualStep = step || this.step;
    this.setVolume(this.value - actualStep);
  }
  
  // 切换静音
  toggleMute(): void {
    this.isMuted = !this.isMuted;
  }
  
  // 序列化（用于持久化）
  toJSON(): string {
    return JSON.stringify({
      value: this.value,
      step: this.step,
      isMuted: this.isMuted
    });
  }
  
  // 反序列化
  static fromJSON(json: string): VolumeConfig {
    const obj = JSON.parse(json);
    const config = new VolumeConfig();
    config.value = config.clamp(obj.value);
    config.step = obj.step || VolumeConfig.DEFAULT_STEP;
    config.isMuted = obj.isMuted || false;
    return config;
  }
}
```

### **3.2.3 播放进度数据模型**

```typescript
// model/ProgressModel.ets
export class ProgressRecord {
  videoId: string = '';
  episodeIndex: number = 0;
  position: number = 0;
  duration: number = 0;
  timestamp: number = Date.now();
  
  constructor(videoId: string, episodeIndex: number, position: number, duration: number) {
    this.videoId = videoId;
    this.episodeIndex = episodeIndex;
    this.position = position;
    this.duration = duration;
    this.timestamp = Date.now();
  }
  
  // 生成存储键
  getStorageKey(): string {
    return `${this.videoId}_${this.episodeIndex}`;
  }
  
  // 校验
  isValid(): boolean {
    return this.videoId.length > 0 &&
           this.episodeIndex >= 0 &&
           this.position >= 0 &&
           this.position <= this.duration &&
           this.duration > 0;
  }
  
  // 计算进度百分比
  getProgressPercent(): number {
    if (this.duration <= 0) return 0;
    return (this.position / this.duration) * 100;
  }
  
  // 序列化
  toJSON(): string {
    return JSON.stringify({
      videoId: this.videoId,
      episodeIndex: this.episodeIndex,
      position: this.position,
      duration: this.duration,
      timestamp: this.timestamp
    });
  }
  
  // 反序列化
  static fromJSON(json: string): ProgressRecord {
    const obj = JSON.parse(json);
    return new ProgressRecord(
      obj.videoId,
      obj.episodeIndex,
      obj.position,
      obj.duration
    );
  }
}

export class ProgressStorage {
  private static readonly MAX_RECORDS = 100;  // 最大记录数
  private static readonly EXPIRE_DAYS = 30;   // 过期天数
  
  records: Map<string, ProgressRecord> = new Map();
  
  // 添加记录
  addRecord(record: ProgressRecord): void {
    this.records.set(record.getStorageKey(), record);
    this.cleanExpired();
  }
  
  // 获取记录
  getRecord(videoId: string, episodeIndex: number): ProgressRecord | null {
    const key = `${videoId}_${episodeIndex}`;
    return this.records.get(key) || null;
  }
  
  // 清理过期记录
  cleanExpired(): void {
    const now = Date.now();
    const expireTime = VolumeConfig.EXPIRE_DAYS * 24 * 60 * 60 * 1000;
    
    for (const [key, record] of this.records) {
      if (now - record.timestamp > expireTime) {
        this.records.delete(key);
      }
    }
    
    // 若超过最大记录数，删除最旧的
    if (this.records.size > ProgressStorage.MAX_RECORDS) {
      const sortedRecords = Array.from(this.records.values())
        .sort((a, b) => a.timestamp - b.timestamp);
      
      const deleteCount = this.records.size - ProgressStorage.MAX_RECORDS;
      for (let i = 0; i < deleteCount; i++) {
        this.records.delete(sortedRecords[i].getStorageKey());
      }
    }
  }
}
```

### **3.2.4 弹幕数据模型**

```typescript
// model/DanmakuModel.ets
export class DanmakuItem {
  private static readonly MAX_CONTENT_LENGTH = 100;
  private static readonly MIN_SPEED = 50;
  private static readonly MAX_SPEED = 300;
  private static readonly DEFAULT_SPEED = 100;
  
  id: string = '';
  content: string = '';
  time: number = 0;
  color: string = '#FFFFFF';
  track: number = -1;
  speed: number = DanmakuItem.DEFAULT_SPEED;
  sender: string = '';
  
  constructor(
    id: string,
    content: string,
    time: number,
    color: string = '#FFFFFF',
    speed: number = DanmakuItem.DEFAULT_SPEED
  ) {
    this.id = id;
    this.content = this.sanitizeContent(content);
    this.time = time;
    this.color = this.validateColor(color);
    this.speed = this.clampSpeed(speed);
  }
  
  // 内容清洗（截断并转义）
  private sanitizeContent(content: string): string {
    // 截断超长内容
    let sanitized = content.slice(0, DanmakuItem.MAX_CONTENT_LENGTH);
    
    // 转义特殊字符（防止XSS）
    sanitized = sanitized
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
    
    return sanitized;
  }
  
  // 校验颜色格式
  private validateColor(color: string): string {
    const colorRegex = /^#[0-9A-Fa-f]{6}$/;
    return colorRegex.test(color) ? color : '#FFFFFF';
  }
  
  // 约束速度范围
  private clampSpeed(speed: number): number {
    return Math.max(DanmakuItem.MIN_SPEED,
                    Math.min(DanmakuItem.MAX_SPEED, speed));
  }
  
  // 校验
  isValid(): boolean {
    return this.id.length > 0 &&
           this.content.length > 0 &&
           this.content.length <= DanmakuItem.MAX_CONTENT_LENGTH &&
           this.time >= 0;
  }
  
  // 序列化
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      content: this.content,
      time: this.time,
      color: this.color,
      track: this.track,
      speed: this.speed,
      sender: this.sender
    });
  }
  
  // 反序列化
  static fromJSON(json: string): DanmakuItem {
    const obj = JSON.parse(json);
    const item = new DanmakuItem(
      obj.id,
      obj.content,
      obj.time,
      obj.color,
      obj.speed
    );
    item.track = obj.track;
    item.sender = obj.sender || '';
    return item;
  }
}

export class DanmakuConfig {
  isVisible: boolean = true;
  speed: number = 100;
  fontSize: number = 16;
  opacity: number = 0.8;
  maxTrackCount: number = 10;
  sendCooldown: number = 2000;  // 发送冷却时间（毫秒）
  
  lastSendTime: number = 0;
  
  // 检查是否可以发送
  canSend(): boolean {
    const now = Date.now();
    return now - this.lastSendTime >= this.sendCooldown;
  }
  
  // 记录发送时间
  recordSend(): void {
    this.lastSendTime = Date.now();
  }
}
```

### **3.2.5 播放结束状态模型**

```typescript
// model/PlaybackEndModel.ets
export enum EndState {
  PLAYING = 'playing',
  ENDED = 'ended',
  COUNTDOWN = 'countdown',
  REPLAY = 'replay'
}

export class PlaybackEndState {
  state: EndState = EndState.PLAYING;
  countdown: number = 10;
  isLastEpisode: boolean = false;
  nextEpisodeIndex: number = -1;
  autoPlayEnabled: boolean = true;
  
  private countdownTimer: number = -1;
  private onCountdownEnd: (() => void) | null = null;
  
  // 开始倒计时
  startCountdown(
    seconds: number,
    onTick: (remaining: number) => void,
    onEnd: () => void
  ): void {
    this.state = EndState.COUNTDOWN;
    this.countdown = seconds;
    this.onCountdownEnd = onEnd;
    
    this.countdownTimer = setInterval(() => {
      this.countdown--;
      onTick(this.countdown);
      
      if (this.countdown <= 0) {
        this.stopCountdown();
        if (this.onCountdownEnd) {
          this.onCountdownEnd();
        }
      }
    }, 1000);
  }
  
  // 停止倒计时
  stopCountdown(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
    this.state = EndState.PLAYING;
  }
  
  // 设置播放结束
  setEnded(isLastEpisode: boolean): void {
    this.state = EndState.ENDED;
    this.isLastEpisode = isLastEpisode;
  }
  
  // 设置重新播放
  setReplay(): void {
    this.stopCountdown();
    this.state = EndState.REPLAY;
  }
}
```

# **4. 技术选型**

## **4.1 开发框架**

| 技术 | 用途 | 版本要求 |
|------|------|----------|
| ArkTS | 应用开发语言 | HarmonyOS NEXT API 12+ |
| ArkUI | UI框架 | 原生支持 |
| XComponent | Native桥接 | 原生支持 |

## **4.2 系统能力**

| 能力 | 模块 | 用途 |
|------|------|------|
| 音量管理 | @ohos.multimedia.audio | 系统音量控制 |
| 数据存储 | @ohos.data.preferences | 进度、配置持久化 |
| 加解密 | @ohos.security.cryptoFramework | 进度数据加密 |
| 日志 | @kit.PerformanceAnalysisKit | 日志记录 |
| 窗口管理 | @kit.ArkUI | 全屏切换 |

## **4.3 第三方依赖**

| 依赖 | 用途 | 备注 |
|------|------|------|
| libplayer.so | Native播放器 | 已有，需扩展接口 |

## **4.4 性能优化策略**

- **弹幕渲染**：使用Canvas替代组件渲染，提升帧率
- **进度保存**：使用防抖策略，避免频繁IO
- **状态管理**：使用`@Track`精准追踪状态变化
- **内存管理**：弹幕数据分页加载，避免一次性加载过多

# **5. 关键技术点总结**

## **5.1 架构亮点**

1. **分层解耦**：UI、业务、数据三层分离，职责清晰
2. **模块化设计**：各功能模块独立封装，可单独测试和复用
3. **响应式编程**：充分利用ArkUI状态驱动特性，减少手动DOM操作
4. **异步优先**：所有耗时操作异步化，保证UI流畅

## **5.2 性能保障**

1. **弹幕高性能渲染**：Canvas + requestAnimationFrame，保证30fps
2. **音量实时响应**：<100ms延迟，即时反馈
3. **画质快速切换**：Promise.race实现超时控制，2秒内完成
4. **进度精准保存**：定时保存 + 退出保存，最多丢失10秒

## **5.3 安全防护**

1. **输入校验**：弹幕长度、特殊字符过滤
2. **频率限制**：弹幕发送冷却时间，防止刷屏
3. **数据加密**：进度数据加密存储，保护隐私
4. **异常处理**：全链路异常捕获，不影响主流程

## **5.4 扩展能力**

1. **可配置化**：弹幕速度、倒计时时长等参数可动态调整
2. **插件化**：弹幕敏感词过滤可插拔
3. **接口预留**：Native层接口预留扩展点，支持后续功能增强
