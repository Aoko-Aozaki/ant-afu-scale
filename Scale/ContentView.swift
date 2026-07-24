import SwiftUI

struct ContentView: View {
    @StateObject private var ble = BluetoothManager()
    private let health = HealthKitManager()

    @State private var profile = UserProfile.load()
    @State private var showProfile = false
    @State private var healthMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusCard
                measurementCard
                Spacer()
                actionButton
            }
            .padding()
            .navigationTitle("体脂秤")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(profile: $profile)
            }
            .task {
                try? await health.requestAuthorization()
            }
            .onAppear {
                // 测到稳定值 → 写入健康
                ble.onMeasurementReady = { m in
                    Task { @MainActor in
                        do {
                            try await health.save(m)
                            healthMessage = "已同步到「健康」App"
                        } catch {
                            healthMessage = "同步失败：\(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }

    // MARK: - 状态
    private var statusCard: some View {
        VStack(spacing: 8) {
            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)
            if let w = ble.liveWeight, ble.lastMeasurement == nil {
                Text(String(format: "%.2f kg", w))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
            }
        }
    }

    private var statusText: String {
        switch ble.state {
        case .idle: return "按下按钮开始测量"
        case .poweredOff: return "请先打开手机蓝牙"
        case .scanning: return "正在寻找体脂秤…"
        case .connecting: return "连接中…"
        case .measuring: return "请站上秤，保持不动…"
        case .done: return "测量完成 ✅"
        case .bodyFatUnavailable(let hint): return "测不出体脂：\(hint)"
        case .error(let msg): return msg
        }
    }

    // MARK: - 结果
    @ViewBuilder private var measurementCard: some View {
        if let m = ble.lastMeasurement {
            VStack(spacing: 16) {
                Text(String(format: "%.2f kg", m.weightKg))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metric("体脂率", String(format: "%.1f%%", m.bodyFatPercent))
                    metric("BMI", String(format: "%.1f", m.bmi))
                    metric("水分率", String(format: "%.1f%%", m.waterPercent))
                    metric("肌肉率", String(format: "%.1f%%", m.muscleRate))
                    metric("基础代谢", "\(m.bmr) kcal")
                    metric("去脂体重", String(format: "%.1f kg", m.leanBodyMassKg))
                }
                if let healthMessage {
                    Text(healthMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text("体脂等为本地公式估算，仅供参考")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3).bold()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 按钮
    private var actionButton: some View {
        let measuring = ble.state == .scanning || ble.state == .connecting || ble.state == .measuring
        return Button {
            healthMessage = nil
            if measuring { ble.cancel() } else { ble.startMeasurement() }
        } label: {
            Text(measuring ? "取消" : "开始测量")
                .font(.title3).bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(measuring ? Color.red : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - 资料设置
struct ProfileView: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("身体资料（用于估算体脂）") {
                    Stepper("身高：\(Int(profile.heightCm)) cm",
                            value: $profile.heightCm, in: 80...230)
                    Stepper("年龄：\(profile.age) 岁",
                            value: $profile.age, in: 5...120)
                    Picker("性别", selection: $profile.isMale) {
                        Text("男").tag(true)
                        Text("女").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("我的资料")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        profile.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
