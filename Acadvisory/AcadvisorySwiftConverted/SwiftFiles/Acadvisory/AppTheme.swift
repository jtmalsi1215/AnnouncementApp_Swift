import SwiftUI

struct AppTheme {
    static let accentYellow = Color(red: 1.0, green: 0.824, blue: 0.298)
    static let softYellow = Color(red: 1.0, green: 0.945, blue: 0.784)
    static let formGray = Color(red: 0.937, green: 0.937, blue: 0.937)
    static let profileGray = Color(red: 0.898, green: 0.898, blue: 0.898)

    static func categoryBackground(_ category: String) -> Color {
        switch AnnouncementCategory.from(category) {
        case .academics:
            return Color.blue.opacity(0.18)
        case .events:
            return Color.purple.opacity(0.18)
        case .urgent:
            return Color.red.opacity(0.18)
        case .organization:
            return Color.orange.opacity(0.20)
        case .campusUpdates:
            return Color.green.opacity(0.20)
        }
    }

    static func categoryStrong(_ category: String) -> Color {
        switch AnnouncementCategory.from(category) {
        case .academics:
            return .blue
        case .events:
            return .purple
        case .urgent:
            return .red
        case .organization:
            return .orange
        case .campusUpdates:
            return .green
        }
    }
}

extension Date {
    func acadvisoryLongString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy   h:mm a"
        return formatter.string(from: self)
    }

    func acadvisoryDateKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    func acadvisoryDateOnlyString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }

    func acadvisoryTimeOnlyString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    func acadvisoryEventDateTimeString() -> String {
        "\(acadvisoryDateOnlyString()) - \(acadvisoryTimeOnlyString())"
    }

    func acadvisoryMonthShort() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"
        return formatter.string(from: self).uppercased()
    }
}

extension String {
    func acadvisoryLimited(to count: Int = 34) -> String {
        guard self.count > count else { return self }
        let endIndex = self.index(self.startIndex, offsetBy: count)
        return String(self[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
