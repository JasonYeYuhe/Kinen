# Kinen Phase 2 开发计划书

> 作者：Jason (叶宇和) + Claude Opus 4.6
> 日期：2026-04-09
> 状态：待 Gemini 3.1 Pro 审阅

---

## 一、当前状态 (Phase 1 完成)

| 指标 | 数值 |
|------|------|
| Swift 文件 | 34 |
| 代码行数 | 4,082 |
| 测试用例 | 24 (4 文件) |
| 平台 | macOS 15+ ✅, iOS 18+ ✅ |
| Git 提交 | 5 次 |
| GitHub | github.com/JasonYeYuhe/Kinen |
| Pages | jasonyeyuhe.github.io/Kinen |

### 已完成功能 (17项)

核心日记 · 8模板(含CBT) · 情绪追踪+NLP · AI 5步循环 · CBT认知扭曲检测(8种) · 智能写作提示 · 主题自动检测 · 语音转文字 · 照片日记 · 写作计时 · 日历热力图 · Swift Charts洞察仪表板 · 周报/月报 · Face ID锁 · 导出(MD/JSON/TXT) · 危机检测 · 引导页

---

## 二、审计发现的缺口 (Phase 2 目标)

### 关键缺陷 (必须修复)

| # | 问题 | 严重度 | 描述 |
|---|------|--------|------|
| 1 | macOS 隐私权限缺失 | 🔴 致命 | macOS Info.plist 缺少麦克风/语音/照片权限声明，调用时会崩溃 |
| 2 | macOS 缺少 entitlements | 🔴 致命 | macOS target 没有 App Sandbox entitlements |
| 3 | 无标签管理 UI | 🟡 重要 | 标签只能被 AI 创建，用户无法手动增删改 |
| 4 | 无筛选系统 | 🟡 重要 | 只有全文搜索，缺少按情绪/标签/日期筛选 |
| 5 | 无法重新分析旧条目 | 🟡 重要 | AI 只在创建时运行一次，旧条目无法重新分析 |

### 体验增强 (应该做)

| # | 问题 | 描述 |
|---|------|------|
| 6 | 缺少动画/转场 | 几乎零动画，iOS 无触觉反馈 |
| 7 | 缺少年度热力图 | 日历只有月视图，缺 GitHub 风格年度热力图 |
| 8 | Insights→Recap 未连通 | 两个页面独立，没有互相导航 |
| 9 | 无 SwiftUI Previews | 34 个文件零 Preview，开发效率低 |
| 10 | 编辑器缺 Markdown 预览 | 编辑器是纯文本，缺少基础 Markdown 渲染 |

---

## 三、Phase 2 实施计划

### Sprint 1：关键修复 (Bug-level)

**1.1 macOS 权限 & Entitlements**

修改文件：
- `Resources/Info.plist` — 添加 NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription, NSPhotoLibraryUsageDescription
- 新增 `Resources/Kinen-macOS.entitlements` — App Sandbox + 麦克风 + 照片
- `project.yml` — macOS target 引用 entitlements

**1.2 标签管理 UI**

新增文件：
- `Sources/Views/Screens/TagManagementSheet.swift` — 标签列表(名称/颜色/条目数) + 重命名/删除/合并
- `Sources/Views/Components/TagEditor.swift` — 条目编辑器中的手动标签输入(自动补全)

修改文件：
- `EntryEditorSheet.swift` — 添加标签编辑区域
- `EntryDetailScreen.swift` — 标签可点击进入管理
- `SettingsView.swift` — 添加"管理标签"入口

**1.3 筛选系统**

新增文件：
- `Sources/Views/Components/FilterBar.swift` — 横向筛选栏：情绪筛选(emoji chips)、标签筛选(多选)、日期范围、仅书签

修改文件：
- `JournalListScreen.swift` — 集成 FilterBar，替换纯文本搜索

### Sprint 2：体验增强

**2.1 重新分析旧条目**

修改文件：
- `EntryDetailScreen.swift` — 添加 "Re-analyze" 按钮，调用 AIJournalingLoop.processEntry()
- 显示分析进度指示器

**2.2 年度热力图**

修改文件：
- `CalendarScreen.swift` — 添加 year/month 切换
- 新增年度视图：12x31 网格，GitHub contribution 风格，颜色=情绪平均值

**2.3 动画 & 触觉反馈**

修改文件：
- `MoodPicker.swift` — 选择时弹跳动画 + iOS haptic
- `EntryRow.swift` — 列表出现时滑入动画
- `InsightsScreen.swift` — 数字递增动画
- `OnboardingView.swift` — 页面转场动画
- `ChatScreen` 风格的消息出现动画用于 insight 卡片

新增文件：
- `Sources/Core/HapticManager.swift` — 统一触觉反馈管理(iOS)

**2.4 Insights ↔ Recap 互通**

修改文件：
- `InsightsScreen.swift` — 底部添加 "View Weekly Recap →" 按钮
- `RecapScreen.swift` — 顶部添加 "View Detailed Charts →" 链接

**2.5 Markdown 预览**

修改文件：
- `EntryDetailScreen.swift` — 用 AttributedString 渲染基础 Markdown (粗体/斜体/标题/列表/代码)
- 不引入第三方库，纯 SwiftUI 实现

### Sprint 3：开发体验 + 代码质量

**3.1 SwiftUI Previews**

修改文件：为以下组件添加 #Preview：
- MoodPicker, EntryRow, EntryCard, FilterBar, TemplatePickerSheet
- OnboardingView, LockScreenView, CrisisAlertView
- InsightsScreen, CalendarScreen, RecapScreen (需要 mock data)

新增文件：
- `Sources/Core/PreviewData.swift` — 预览用的 mock JournalEntry/Tag/Insight 数据

**3.2 更多测试**

新增文件：
- `Tests/RecapGeneratorTests.swift` — 周报/月报生成 + 空数据处理
- `Tests/AIJournalingLoopTests.swift` — 主题检测 + 微实验生成
- `Tests/DateExtensionsTests.swift` — 日期工具测试

---

## 四、文件变更汇总

| 类型 | 文件 | Sprint |
|------|------|--------|
| 新增 | TagManagementSheet.swift | 1 |
| 新增 | TagEditor.swift | 1 |
| 新增 | FilterBar.swift | 1 |
| 新增 | Kinen-macOS.entitlements | 1 |
| 新增 | HapticManager.swift | 2 |
| 新增 | PreviewData.swift | 3 |
| 新增 | RecapGeneratorTests.swift | 3 |
| 新增 | AIJournalingLoopTests.swift | 3 |
| 新增 | DateExtensionsTests.swift | 3 |
| 修改 | Info.plist (macOS权限) | 1 |
| 修改 | project.yml (entitlements) | 1 |
| 修改 | EntryEditorSheet.swift (标签编辑) | 1 |
| 修改 | EntryDetailScreen.swift (re-analyze + Markdown) | 1+2 |
| 修改 | JournalListScreen.swift (筛选) | 1 |
| 修改 | SettingsView.swift (标签管理入口) | 1 |
| 修改 | CalendarScreen.swift (年度热力图) | 2 |
| 修改 | MoodPicker.swift (动画) | 2 |
| 修改 | InsightsScreen.swift (Recap链接+动画) | 2 |
| 修改 | RecapScreen.swift (Insights链接) | 2 |
| 修改 | OnboardingView.swift (转场动画) | 2 |

**预计新增文件：9 | 修改文件：11 | 预计新增代码：~1,500 行**

---

## 五、优先级与风险

### 不做什么 (Phase 3+)
- ❌ CloudKit 同步
- ❌ StoreKit 2 订阅（先验证产品再收费）
- ❌ Apple Watch app
- ❌ Widget Extension
- ❌ 国际化 Localizable.strings
- ❌ CoreML 情感模型（先用 NaturalLanguage）

### 风险
| 风险 | 缓解 |
|------|------|
| Markdown 渲染复杂度 | 只做基础格式(粗体/斜体/标题)，不做完整 CommonMark |
| 筛选器性能(大量条目) | SwiftData 的 #Predicate 在 SQLite 层面筛选，足够快 |
| 标签合并逻辑 | 合并时遍历所有条目替换引用，在 SwiftData context 中批量操作 |

---

## 六、验证标准

- [ ] macOS + iOS 双平台编译通过
- [ ] 所有测试通过 (目标 30+ test cases)
- [ ] 能手动创建/编辑/删除标签
- [ ] 能按情绪/标签/日期筛选条目
- [ ] 能在旧条目上重新运行 AI 分析
- [ ] 日历有年度热力图
- [ ] 情绪选择有动画和 iOS 触觉反馈
- [ ] git push 到 GitHub
