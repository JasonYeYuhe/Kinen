# Kinen App Store 提交状态

> 更新时间：2026-04-30 17:33 JST
> 状态：**Waiting for Review (Build 12, iOS + macOS)** — 已 Resubmit
> Apple 典型审核周期：24–48 小时

## 最近提交记录（按时间倒序）

| 日期 | 平台 | Build | 状态 | 备注 |
|------|------|-------|------|------|
| **2026-04-30 17:33 JST** | **iOS + macOS** | **1.0 (12)** | **Waiting for Review** | **修复 4/29 拒绝（2.1(a) + 5.1.1/5.1.2(i)），Reviewer Reply 已发** |
| 2026-04-29 | macOS | 1.0 (11) | Rejected | 2.1.0 App Completeness + 5.1.1 Privacy |
| 2026-04-27 | macOS | 1.0 (11) | Submitted（被 4/29 拒绝）|  |
| 2026-04-23 | macOS | 1.0 (8) | Rejected → fixed in 1.0(11) | 2.1(a) crash + 2.1 WeatherKit |

## App Store Connect 信息

- **App Name:** Kinen - AI Journal
- **Apple ID:** 6761919528
- **Bundle ID:** com.jasonye.kinen
- **SKU:** kinen-ai-journal
- **Team ID:** KHMK6Q3L3K
- **Platforms:** iOS + macOS
- **Version:** 0.1.0 (Build 1)
- **ASC URL:** https://appstoreconnect.apple.com/apps/6761919528/distribution/ios/version/inflight

## 提交状态

| 平台 | 版本 | Build | 状态 | 提交时间 |
|------|------|-------|------|---------|
| iOS | 1.0 | 0.1.0 (1) | Waiting for Review | 2026-04-10 17:17 |
| macOS | 1.0 | 0.1.0 (1) | Waiting for Review | 2026-04-10 17:24 |

## 已完成项目

### 代码 & 构建
- [x] Bundle ID `com.jasonye.kinen` 已注册
- [x] App icon alpha 通道已修复（去除透明背景）
- [x] macOS entitlements 添加 App Sandbox
- [x] iOS Archive + Upload 成功
- [x] macOS Archive + Upload 成功
- [x] Export Compliance: 两个平台都已设为 "None"

### App Store Connect 元数据
- [x] Promotional Text
- [x] Description (from appstore/description-en.txt)
- [x] Keywords
- [x] Support URL: https://jasonyeyuhe.github.io/Kinen/
- [x] Marketing URL: https://jasonyeyuhe.github.io/Kinen/
- [x] Copyright: 2026 Jason Ye
- [x] What's New in This Version

### App Information
- [x] Primary Category: Health & Fitness
- [x] Secondary Category: Lifestyle
- [x] Content Rights: No third-party content
- [x] Age Rating: 13+ (Medical/Treatment: Infrequent)
- [x] Regulated Medical Device: No

### App Privacy
- [x] Privacy Policy URL: https://jasonyeyuhe.github.io/Kinen/
- [x] Data Collection: Does not collect data (Published)

### Pricing & Availability
- [x] Price: Free ($0.00)
- [x] Availability: 175 countries/regions

### Screenshots
- [x] iPhone 6.5" (1284x2778): 8 张已上传
- [x] iPad 13" (2064x2752): 8 张已上传
- [x] macOS (2560x1600): 7 张已上传

### App Review Information
- [x] Contact: Yuhe Ye, +81 08035267088, yyyyy.yeyuhe@icloud.com
- [x] Sign-in required: No

## 项目文件位置

- 代码：`~/Documents/Kinen/`
- App Store 描述：`~/Documents/Kinen/appstore/description-en.txt`
- 中文描述：`~/Documents/Kinen/appstore/description-zh.txt`
- 关键词：`~/Documents/Kinen/appstore/keywords.txt`
- Screenshots：`~/Documents/Kinen/appstore/screenshots/`
  - iPhone: `ios/`
  - iPad: `ipad/`
  - macOS: `mac/`
- GitHub：https://github.com/JasonYeYuhe/Kinen
- Pages：https://jasonyeyuhe.github.io/Kinen/
- Archives：`~/Documents/Kinen/build/Kinen-iOS.xcarchive` + `Kinen-macOS.xcarchive`
- Build script：`~/Documents/Kinen/scripts/build-appstore.sh`
