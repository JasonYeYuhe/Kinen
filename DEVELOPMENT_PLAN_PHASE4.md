# Kinen Phase 4 开发计划书：App Store 发布准备

> 作者：Jason (叶宇和) + Claude Opus 4.6
> 日期：2026-04-09
> 状态：待 Gemini 3.1 Pro 审阅

---

## 一、Context

Kinen Phase 3 已完成（46 Swift 文件、5,689 LOC、35 测试、9 次提交、25+ 功能）。iCloud 同步、StoreKit 订阅、加密备份全部就绪。

**Phase 4 目标：让 Kinen 准备好提交 App Store。**

审计发现了 7 个 App Store 必须修复的问题。

---

## 二、审计发现的 App Store 阻塞项

| # | 问题 | 严重度 | 描述 |
|---|------|--------|------|
| 1 | 无 PrivacyInfo.xcprivacy | 🔴 致命 | iOS 17+ Apple 强制要求，没有会被拒 |
| 2 | 68 个硬编码英文字符串 | 🔴 致命 | 所有 View 层文本未国际化 |
| 3 | 无 Localizable.strings | 🔴 致命 | String(localized:) 有用但无翻译文件 |
| 4 | 无无障碍支持 | 🟡 重要 | 零 accessibilityLabel/Hint |
| 5 | 无 StoreKit 测试配置 | 🟡 重要 | 无法本地测试 IAP |
| 6 | GitHub Pages 无截图 | 🟡 重要 | 营销站没有任何应用截图 |
| 7 | 无评分引导 | 🟠 一般 | 缺少 SKStoreReviewController |

---

## 三、Sprint 1：Apple 合规（致命修复）

### 1.1 PrivacyInfo.xcprivacy

**新增 `Resources/PrivacyInfo.xcprivacy`**

参照 Stride 的模式，声明：
- NSPrivacyTracking: false（不追踪）
- NSPrivacyTrackingDomains: 空数组
- NSPrivacyCollectedDataTypes: 空数组（所有数据本地处理）
- NSPrivacyAccessedAPITypes: UserDefaults (C617.1), File timestamp (3B52.1)

这是 Kinen 最强差异化的证明文件 — "零数据收集"。

### 1.2 国际化 (i18n)

**目标语言：4 种**
- English (en) — 基础
- 简体中文 (zh-Hans)
- 繁体中文 (zh-Hant)
- 日本語 (ja)

**步骤：**
1. 新增 `Resources/en.lproj/Localizable.strings` — 英文基础键值对
2. 新增 `Resources/zh-Hans.lproj/Localizable.strings` — 简中翻译
3. 新增 `Resources/zh-Hant.lproj/Localizable.strings` — 繁中翻译
4. 新增 `Resources/ja.lproj/Localizable.strings` — 日文翻译
5. 修改 project.yml — knownRegions: [en, zh-Hans, zh-Hant, ja]
6. 修改所有 View 文件 — 68 个 `Text("...")` → `Text("key", tableName: nil)`

**翻译范围：** ~150 个字符串键（UI 标签、按钮、提示、模板名、错误信息等）

### 1.3 StoreKit 测试配置

**新增 `Resources/KinenProducts.storekit`**

定义 3 个产品用于 Xcode 本地测试：
- com.kinen.app.pro.monthly — $2.99 Auto-Renewable
- com.kinen.app.pro.yearly — $19.99 Auto-Renewable
- com.kinen.app.pro.lifetime — $99.99 Non-Consumable

---

## 四、Sprint 2：无障碍 + 用户体验完善

### 2.1 Accessibility

**修改所有交互组件，添加 accessibilityLabel/Hint：**

关键组件：
- MoodPicker — 每个情绪按钮: `accessibilityLabel("Mood: Great")`
- FilterBar — 筛选 chips: `accessibilityLabel("Filter by mood: Happy")`
- EntryRow — `accessibilityLabel("\(title), \(mood), \(date)")`
- VoiceRecorderButton — `accessibilityLabel(isRecording ? "Stop recording" : "Start voice input")`
- SyncStatusBadge — `accessibilityLabel("iCloud sync enabled")`
- ProGate — `accessibilityLabel("Pro feature locked")`
- CalendarScreen year heatmap — `accessibilityLabel("\(date): \(count) entries")`
- CrisisAlertView — `accessibilityLabel("Mental health resources")`

### 2.2 评分引导

**修改 `Sources/Views/Screens/SettingsView.swift`：**
- 添加 "Rate Kinen" 按钮，使用 `RequestReview` 环境变量
- 在写完第 10 篇日记后自动提示一次

### 2.3 版本信息 + What's New

**新增 `Sources/Views/Components/WhatsNewSheet.swift`：**
- 版本更新日志（当版本号变化时自动弹出）
- 列出新功能亮点

---

## 五、Sprint 3：App Store 素材

### 3.1 App Store 截图生成

不手动截图 — 用 SwiftUI Preview 生成：

**新增 `Sources/Core/PreviewData.swift`：**
- Mock JournalEntry 数据（含情绪、标签、洞察）
- Mock Tag 数据
- Mock Recap 数据

为关键屏幕添加 #Preview：
- JournalListScreen（有丰富条目的列表）
- EntryDetailScreen（带 AI 洞察和 CBT 建议）
- InsightsScreen（有图表和数据的仪表板）
- CalendarScreen（年度热力图有颜色数据）
- RecapScreen（周报有完整数据）
- ProPaywallView（定价页面）
- OnboardingView（引导页）

### 3.2 更新 GitHub Pages

**修改 `docs/index.html`：**
- 添加截图展示区（从 Preview 中导出）
- 添加 "Available on the App Store" 标志占位
- 添加 changelog/版本历史

### 3.3 App Store 元数据准备

**新增 `appstore/` 文件夹：**
- `appstore/description-en.txt` — 英文描述
- `appstore/description-zh.txt` — 中文描述
- `appstore/keywords.txt` — 关键词
- `appstore/whats-new.txt` — 更新说明

---

## 六、文件变更汇总

| 类型 | 文件 | Sprint |
|------|------|--------|
| 新增 | Resources/PrivacyInfo.xcprivacy | 1 |
| 新增 | Resources/en.lproj/Localizable.strings | 1 |
| 新增 | Resources/zh-Hans.lproj/Localizable.strings | 1 |
| 新增 | Resources/zh-Hant.lproj/Localizable.strings | 1 |
| 新增 | Resources/ja.lproj/Localizable.strings | 1 |
| 新增 | Resources/KinenProducts.storekit | 1 |
| 修改 | project.yml (knownRegions + storekit) | 1 |
| 修改 | ~15 View 文件 (68 字符串国际化) | 1 |
| 修改 | ~10 组件 (accessibility) | 2 |
| 修改 | SettingsView.swift (评分引导) | 2 |
| 新增 | WhatsNewSheet.swift | 2 |
| 新增 | PreviewData.swift | 3 |
| 修改 | ~7 屏幕 (添加 #Preview) | 3 |
| 修改 | docs/index.html (截图) | 3 |
| 新增 | appstore/ 元数据文件夹 | 3 |

**预计：新增 ~10 文件 | 修改 ~25 文件 | 新增代码 ~2,000 行（大量翻译文本）**

---

## 七、不做什么

- ❌ Apple Watch app（Phase 5）
- ❌ Widget Extension（Phase 5）
- ❌ CoreML 情感模型升级（Phase 5+）
- ❌ 自动截图脚本（手动从 Preview 导出即可）
- ❌ Android/Windows（Cortex 方案的领域）

---

## 八、验证标准

- [ ] 双平台编译通过
- [ ] PrivacyInfo.xcprivacy 包含在两个 target 中
- [ ] 切换语言到中文/日文后 UI 完整显示翻译
- [ ] VoiceOver 能正确朗读所有交互元素
- [ ] StoreKit 本地测试 3 个产品购买流程
- [ ] 每个主要屏幕有 #Preview 且显示正常
- [ ] GitHub Pages 有应用截图
- [ ] git push 到 GitHub
- [ ] `xcodebuild archive` 可以生成有效的 .xcarchive
