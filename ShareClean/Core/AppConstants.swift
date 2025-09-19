import Foundation
enum AppConstants {
    static let appGroupID = "group.com.yourcompany.shareclean"
    static func defaults() -> UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }
}
