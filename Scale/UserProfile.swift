import Foundation

/// 用户资料：体脂公式需要 身高 / 年龄 / 性别。存在本地 UserDefaults。
struct UserProfile: Codable, Equatable {
    var heightCm: Double = 172      // 身高（厘米）
    var age: Int = 25               // 年龄
    var isMale: Bool = true         // 性别：true=男 false=女

    static let storageKey = "user_profile"

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
