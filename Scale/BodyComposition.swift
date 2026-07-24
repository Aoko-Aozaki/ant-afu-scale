import Foundation

/// 一次测量的结果。
struct Measurement: Identifiable {
    let id = UUID()
    let date: Date
    let weightKg: Double
    let impedance: Double     // 阻抗 Ω
    let bmi: Double
    let bodyFatPercent: Double
    let waterPercent: Double
    let muscleRate: Double
    let bmr: Int              // 基础代谢
    let leanBodyMassKg: Double // 去脂体重
}

/// 体脂等身体成分的本地估算（BIA 公式）。
/// 公式移植自 icomon_scale 项目（源自 ha-miscale2），秤本身只提供体重和阻抗。
/// 这是估算值，和原厂 App 不会完全一致，属正常现象。
enum BodyComposition {

    static func calculate(weightKg weight: Double,
                          impedance rawImpedance: Double,
                          profile: UserProfile) -> Measurement {
        let h = profile.heightCm
        let age = Double(profile.age)
        let isMale = profile.isMale
        // 阻抗为 0 时给个中间默认值，避免公式异常
        let impedance = rawImpedance > 0 ? rawImpedance : 500.0

        let bmi = weight / pow(h / 100.0, 2)

        // 瘦体重系数 (LBM coefficient)
        let lbmCoeff = (h * 9.058 / 100.0) * (h / 100.0)
            + weight * 0.32 + 12.226
            - impedance * 0.0068
            - age * 0.0542

        // 体脂率
        var fatConst: Double
        var fatCoeff: Double = 1.0
        if isMale {
            fatConst = 0.8
            if weight < 61 { fatCoeff = 0.98 }
            if h > 160 { fatCoeff *= 1.03 }
        } else {
            fatConst = age <= 49 ? 9.25 : 7.25
            if weight > 60 { fatCoeff = 0.96 }
            else if weight < 50 { fatCoeff = 1.02 }
            if h > 160 { fatCoeff *= 1.03 }
        }
        var fatPct = (1.0 - (((lbmCoeff - fatConst) * fatCoeff) / weight)) * 100.0
        fatPct = min(60.0, max(3.0, fatPct))

        // 水分率
        var waterPct = (100.0 - fatPct) * 0.7
        let waterCoeff = waterPct <= 50 ? 1.02 : 0.98
        waterPct = min(75.0, max(35.0, waterPct * waterCoeff))

        // 骨量 -> 骨率
        var boneMass: Double
        if isMale {
            boneMass = (0.18016894 - (lbmCoeff * 0.05158)) * -1
        } else {
            boneMass = (0.245691014 - (lbmCoeff * 0.07158)) * -1
        }
        boneMass += boneMass > 2.2 ? 0.1 : -0.1
        boneMass = max(0.5, boneMass)

        // 肌肉
        let fatMass = fatPct * 0.01 * weight
        let muscleMass = weight - fatMass - boneMass * 0.85
        let muscleRate = muscleMass / weight * 100.0

        // 基础代谢 (Mifflin-St Jeor)
        let bmr: Int
        if isMale {
            bmr = Int((10 * weight + 6.25 * h - 5 * age + 5).rounded())
        } else {
            bmr = Int((10 * weight + 6.25 * h - 5 * age - 161).rounded())
        }

        let leanBodyMass = weight - fatMass

        return Measurement(
            date: Date(),
            weightKg: (weight * 100).rounded() / 100,
            impedance: (impedance * 10).rounded() / 10,
            bmi: (bmi * 10).rounded() / 10,
            bodyFatPercent: (fatPct * 10).rounded() / 10,
            waterPercent: (waterPct * 10).rounded() / 10,
            muscleRate: (muscleRate * 10).rounded() / 10,
            bmr: bmr,
            leanBodyMassKg: (leanBodyMass * 10).rounded() / 10
        )
    }
}
