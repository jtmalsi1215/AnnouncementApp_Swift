import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Equatable {
    let id: String
    let uid: String
    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var role: String
    var photoUrl: String
    var photoBase64: String

    init(uid: String, data: [String: Any]) {
        self.id = uid
        self.uid = uid
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.role = data["role"] as? String ?? "Student"
        self.photoUrl = data["photoUrl"] as? String ?? ""
        self.photoBase64 = data["photoBase64"] as? String ?? ""
    }

    var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? email : name
    }

    var displayNameUppercase: String {
        fullName.isEmpty ? "USER" : fullName.uppercased()
    }

    var firstNameUppercase: String {
        if !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return firstName.uppercased()
        }

        if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fullName.components(separatedBy: " ").first?.uppercased() ?? "USER"
        }

        return email.components(separatedBy: "@").first?.uppercased() ?? "USER"
    }
}

struct Announcement: Identifiable, Equatable {
    let id: String
    var title: String
    var details: String
    var category: String
    var createdAt: Date
    var eventDateTime: Date?

    init(id: String, data: [String: Any]) {
        self.id = id
        self.title = data["title"] as? String ?? "No title"
        self.details = data["details"] as? String ?? "No details"
        self.category = data["category"] as? String ?? data["type"] as? String ?? "Events"

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }

        if let timestamp = data["eventDateTime"] as? Timestamp {
            self.eventDateTime = timestamp.dateValue()
        } else if let timestamp = data["eventAt"] as? Timestamp {
            self.eventDateTime = timestamp.dateValue()
        } else {
            self.eventDateTime = nil
        }
    }

    var calendarDate: Date {
        createdAt
    }

    var eventDateText: String {
        eventDateTime?.acadvisoryDateOnlyString() ?? "No event date set"
    }

    var eventTimeText: String {
        eventDateTime?.acadvisoryTimeOnlyString() ?? "No event time set"
    }

    var eventDateTimeText: String {
        eventDateTime?.acadvisoryEventDateTimeString() ?? "No event date and time set"
    }
}

struct AnnouncementHistory: Identifiable, Equatable {
    let id: String
    var announcementId: String
    var action: String
    var title: String
    var details: String
    var category: String
    var oldTitle: String
    var newTitle: String
    var oldDetails: String
    var newDetails: String
    var oldCategory: String
    var newCategory: String
    var eventDateTime: Date?
    var oldEventDateTime: Date?
    var newEventDateTime: Date?
    var actorName: String
    var actorRole: String
    var createdAt: Date

    init(id: String, data: [String: Any]) {
        self.id = id
        self.announcementId = data["announcementId"] as? String ?? ""
        self.action = data["action"] as? String ?? "updated"
        self.title = data["title"] as? String ?? "No title"
        self.details = data["details"] as? String ?? ""
        self.category = data["category"] as? String ?? "Events"
        self.oldTitle = data["oldTitle"] as? String ?? ""
        self.newTitle = data["newTitle"] as? String ?? ""
        self.oldDetails = data["oldDetails"] as? String ?? ""
        self.newDetails = data["newDetails"] as? String ?? ""
        self.oldCategory = data["oldCategory"] as? String ?? ""
        self.newCategory = data["newCategory"] as? String ?? ""

        if let timestamp = data["eventDateTime"] as? Timestamp {
            self.eventDateTime = timestamp.dateValue()
        } else {
            self.eventDateTime = nil
        }

        if let timestamp = data["oldEventDateTime"] as? Timestamp {
            self.oldEventDateTime = timestamp.dateValue()
        } else {
            self.oldEventDateTime = nil
        }

        if let timestamp = data["newEventDateTime"] as? Timestamp {
            self.newEventDateTime = timestamp.dateValue()
        } else {
            self.newEventDateTime = nil
        }

        self.actorName = data["actorName"] as? String ?? "Admin"
        self.actorRole = data["actorRole"] as? String ?? "Admin"

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
    }

    var eventDateTimeText: String {
        eventDateTime?.acadvisoryEventDateTimeString() ?? "No event date and time set"
    }

    var oldEventDateTimeText: String {
        oldEventDateTime?.acadvisoryEventDateTimeString() ?? "No event date and time set"
    }

    var newEventDateTimeText: String {
        newEventDateTime?.acadvisoryEventDateTimeString() ?? "No event date and time set"
    }

    var actionLabel: String {
        switch action.lowercased() {
        case "edited", "updated":
            return "EDITED"
        case "deleted":
            return "DELETED"
        case "created", "published":
            return "PUBLISHED"
        default:
            return action.uppercased()
        }
    }

    var actionIcon: String {
        switch action.lowercased() {
        case "edited", "updated":
            return "pencil"
        case "deleted":
            return "trash"
        case "created", "published":
            return "plus"
        default:
            return "clock.arrow.circlepath"
        }
    }
}

enum AnnouncementCategory: String, CaseIterable, Identifiable {
    case academics = "Academics"
    case events = "Events"
    case urgent = "Urgent"
    case organization = "Organization"
    case campusUpdates = "Campus Updates"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .academics:
            return "graduationcap.fill"
        case .events:
            return "calendar"
        case .urgent:
            return "exclamationmark.triangle.fill"
        case .organization:
            return "person.3.fill"
        case .campusUpdates:
            return "megaphone.fill"
        }
    }

    static func from(_ value: String) -> AnnouncementCategory {
        AnnouncementCategory(rawValue: value) ?? .events
    }
}
