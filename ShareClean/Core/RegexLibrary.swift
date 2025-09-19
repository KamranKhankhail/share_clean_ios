import Foundation

struct RegexLibrary {
    static let email: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.caseInsensitive])
        } catch {
            fatalError("Failed to create email regex: \(error)")
        }
    }()
    
    static let phone: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: #"(?:(?:\+|00)\d{1,3}[\s-]?)?(?:\(?\d{2,4}\)?[\s-]?)?\d{3,4}[\s-]?\d{3,4}"#, options: [])
        } catch {
            fatalError("Failed to create phone regex: \(error)")
        }
    }()
    
    static let amount: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: #"(?:[$€£¥₹]|USD|EUR|GBP|JPY|INR)\s?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?"#, options: [.caseInsensitive])
        } catch {
            fatalError("Failed to create amount regex: \(error)")
        }
    }()
    
    static let idcode: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: #"\b[A-Z0-9]{6,8}\b"#, options: [])
        } catch {
            fatalError("Failed to create idcode regex: \(error)")
        }
    }()
    
    static func matchesPII(in text: String, settings: DetectionSettings) -> [PIIType] {
        var out: [PIIType] = []
        guard !text.isEmpty else { return out }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if settings.detectEmails && email.firstMatch(in: text, options: [], range: range) != nil { 
            out.append(.email) 
        }
        if settings.detectPhones && phone.firstMatch(in: text, options: [], range: range) != nil { 
            out.append(.phone) 
        }
        if settings.detectAmounts && amount.firstMatch(in: text, options: [], range: range) != nil { 
            out.append(.amount) 
        }
        if settings.detectIDs && idcode.firstMatch(in: text, options: [], range: range) != nil { 
            out.append(.idcode) 
        }
        return out
    }
}
