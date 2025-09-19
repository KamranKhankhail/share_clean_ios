import Foundation

struct RegexLibrary {
    static let email = try! NSRegularExpression(pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.caseInsensitive])
    static let phone = try! NSRegularExpression(pattern: #"(?:(?:\+|00)\d{1,3}[\s-]?)?(?:\(?\d{2,4}\)?[\s-]?)?\d{3,4}[\s-]?\d{3,4}"#, options: [])
    static let amount = try! NSRegularExpression(pattern: #"(?:[$€£¥₹]|USD|EUR|GBP|JPY|INR)\s?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?"#, options: [.caseInsensitive])
    static let idcode = try! NSRegularExpression(pattern: #"\b[A-Z0-9]{6,8}\b"#, options: [])
    static func matchesPII(in text: String, settings: DetectionSettings) -> [PIIType] {
        var out: [PIIType] = []
        if settings.detectEmails && email.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil { out.append(.email) }
        if settings.detectPhones && phone.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil { out.append(.phone) }
        if settings.detectAmounts && amount.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil { out.append(.amount) }
        if settings.detectIDs && idcode.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil { out.append(.idcode) }
        return out
    }
}
