# Kinen App Store 提交状态

> 更新时间：2026-04-10
> 状态：Prepare for Submission

## App Store Connect 信息

- **App Name:** Kinen - AI Journal
- **Apple ID:** 6761919528
- **Bundle ID:** com.jasonye.kinen
- **SKU:** kinen-ai-journal
- **Team ID:** KHMK6Q3L3K
- **Platforms:** iOS + macOS
- **ASC URL:** https://appstoreconnect.apple.com/apps/6761919528/distribution/ios/version/inflight

## 已完成

- [x] Developer Portal: Bundle ID `com.jasonye.kinen` 已注册
- [x] App Store Connect: App 记录已创建（iOS 1.0 + macOS 1.0）
- [x] 代码 Bundle ID 已更新为 `com.jasonye.kinen`
- [x] macOS Archive 成功（Apple Development 签名）
- [x] iOS Archive 成功（Apple Development 签名）
- [x] Archives 在 `~/Documents/Kinen/build/` 目录

## 未完成（需要在 App Store Connect 填写）

### iOS App Version 1.0 页面

| 字段 | 状态 | 值 |
|------|------|-----|
| Screenshots | ❌ 未上传 | 需要 iPhone 6.5" 截图 (1242x2688 或 1284x2778) |
| Promotional Text | ❌ 未填 | 见下方 |
| Description | ❌ 未填 | 见 appstore/description-en.txt |
| Keywords | ❌ 未填 | 见下方 |
| Support URL | ❌ 未填 | https://jasonyeyuhe.github.io/Kinen/ |
| Marketing URL | ❌ 未填 | https://jasonyeyuhe.github.io/Kinen/ |
| Copyright | ❌ 未填 | 2026 Jason Ye |
| Build | ❌ 未上传 | 需要从 Xcode Organizer 上传 |

### macOS App Version 1.0 页面

| 字段 | 状态 |
|------|------|
| 同上所有字段 | ❌ 未填 |
| macOS Screenshots | ❌ 未上传 |

### App Information 页面（左侧栏 General → App Information）

| 字段 | 状态 | 值 |
|------|------|-----|
| Primary Category | ❌ 未设置 | Health & Fitness |
| Secondary Category | ❌ 未设置 | Lifestyle |
| Content Rights | ❌ 未确认 | "Does not contain third-party content" |
| Age Rating | ❌ 未填 | 全部 No，可能 Medical/Treatment = Infrequent |

### App Privacy 页面（左侧栏 App Store → App Privacy）

| 字段 | 状态 | 值 |
|------|------|-----|
| Privacy Policy URL | ❌ 未填 | https://jasonyeyuhe.github.io/Kinen/ |
| Data Collection | ❌ 未声明 | "Does not collect data" |

### Pricing 页面

| 字段 | 状态 | 值 |
|------|------|-----|
| Price | ❌ 未设置 | Free (IAP for Pro features) |
| Availability | ❌ 未设置 | All territories |

## 要填写的文本（直接复制粘贴）

### Promotional Text (170 char max)
```
Your private AI journal. Mood analysis, CBT reflections, and pattern discovery — all on your device. Zero cloud.
```

### Keywords (100 char max, comma-separated)
```
journal,diary,AI,mood,CBT,mental health,private,local,sentiment,reflection,gratitude,wellness
```

### Support URL
```
https://jasonyeyuhe.github.io/Kinen/
```

### Marketing URL
```
https://jasonyeyuhe.github.io/Kinen/
```

### Copyright
```
2026 Jason Ye
```

### Privacy Policy URL
```
https://jasonyeyuhe.github.io/Kinen/
```

### Description
见文件：`appstore/description-en.txt`

### What's New in This Version
```
Initial release of Kinen - AI Journal.

- On-device AI mood analysis and sentiment tracking
- CBT cognitive distortion detection with reframing
- 8 guided journal templates
- Voice journaling with on-device speech recognition
- iCloud sync across Apple devices
- AES-256 encrypted backups
- Face ID / Touch ID app lock
- Swift Charts mood trends and insights
- Year-at-a-glance calendar heatmap
```

## 项目文件位置

- 代码：`~/Documents/Kinen/`
- App Store 描述：`~/Documents/Kinen/appstore/description-en.txt`
- 中文描述：`~/Documents/Kinen/appstore/description-zh.txt`
- 关键词：`~/Documents/Kinen/appstore/keywords.txt`
- GitHub：https://github.com/JasonYeYuhe/Kinen
- Pages：https://jasonyeyuhe.github.io/Kinen/
- Archives：`~/Documents/Kinen/build/Kinen-iOS.xcarchive` + `Kinen-macOS.xcarchive`
- Build script：`~/Documents/Kinen/scripts/build-appstore.sh`
