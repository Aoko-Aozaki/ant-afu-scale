<div align="center">

<img src="Scale/Assets.xcassets/AppIcon.appiconset/Scale_1024.png" width="128" alt="Scale App Icon" />

# Scale · 蚂蚁阿福体脂秤

一个原生 iOS App，直接通过蓝牙连接蚂蚁阿福体脂秤，读取体重与阻抗，本地估算身体成分，并同步到 Apple「健康」。

</div>

## 简介

Scale 是用 SwiftUI 写的 iOS 体脂秤 App。手机作为蓝牙中心设备直接与体脂秤通信，无需依赖原厂 App 或云端：

- 自动扫描并连接沃莱系列体脂秤（服务 UUID `FFB0`），并记住上次连过的秤下次直连。
- 连接后向秤下发用户资料（身高 / 年龄 / 性别），触发它做阻抗测量。
- 解析秤的 "Scale27" 蓝牙协议（体重包 / 阻抗包），实时显示体重、稳定后锁定读数。
- 基于阻抗 + 用户资料，本地用 BIA 公式估算体脂率、BMI、水分率、肌肉率、基础代谢、去脂体重。
- 测量完成后自动把体重、体脂率、BMI、去脂体重写入 Apple「健康」App。
- 对穿鞋、脚底有水等无法测出阻抗的情况给出针对性提示，而不是硬算一个假值。

> ⚠️ 体脂等身体成分为使用体脂秤提供的原始阻值以本地公式估算，与原厂 App 的计算公式不完全一致，仅供参考（反正都差不多准）。

## 运行截图

| 测量结果 | 我的资料 |
| :---: | :---: |
| <img src="readme.assets/IMG_2593.PNG" width="300" alt="测量结果" /> | <img src="readme.assets/IMG_2592.PNG" width="300" alt="我的资料" /> |

## 项目结构

| 文件 | 作用 |
| --- | --- |
| [ContentView.swift](Scale/ContentView.swift) | 主界面：测量状态、结果卡片、资料设置页 |
| [BluetoothManager.swift](Scale/BluetoothManager.swift) | CoreBluetooth：扫描 / 连接 / 订阅通知 / 下发资料 / 稳定判定 |
| [Scale27.swift](Scale/Scale27.swift) | 沃莱 "Scale27" 蓝牙协议的编解码 |
| [BodyComposition.swift](Scale/BodyComposition.swift) | 阻抗 + 资料 → 身体成分的 BIA 估算公式 |
| [HealthKitManager.swift](Scale/HealthKitManager.swift) | 把测量结果写入 Apple「健康」 |
| [UserProfile.swift](Scale/UserProfile.swift) | 身高 / 年龄 / 性别，存本地 UserDefaults |

## 环境要求

- iOS 真机（模拟器没有蓝牙，无法连接体脂秤）
- Xcode，Swift + SwiftUI
- 支持沃莱 / 蚂蚁阿福芯片的体脂秤（服务 UUID `FFB0`）
- 首次运行需授予蓝牙权限；写入健康数据需授予「健康」写入权限
  
- 自签名的应用有效期为7天，建议去闲鱼花几块钱找人用开发者账号代签名

## 参考项目：ant-afu-welland-scale

本项目的蓝牙协议与估算逻辑参考了 [`ant-afu-welland-scale`](https://github.com/Mzdyl/ant-afu-welland-scale) —— 一个用 Python 写的 macOS 命令行读秤工具。Scale 把它的核心算法移植成了 Swift，具体借鉴的部分：

- **"Scale27" 蓝牙协议解析**：[Scale27.swift](Scale/Scale27.swift) 移植自其 `protocol.py`，包括 20 字节数据包的包头 / 包类型判定、体重编码的取整与刻度换算（`gunit`）、阻抗归一化，以及下发时间 + 用户资料（`encode_time_and_user_info_27`）以触发体脂测量的逻辑。
- **身体成分估算公式**：[BodyComposition.swift](Scale/BodyComposition.swift) 的 BIA 公式源自其使用的 `ha-miscale2` 算法，用体重、阻抗、身高、年龄、性别估算体脂率、水分、骨量、肌肉率等。
  

区别在于：`ant-afu-welland-scale` 是 macOS 上跑的 Python CLI，而 Scale 是 iOS 原生 App（靠 CoreBluetooth + SwiftUI），并额外接入了 Apple「健康」。参考项目自身的用法请见其仓库：<https://github.com/Mzdyl/ant-afu-welland-scale>。
