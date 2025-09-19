import Foundation
final class QuotaManager {
    static let shared = QuotaManager()
    private let key="autoRedacts", dayKey="autoRedactsDay", freePerDay=3
    func canAutoRedact(isPro: Bool) -> Bool {
        if isPro { return true }
        let today = Self.dayString(Date())
        let d = AppConstants.defaults().string(forKey: dayKey) ?? ""
        let c = AppConstants.defaults().integer(forKey: key)
        if d != today { return true }
        return c < freePerDay
    }
    func incrementAutoRedacts() {
        let today = Self.dayString(Date())
        let defaults = AppConstants.defaults()
        let d = defaults.string(forKey: dayKey) ?? ""
        if d != today { defaults.set(today, forKey: dayKey); defaults.set(1, forKey: key) }
        else { let c = defaults.integer(forKey: key); defaults.set(c+1, forKey: key) }
    }
    private static func dayString(_ date: Date)->String { let f=DateFormatter(); f.dateFormat="yyyy-MM-dd"; f.timeZone=TimeZone(secondsFromGMT:0); return f.string(from: date) }
}
