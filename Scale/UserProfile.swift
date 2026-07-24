import Foundation

/// 用户资料：体脂公式需要 身高 / 年龄 / 性别。存在本地 UserDefaults。
struct UserProfile: Codable, Equatable {
    var heightCm: Double = 172      // 身高（厘米）
    var age: Int = 25               // 年龄
    var isMale: Bool = true         // 性别：true=男 false=女
    var autoSyncHealth: Bool = true // 测量后自动写入「健康」App

    static let storageKey = "user_profile"

    init() {}

    // 容错解码：老版本存的资料没有 autoSyncHealth 字段，缺失时用默认值，避免整份资料被重置。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = UserProfile()
        heightCm = try c.decodeIfPresent(Double.self, forKey: .heightCm) ?? d.heightCm
        age = try c.decodeIfPresent(Int.self, forKey: .age) ?? d.age
        isMale = try c.decodeIfPresent(Bool.self, forKey: .isMale) ?? d.isMale
        autoSyncHealth = try c.decodeIfPresent(Bool.self, forKey: .autoSyncHealth) ?? d.autoSyncHealth
    }

    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return UserProfile() }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserProfile.storageKey)
        }
    }
}
