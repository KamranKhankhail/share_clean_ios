import Foundation
enum AppConstants {
    static let appGroupID = "group.com.kivyx.shareclean"
    static func defaults() -> UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }
}
