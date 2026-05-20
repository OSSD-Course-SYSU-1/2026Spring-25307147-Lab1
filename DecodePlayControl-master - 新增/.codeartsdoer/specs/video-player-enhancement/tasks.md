# 鸿蒙视频播放器增强功能 - 实现任务列表

## 1. 基础架构搭建

### 1.1 目录结构创建
- [ ] 创建数据模型目录：`entry/src/main/ets/model/`
- [ ] 创建视图模型目录：`entry/src/main/ets/viewmodel/`
- [ ] 创建服务层目录：`entry/src/main/ets/service/`
- [ ] 创建工具类目录：`entry/src/main/ets/utils/`

### 1.2 基础数据模型实现
- [ ] 实现画质数据模型 `model/QualityModel.ets`：
  - 定义 `QualityItem` 类（id、name、resolution、bitrate）
  - 实现 `isValid()` 校验方法
  - 实现 `toJSON()` 和 `fromJSON()` 序列化方法
- [ ] 实现音量数据模型 `model/VolumeModel.ets`：
  - 定义 `VolumeConfig` 类（value、step、isMuted）
  - 实现 `clamp()` 音量值约束方法
  - 实现 `increase()` 和 `decrease()` 音量调节方法
- [ ] 实现播放进度数据模型 `model/ProgressModel.ets`：
  - 定义 `ProgressRecord` 类（videoId、episodeIndex、position、duration、timestamp）
  - 实现 `getStorageKey()` 生成复合键方法
  - 实现 `getProgressPercent()` 进度百分比计算
- [ ] 实现弹幕数据模型 `model/DanmakuModel.ets`：
  - 定义 `DanmakuItem` 类（id、content、time、color、track、speed）
  - 实现 `sanitizeContent()` 内容清洗方法（长度限制、特殊字符转义）
  - 实现 `validateColor()` 颜色格式校验方法
- [ ] 实现播放结束状态模型 `model/PlaybackEndModel.ets`：
  - 定义 `EndState` 枚举（PLAYING、ENDED、COUNTDOWN、REPLAY）
  - 定义 `PlaybackEndState` 类（state、countdown、isLastEpisode）
  - 实现倒计时管理方法

## 2. 数据存储服务实现

### 2.1 Preferences存储服务
- [ ] 创建存储服务基类 `service/BaseStorage.ets`：
  - 封装 `@ohos.data.preferences` API
  - 实现 `init()` 初始化方法
  - 实现 `get()` 和 `set()` 读写方法
  - 实现 `delete()` 删除方法
- [ ] 实现进度存储服务 `service/ProgressStorage.ets`：
  - 继承 `BaseStorage`
  - 实现 `saveProgress()` 保存播放进度方法
  - 实现 `loadProgress()` 加载历史进度方法
  - 实现 `clearProgress()` 清除进度方法
  - 实现过期记录自动清理逻辑
- [ ] 实现配置存储服务 `service/ConfigStorage.ets`：
  - 继承 `BaseStorage`
  - 实现 `saveVolumeConfig()` 音量配置保存方法
  - 实现 `loadVolumeConfig()` 音量配置加载方法
  - 实现 `saveDanmakuConfig()` 弹幕配置保存方法

### 2.2 数据加密服务（可选）
- [ ] 创建加密工具类 `utils/CryptoUtils.ets`：
  - 封装 `@ohos.security.cryptoFramework` API
  - 实现 `encrypt()` 加密方法
  - 实现 `decrypt()` 解密方法
  - 处理加密异常场景

## 3. 画质调节功能实现

### 3.1 画质管理器实现
- [ ] 创建画质管理器 `viewmodel/QualityManager.ets`：
  - 定义 `IQualityManager` 接口
  - 实现 `loadQualityList()` 获取画质列表方法
  - 实现 `switchQuality()` 画质切换方法（含2秒超时控制）
  - 实现 `getCurrentQuality()` 获取当前画质方法
  - 实现 `isQualitySwitchSupported()` 画质切换支持检测方法
  - 使用 `Promise.race()` 实现超时控制

### 3.2 画质选择器UI组件
- [ ] 创建画质选择器组件 `view/QualitySelector.ets`：
  - 定义组件状态：`@Prop qualityList`、`@Prop currentQuality`、`@Link isVisible`
  - 实现画质列表展示UI（Flex布局）
  - 实现当前画质标识显示（橙色高亮）
  - 实现画质选项点击事件处理
  - 实现切换失败提示UI
- [ ] 集成画质选择器到主播放视图 `view/VideoPlayView.ets`：
  - 添加画质按钮到控制栏
  - 根据画质列表长度动态显示/隐藏按钮
  - 绑定画质管理器方法

### 3.3 Native层画质接口扩展
- [ ] 扩展Native播放器接口 `cpp/types/libplayer/Index.d.ts`：
  - 添加 `setQuality()` 画质设置接口定义
  - 添加 `getSupportedQualities()` 获取画质列表接口定义
- [ ] 实现Native层画质切换逻辑（可选，如需Native支持）：
  - 在 `cpp/player/src/Player.cpp` 添加画质切换实现
  - 处理视频流切换逻辑

## 4. 音量控制功能实现

### 4.1 音量管理器实现
- [ ] 创建音量管理器 `viewmodel/VolumeManager.ets`：
  - 定义 `IVolumeManager` 接口
  - 封装 `@ohos.multimedia.audio` 的 `AudioVolumeManager`
  - 实现 `setVolume()` 设置音量方法（0-100范围约束）
  - 实现 `getVolume()` 获取音量方法
  - 实现 `toggleMute()` 切换静音方法
  - 实现 `increaseVolume()` 和 `decreaseVolume()` 音量增减方法
  - 实现音量持久化保存逻辑
- [ ] 实现音量键事件监听：
  - 监听系统音量变化事件
  - 同步更新UI音量滑块位置

### 4.2 音量控制UI组件
- [ ] 创建音量控制组件 `view/VolumeControl.ets`：
  - 定义组件状态：`@Link volume`、`@Link isMuted`
  - 实现音量图标（根据音量值切换图标：静音/低音量/高音量）
  - 实现音量滑块（Slider组件，range 0-100）
  - 实现滑块拖动实时响应（`@Watch` 装饰器监听）
  - 实现静音按钮点击事件
- [ ] 集成音量控制到主播放视图：
  - 添加音量控制组件到控制栏
  - 绑定音量管理器方法
  - 应用启动时加载上次音量设置

## 5. 进度记忆与回溯功能实现

### 5.1 进度追踪器实现
- [ ] 创建进度追踪器 `viewmodel/ProgressTracker.ets`：
  - 定义 `IProgressTracker` 接口
  - 实现 `startTracking()` 开始追踪方法（启动10秒定时器）
  - 实现 `stopTracking()` 停止追踪方法（清除定时器）
  - 实现 `saveProgress()` 保存当前进度方法
  - 实现 `loadProgress()` 加载历史进度方法
  - 实现应用退出时立即保存逻辑（`aboutToDisappear` 生命周期）
  - 使用 `setInterval` 实现10秒自动保存

### 5.2 进度回溯UI组件
- [ ] 创建进度回溯按钮组件 `view/ProgressRecallButton.ets`：
  - 定义组件状态：`@Prop lastPosition`、`@Link isVisible`
  - 实现"上次播放至XX:XX"提示文本（使用 `TimeUtils` 格式化）
  - 实现按钮点击跳转逻辑
  - 实现跳转成功提示（2秒后自动消失）
  - 定位在视频窗口左下角
- [ ] 集成进度回溯功能到主播放视图：
  - 视频加载时查询历史进度
  - 根据历史进度存在性显示/隐藏回溯按钮
  - 点击回溯后调用 `player.seek()` 跳转

### 5.3 多集视频进度管理
- [ ] 实现多集进度独立存储逻辑：
  - 使用复合键 `videoId_episodeIndex` 区分不同集数
  - 视频切换时自动切换到对应集的进度
  - 实现进度数据过期清理（30天过期）

## 6. 弹幕功能实现

### 6.1 弹幕轨道管理器实现
- [ ] 创建弹幕轨道管理器 `viewmodel/DanmakuTrackManager.ets`：
  - 定义 `IDanmakuTrackManager` 接口
  - 实现轨道分配算法（贪心算法，优先选择最早释放的轨道）
  - 实现 `allocateTrack()` 分配轨道方法
  - 实现 `releaseTrack()` 释放轨道方法
  - 实现 `getTrackPosition()` 获取轨道垂直位置方法
  - 支持配置最大轨道数（默认10条）

### 6.2 弹幕管理器实现
- [ ] 创建弹幕管理器 `viewmodel/DanmakuManager.ets`：
  - 定义 `IDanmakuManager` 接口
  - 实现 `loadDanmaku()` 加载弹幕数据方法（支持分页加载）
  - 实现 `sendDanmaku()` 发送弹幕方法（含频率限制、长度校验）
  - 实现 `toggleVisibility()` 切换显示状态方法
  - 实现 `setSpeed()` 设置弹幕速度方法
  - 实现发送冷却时间检测（2秒间隔）
  - 实现本地弹幕缓存逻辑
- [ ] 集成弹幕轨道管理器到弹幕管理器

### 6.3 弹幕渲染视图组件
- [ ] 创建弹幕渲染视图 `view/DanmakuView.ets`：
  - 定义组件状态：`@Prop danmakuList`、`@Link isVisible`
  - 使用 Canvas 组件实现高性能渲染
  - 实现弹幕滚动动画（从右向左）
  - 使用 `requestAnimationFrame` 保证30fps帧率
  - 实现弹幕颜色渲染（支持多种颜色）
  - 实现弹幕轨道分配和避免重叠
  - 实现横竖屏自适应调整
- [ ] 实现弹幕性能优化：
  - 实现弹幕密度自动降低机制（当渲染性能下降时）
  - 实现屏幕外弹幕自动回收

### 6.4 弹幕输入组件
- [ ] 创建弹幕输入组件 `view/DanmakuInput.ets`：
  - 定义组件状态：`@State inputText`、`@State selectedColor`
  - 实现弹幕输入框（TextInput组件，最大100字符）
  - 实现颜色选择器（预设颜色列表：白、红、黄、蓝、绿）
  - 实现发送按钮（支持快捷键发送）
  - 实现输入长度实时提示
  - 实现发送频率限制提示（"发送过快，请稍后再试"）
- [ ] 集成弹幕功能到主播放视图：
  - 添加弹幕渲染视图覆盖在视频画面上
  - 添加弹幕输入组件到控制栏
  - 添加弹幕开关按钮
  - 视频播放时同步弹幕时间戳

### 6.5 敏感词过滤（可选）
- [ ] 创建敏感词过滤工具 `utils/SensitiveWordFilter.ets`：
  - 实现敏感词列表加载
  - 实现 `filter()` 过滤方法
  - 实现 `containsSensitiveWord()` 检测方法

## 7. 播放结束处理功能实现

### 7.1 自动播放管理器实现
- [ ] 创建自动播放管理器 `viewmodel/AutoPlayManager.ets`：
  - 定义 `IAutoPlayManager` 接口
  - 实现 `hasNextEpisode()` 检查下一集是否存在方法
  - 实现 `getNextEpisodeIndex()` 获取下一集索引方法
  - 实现 `loadAndPlayNext()` 加载并播放下一集方法
  - 实现 `setAutoPlayEnabled()` 设置自动播放开关方法

### 7.2 播放结束状态处理器实现
- [ ] 创建播放结束状态处理器 `viewmodel/EndStateHandler.ets`：
  - 定义 `IEndStateHandler` 接口
  - 实现 `onPlaybackEnd()` 播放结束处理方法
  - 实现 `startCountdown()` 启动倒计时方法（10秒，误差<100ms）
  - 实现 `cancelCountdown()` 取消倒计时方法
  - 实现 `replayCurrent()` 重新播放当前视频方法
  - 实现 `playNext()` 播放下一集方法
  - 实现状态机管理（避免重复触发）
  - 实现防抖处理（忽略短时间内重复结束事件）
- [ ] 扩展Native播放器回调：
  - 添加 `onCompletion` 播放结束事件监听
  - 在 `cpp/player/src/Player.cpp` 发送播放完成回调

### 7.3 播放结束覆盖层UI组件
- [ ] 创建播放结束覆盖层组件 `view/PlaybackEndOverlay.ets`：
  - 定义组件状态：`@Prop countdown`、`@Prop isLastEpisode`、`@Link isVisible`
  - 实现半透明遮罩背景
  - 实现"重新播放"按钮（居中显示）
  - 实现倒计时提示文本（"X秒后自动播放下一集"）
  - 实现最后一集提示（"本集已播完"）
  - 实现倒计时每秒更新动画
- [ ] 集成播放结束处理到主播放视图：
  - 监听Native播放器 `onCompletion` 事件
  - 播放结束时显示覆盖层组件
  - 绑定重新播放和自动播放逻辑

## 8. 日志与异常处理

### 8.1 日志工具类
- [ ] 创建日志工具类 `utils/Logger.ets`：
  - 封装 `@kit.PerformanceAnalysisKit` 日志API
  - 实现不同级别日志方法（debug、info、warn、error）
  - 实现日志格式化（包含时间戳、模块名、操作类型）
  - 记录用户操作日志（画质切换、音量调节、弹幕发送等）
  - 记录关键错误日志（错误码、错误消息、调用栈）

### 8.2 异常处理机制
- [ ] 实现全局异常捕获处理：
  - 所有异步操作使用 `try-catch` 包裹
  - 异常不影响主流程，记录日志后继续
  - 实现用户友好的错误提示（Toast提示）
- [ ] 实现各模块异常场景处理：
  - 画质切换超时/失败处理
  - 音量设置失败处理
  - 进度加载/保存失败处理
  - 弹幕加载/发送失败处理
  - 播放结束事件异常处理

## 9. 性能优化实现

### 9.1 弹幕渲染性能优化
- [ ] 优化弹幕Canvas渲染：
  - 实现弹幕对象池复用
  - 实现离屏Canvas预渲染
  - 实现渲染帧率监控（确保≥30fps）
  - 实现弹幕数量动态降级（性能不足时自动减少显示）

### 9.2 进度保存性能优化
- [ ] 实现进度保存防抖策略：
  - 使用防抖函数避免频繁IO
  - 合并短时间内的多次保存请求

### 9.3 内存优化
- [ ] 实现弹幕数据分页加载：
  - 按时间段分页加载弹幕
  - 播放进度变化时预加载下一页弹幕
  - 释放已播放时段的弹幕数据

## 10. 集成与测试

### 10.1 主播放视图集成
- [ ] 在 `viewmodel/VideoPlayViewModel.ets` 中集成所有功能管理器：
  - 集成 `QualityManager`
  - 集成 `VolumeManager`
  - 集成 `ProgressTracker`
  - 集成 `DanmakuManager`
  - 集成 `EndStateHandler`
- [ ] 在 `view/VideoPlayView.ets` 中集成所有UI组件：
  - 集成画质选择器组件
  - 集成音量控制组件
  - 集成进度回溯按钮组件
  - 集成弹幕渲染视图和输入组件
  - 集成播放结束覆盖层组件

### 10.2 功能验证测试
- [ ] 验证画质调节功能：
  - 测试画质列表加载
  - 测试画质切换（成功/失败/超时场景）
  - 测试不支持画质切换的视频源
- [ ] 验证音量控制功能：
  - 测试音量滑块实时调节
  - 测试音量键响应
  - 测试静音切换
  - 测试音量持久化保存和恢复
- [ ] 验证进度记忆与回溯功能：
  - 测试进度自动保存（每10秒）
  - 测试历史进度加载和回溯跳转
  - 测试多集视频独立进度
  - 测试应用退出时进度保存
- [ ] 验证弹幕功能：
  - 测试弹幕渲染和滚动
  - 测试弹幕发送（长度限制、频率限制）
  - 测试弹幕显示/隐藏切换
  - 测试弹幕颜色选择
  - 测试弹幕轨道分配（避免重叠）
  - 测试横竖屏弹幕自适应
- [ ] 验证播放结束处理功能：
  - 测试播放结束检测
  - 测试倒计时显示和自动播放
  - 测试重新播放按钮
  - 测试最后一集处理
  - 测试倒计时取消

### 10.3 性能验证
- [ ] 验证画质切换响应时间（<2秒）
- [ ] 验证弹幕渲染帧率（≥30fps）
- [ ] 验证音量调节延迟（<100ms）
- [ ] 验证进度回溯跳转延迟（<1秒）
- [ ] 验证弹幕发送到显示延迟（<200ms）

### 10.4 异常场景测试
- [ ] 测试画质切换失败场景
- [ ] 测试音量设置失败场景
- [ ] 测试进度加载/保存失败场景
- [ ] 测试弹幕加载失败场景（使用本地缓存）
- [ ] 测试弹幕发送失败场景
- [ ] 测试网络异常场景

## 11. 文档与交付

### 11.1 代码注释完善
- [ ] 为所有公共接口添加JSDoc注释
- [ ] 为复杂算法添加实现说明注释
- [ ] 为关键业务逻辑添加注释

### 11.2 配置文件更新
- [ ] 更新 `module.json5` 添加必要权限（如音量控制权限）
- [ ] 检查依赖配置完整性

### 11.3 功能演示准备
- [ ] 准备不同画质等级的测试视频
- [ ] 准备弹幕测试数据
- [ ] 准备多集视频测试数据
