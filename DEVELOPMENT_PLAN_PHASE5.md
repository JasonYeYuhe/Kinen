# Kinen v0.2.0 开发 Prompt — Phase 5: 稳定性 & 打磨

请按照以下开发计划，对 Kinen (記念) 项目执行 Phase 5 的全部开发工作。这是一个 SwiftUI + SwiftData 的隐私优先 AI 日记应用，已提交 App Store (v0.1.0)。Phase 5 的目标是修复所有已知 bug、完成本地化、补齐无障碍支持、修复 UX 缺陷，产出 v0.2.0 更新。

---

## 整体原则

- 所有修改必须同时兼容 macOS 15+ 和 iOS 18+ (通过 `#if os()` 处理差异)
- 遵循项目现有模式：SwiftData 持久化、async/await 并发、OSLog 日志、`String(localized:)` 本地化
- 不引入第三方依赖
- 每个 Sprint 完成后 commit 一次，commit message 用英文，描述清楚改动内容
- 修改完成后运行 `xcodegen generate && xcodebuild test -scheme Kinen -destination 'platform=macOS'` 验证

---

## Sprint 5.1: 关键 Bug 修复

### 任务 1: 修复模板条目编辑顺序 bug
**文件**: `Sources/Views/Screens/EntryEditorSheet.swift`
**问题**: `effectiveContent` 计算属性使用 `templateResponses.values` 拼接模板内容，但 Swift Dictionary 无序，导致保存后段落顺序可能打乱。
**修复**: 找到 `effectiveContent` 计算属性（约 line 418），改为按 `template.prompts` 的顺序迭代，使用 prompt ID 作为 key 从 `templateResponses` 中取值拼接。确保顺序与模板定义一致。

### 任务 2: 完善备份恢复
**文件**: `Sources/Features/Settings/BackupService.swift`
**问题**: `BackupEntry` 结构体缺少 `photoData`、`isHidden`、`template` 字段，备份数据不完整。
**修复**:
1. 在 `BackupEntry` 结构体中新增字段：`photoDataBase64: String?`、`isHidden: Bool`、`templateRawValue: String?`
2. 在 `createBackup` 方法中，将 `entry.photoData` 转为 base64 字符串存入、保存 `entry.isHidden`、保存 `entry.template?.rawValue`
3. 在 `restoreBackup` 方法中，恢复这些字段：将 base64 还原为 Data 赋给 `photoData`、恢复 `isHidden`、通过 rawValue 恢复 `template`
4. 确保 `BackupEntry` 的 `CodingKeys` 和 Codable 兼容（新字段用 optional 确保向后兼容旧备份文件）

### 任务 3: 修复 Re-analyze 清除旧洞察
**文件**: `Sources/Views/Screens/EntryDetailScreen.swift`, `Sources/Models/EntryInsight.swift`
**问题**: 重新分析时 `entry.insights = []` 直接清空，用户丢失之前的 AI 分析结果。
**修复**: 
1. 在 `EntryInsight` 模型中添加 `analysisVersion: Int = 1` 属性（带默认值以兼容 CloudKit）
2. 在 EntryDetailScreen 的重新分析逻辑中，不再清空旧 insights，而是递增 version 号并追加新 insights
3. 在显示 insights 时，默认展示最新版本的 insights，可选展开查看历史版本
4. 或者更简单的方案：在清空前显示确认弹窗 `.alert("重新分析将替换当前 AI 洞察，确定继续吗？")`

### 任务 4: 统一 AI 设置读取
**文件**: `Sources/Features/AI/AIJournalingLoop.swift`, `Sources/Views/Screens/EntryEditorSheet.swift`
**问题**: `AIJournalingLoop.processEntry()` 内部直接读 UserDefaults（line 28-29），应该由调用方传入设置。
**修复**:
1. 修改 `processEntry` 方法签名为：`func processEntry(_ entry: JournalEntry, in context: ModelContext, enableSentiment: Bool, enableTags: Bool) async`
2. 删除方法内部的 UserDefaults 读取（line 28-29）
3. 在 `EntryEditorSheet.swift` 的调用处，传入 `@AppStorage` 变量的值

---

## Sprint 5.2: 本地化完成

### 任务 5: 提取所有硬编码英文字符串
在以下文件中，将所有硬编码的 `Text("English string")` 替换为 `Text(String(localized: "key.name"))`，并在 `Resources/en.lproj/Localizable.strings` 和 `Resources/zh-Hans.lproj/Localizable.strings` 中添加对应条目。

**需处理的文件和关键字符串**:

1. **`Sources/Views/Screens/InsightsScreen.swift`** (~15 处):
   - "Current Streak", "Total Entries", "Mood Trend", "Sentiment Analysis", "Writing Activity", "This Week", "Top Topics", "View Weekly Recap", "day"/"days", "entries", "words", 空状态文字等
   - key 命名规范: `insights.streak.title`, `insights.mood.title`, `insights.sentiment.title` 等

2. **`Sources/Views/Screens/RecapScreen.swift`** (~10 处):
   - "This Week"/"This Month", "Overview", "entries"/"words", "day streak", "Average:", "Top feelings:", "Themes", "Highlights", "Challenges", "Growth", "Copy Recap to Clipboard"

3. **`Sources/Views/Screens/CalendarScreen.swift`** (~5 处):
   - "Month"/"Year" (picker labels), "No entries for this day", "Less"/"More" (legend), "entries this year"

4. **`Sources/Views/Screens/ProPaywallView.swift`** (~8 处):
   - "Unlock Kinen Pro", 功能描述列表, 价格说明, "Restore Purchases", "Already Pro"

5. **`Sources/Views/Screens/LockScreenView.swift`** (~3 处):
   - "Kinen is Locked", "Unlock with Face ID", 解锁按钮文字

6. **`Sources/Views/Components/WhatsNewSheet.swift`** (~4 处):
   - "What's New in Kinen", version 文字, changelog 条目

7. **`Sources/Features/AI/CrisisDetector.swift`** (CrisisAlertView 部分, ~4 处):
   - "You Matter", "Reach out for support:", "I Understand", disclaimer 文字

8. **`Sources/Views/Components/FilterBar.swift`** (~2 处):
   - "Bookmarked", "Clear"

**中文翻译要求**: 所有 zh-Hans 翻译要自然流畅，专业术语参考:
- Streak = 连续记录
- Insights = 洞察
- Mood Trend = 心情趋势
- Recap = 回顾
- CBT = 认知行为疗法

---

## Sprint 5.3: 无障碍 & 加载状态

### 任务 6: 添加无障碍标签
当前整个项目只有约 8 处 `.accessibilityLabel`，需要补充到 40+ 处。在以下文件添加适当的 `.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityElement()` 修饰符:

1. **`Sources/Views/Components/MoodPicker.swift`**: 每个心情按钮加 `.accessibilityLabel("心情: \(mood.label)")`
2. **`Sources/Views/Components/FilterBar.swift`**: 每个筛选芯片加标签描述
3. **`Sources/Views/Screens/InsightsScreen.swift`**: 图表卡片用 `.accessibilityElement(children: .combine)` 并加描述性标签
4. **`Sources/Views/Screens/CalendarScreen.swift`**: DayCell 加 `.accessibilityLabel` 包含日期和心情信息；年度热力图加整体描述
5. **`Sources/Views/Components/ProGate.swift`**: 锁定遮罩加功能说明
6. **`Sources/Views/Components/EntryRow.swift`**: 组合标签包含标题、心情、日期

### 任务 7: 添加加载状态
**文件**: `Sources/Views/Screens/JournalListScreen.swift`, `Sources/Views/Screens/InsightsScreen.swift`
在 `@Query` 数据初次加载时显示 `ProgressView`。由于 SwiftData `@Query` 不暴露 loading 状态，使用 `@State var isInitialLoad = true`，在 `.onAppear` 后设为 false。

### 任务 8: 添加错误提示组件
1. **新建** `Sources/Views/Components/ToastView.swift`: 一个简单的浮动提示 View，支持 success/error/info 类型，自动消失
2. **修改** `Sources/Views/Components/VoiceRecorderButton.swift`: 语音识别失败时通过回调传递错误信息
3. **修改** `Sources/Views/Screens/EntryEditorSheet.swift`: AI 处理失败时显示 toast 而非静默失败

### 任务 9: 日历空状态
**文件**: `Sources/Views/Screens/CalendarScreen.swift`
无条目时显示 `ContentUnavailableView`，参考 `JournalListScreen` 已有的空状态实现模式。

---

## Sprint 5.4: UX 修复 & 隐私对齐

### 任务 10: 修复隐私/同步信息矛盾
1. **`Sources/App/KinenApp.swift`**: 将 `iCloudSyncEnabled` 的默认值从 `true` 改为 `false`
2. **`Sources/Views/Screens/OnboardingView.swift`**: 在现有 4 页 Onboarding 中新增第 5 页，说明 iCloud 同步是可选功能，让用户主动选择开启
3. **`Sources/Views/Screens/SettingsView.swift`**: 更新 iCloud 区域的说明文字，明确"AI 分析 100% 在设备本地运行，iCloud 同步为可选功能，仅同步你选择的数据"

### 任务 11: macOS 设置可见性
**文件**: `Sources/Views/Screens/ContentView.swift`
在 macOS 侧边栏的 List 中（约 line 50-60）添加 Settings 选项，使用 `Label("Settings", systemImage: "gearshape")`，并在 detail 区域对应显示 `SettingsView()`。

### 任务 12: ProGate 细化
**文件**: `Sources/Views/Components/ProGate.swift`
修改 `ProGate` 接受新的 `description: String` 参数，在锁定遮罩中除了"需要 Pro"外还显示该功能的具体说明。更新所有调用处（如 `RecapScreen.swift`）传入具体描述。

### 任务 13: 日记列表排序选项
**文件**: `Sources/Views/Screens/JournalListScreen.swift`
1. 添加 `@State private var sortOption: SortOption = .dateDesc` (enum: dateDesc, dateAsc, moodDesc, wordCountDesc)
2. 在 toolbar 中添加排序选择器 Menu
3. 对 `filteredEntries` 结果应用排序（不修改 `@Query`，在内存中排序）

---

## 完成后

所有 Sprint 完成后:
1. 运行 `xcodegen generate && xcodebuild test -scheme Kinen -destination 'platform=macOS'` 确保所有测试通过
2. 在中文 locale 下检查 UI 确认无英文残留
3. 创建一个总结 commit，描述 Phase 5 的全部改动
4. 将 `project.yml` 中的版本号更新为 0.2.0
