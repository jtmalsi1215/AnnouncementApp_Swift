import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import UIKit

@MainActor
final class AuthService: ObservableObject {
    @Published var firebaseUser: User?
    @Published var appUser: AppUser?
    @Published var isCheckingAuth = true
    @Published var isAuthLoading = false
    @Published var authMessage: String?
    @Published var profileMessage: String?
    @Published var isSavingProfile = false
    @Published var isUploadingPhoto = false

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }
                self.firebaseUser = user
                self.isCheckingAuth = false
                self.listenToUserDocument(user)
            }
        }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        userListener?.remove()
    }

    var isAdmin: Bool {
        (appUser?.role ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "admin"
    }

    var currentActorName: String {
        if let appUser { return appUser.fullName }
        if let name = firebaseUser?.displayName, !name.isEmpty { return name }
        return firebaseUser?.email ?? "Admin"
    }

    var currentActorRole: String {
        appUser?.role ?? "Admin"
    }

    private func listenToUserDocument(_ user: User?) {
        userListener?.remove()
        appUser = nil

        guard let user else { return }

        userListener = db.collection("users").document(user.uid).addSnapshotListener { [weak self] snapshot, _ in
            Task { @MainActor in
                guard let self else { return }

                if let data = snapshot?.data() {
                    self.appUser = AppUser(uid: user.uid, data: data)
                } else {
                    self.appUser = AppUser(uid: user.uid, data: [
                        "uid": user.uid,
                        "firstName": user.displayName?.components(separatedBy: " ").first ?? "",
                        "lastName": "",
                        "username": "",
                        "email": user.email ?? "",
                        "role": "Student",
                        "photoUrl": user.photoURL?.absoluteString ?? "",
                        "photoBase64": ""
                    ])
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            authMessage = "Please enter your email and password."
            return
        }

        isAuthLoading = true
        authMessage = nil

        Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword) { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthLoading = false

                if let error {
                    self.authMessage = self.friendlyAuthMessage(error)
                }
            }
        }
    }

    func signUp(firstName: String, lastName: String, username: String, email: String, password: String) {
        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanFirstName.isEmpty, !cleanLastName.isEmpty, !cleanUsername.isEmpty, !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            authMessage = "Please complete all sign up fields."
            return
        }

        guard cleanPassword.count >= 6 else {
            authMessage = "Password must be at least 6 characters."
            return
        }

        isAuthLoading = true
        authMessage = nil

        Auth.auth().createUser(withEmail: cleanEmail, password: cleanPassword) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.isAuthLoading = false
                    self.authMessage = self.friendlyAuthMessage(error)
                    return
                }

                guard let user = result?.user else {
                    self.isAuthLoading = false
                    self.authMessage = "Something went wrong. Please try again."
                    return
                }

                let fullName = "\(cleanFirstName) \(cleanLastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                let profileChange = user.createProfileChangeRequest()
                profileChange.displayName = fullName
                profileChange.commitChanges(completion: nil)

                self.db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "firstName": cleanFirstName,
                    "lastName": cleanLastName,
                    "username": cleanUsername,
                    "email": cleanEmail,
                    "role": "Student",
                    "photoUrl": "",
                    "photoBase64": "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true) { firestoreError in
                    Task { @MainActor in
                        self.isAuthLoading = false

                        if let firestoreError {
                            self.authMessage = firestoreError.localizedDescription
                        }
                    }
                }
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            authMessage = nil
            profileMessage = nil
        } catch {
            profileMessage = error.localizedDescription
        }
    }

    func saveProfile(firstName: String, lastName: String, username: String, email: String, onSuccess: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            profileMessage = "No logged in user."
            return
        }

        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanFirstName.isEmpty, !cleanLastName.isEmpty, !cleanUsername.isEmpty, !cleanEmail.isEmpty else {
            profileMessage = "Please complete all profile fields."
            return
        }

        isSavingProfile = true
        profileMessage = nil

        let fullName = "\(cleanFirstName) \(cleanLastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        let profileChange = user.createProfileChangeRequest()
        profileChange.displayName = fullName
        profileChange.commitChanges(completion: nil)

        let finishFirestoreSave = { [weak self] in
            guard let self else { return }
            self.db.collection("users").document(user.uid).setData([
                "uid": user.uid,
                "firstName": cleanFirstName,
                "lastName": cleanLastName,
                "username": cleanUsername,
                "email": cleanEmail,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                Task { @MainActor in
                    self.isSavingProfile = false

                    if let error {
                        self.profileMessage = error.localizedDescription
                    } else {
                        self.profileMessage = nil
                        onSuccess()
                    }
                }
            }
        }

        let currentEmail = user.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if cleanEmail != currentEmail {
            user.sendEmailVerification(beforeUpdatingEmail: cleanEmail) { [weak self] error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.isSavingProfile = false
                        self.profileMessage = self.friendlyAuthMessage(error)
                    } else {
                        finishFirestoreSave()
                    }
                }
            }
        } else {
            finishFirestoreSave()
        }
    }

    func saveProfileImage(_ imageData: Data, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        isUploadingPhoto = true
        let photoBase64 = imageData.base64EncodedString()

        db.collection("users").document(uid).setData([
            "photoBase64": photoBase64,
            "photoUrl": "",
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] error in
            Task { @MainActor in
                self?.isUploadingPhoto = false
                completion(error == nil)
            }
        }
    }

    private func friendlyAuthMessage(_ error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch code {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .userDisabled:
            return "This account has been disabled."
        case .userNotFound, .wrongPassword, .invalidCredential:
            return "Incorrect email or password."
        case .emailAlreadyInUse:
            return "This email already has an account."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .networkError:
            return "Please check your internet connection."
        case .requiresRecentLogin:
            return "Please logout, login again, then update your email."
        default:
            return error.localizedDescription
        }
    }
}

@MainActor
final class AnnouncementStore: ObservableObject {
    @Published var announcements: [Announcement] = []
    @Published var announcementHistory: [AnnouncementHistory] = []
    @Published var readAnnouncementIds: Set<String> = []
    @Published var isMarkingNotification = false
    @Published var notificationMessage: String?
    @Published var isPublishing = false
    @Published var isSavingAnnouncement = false
    @Published var isDeletingAnnouncement = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var historyListener: ListenerRegistration?
    private var readAnnouncementsListener: ListenerRegistration?

    var unreadAnnouncementCount: Int {
        announcements.filter { !readAnnouncementIds.contains($0.id) }.count
    }

    init() {
        listener = db.collection("announcements")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.errorMessage = nil
                    self.announcements = snapshot?.documents.map { document in
                        Announcement(id: document.documentID, data: document.data())
                    } ?? []
                }
            }

        historyListener = db.collection("announcement_history")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.announcementHistory = snapshot?.documents.map { document in
                        AnnouncementHistory(id: document.documentID, data: document.data())
                    } ?? []
                }
            }
    }

    deinit {
        listener?.remove()
        historyListener?.remove()
        readAnnouncementsListener?.remove()
    }

    func listenToReadAnnouncements(for userId: String?) {
        readAnnouncementsListener?.remove()
        readAnnouncementIds = []
        notificationMessage = nil

        guard let userId, !userId.isEmpty else { return }

        readAnnouncementsListener = db.collection("users")
            .document(userId)
            .collection("read_announcements")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.notificationMessage = error.localizedDescription
                        return
                    }

                    self.notificationMessage = nil
                    self.readAnnouncementIds = Set(snapshot?.documents.map { $0.documentID } ?? [])
                }
            }
    }

    func isAnnouncementRead(_ announcementId: String) -> Bool {
        readAnnouncementIds.contains(announcementId)
    }

    func markAnnouncementAsRead(announcement: Announcement, userId: String?, completion: @escaping (Bool, String?) -> Void) {
        guard let userId, !userId.isEmpty else {
            completion(false, "Please login again before marking notifications as read.")
            return
        }

        isMarkingNotification = true
        notificationMessage = nil

        db.collection("users")
            .document(userId)
            .collection("read_announcements")
            .document(announcement.id)
            .setData([
                "announcementId": announcement.id,
                "title": announcement.title,
                "category": announcement.category,
                "readAt": FieldValue.serverTimestamp()
            ], merge: true) { [weak self] error in
                Task { @MainActor in
                    self?.isMarkingNotification = false

                    if let error {
                        self?.notificationMessage = error.localizedDescription
                        completion(false, error.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
            }
    }

    func markAllAnnouncementsAsRead(userId: String?, completion: @escaping (Bool, String?) -> Void) {
        guard let userId, !userId.isEmpty else {
            completion(false, "Please login again before marking notifications as read.")
            return
        }

        guard !announcements.isEmpty else {
            completion(true, nil)
            return
        }

        isMarkingNotification = true
        notificationMessage = nil

        let batch = db.batch()
        let userReadCollection = db.collection("users")
            .document(userId)
            .collection("read_announcements")

        for announcement in announcements {
            let reference = userReadCollection.document(announcement.id)
            batch.setData([
                "announcementId": announcement.id,
                "title": announcement.title,
                "category": announcement.category,
                "readAt": FieldValue.serverTimestamp()
            ], forDocument: reference, merge: true)
        }

        batch.commit { [weak self] error in
            Task { @MainActor in
                self?.isMarkingNotification = false

                if let error {
                    self?.notificationMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    func publishAnnouncement(title: String, details: String, category: String, eventDateTime: Date, completion: @escaping (Bool, String?) -> Void) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, !cleanDetails.isEmpty else {
            completion(false, "Please fill out the title and details.")
            return
        }

        isPublishing = true

        db.collection("announcements").addDocument(data: [
            "title": cleanTitle,
            "details": cleanDetails,
            "category": category,
            "eventDateTime": Timestamp(date: eventDateTime),
            "eventDate": eventDateTime.acadvisoryDateOnlyString(),
            "eventTime": eventDateTime.acadvisoryTimeOnlyString(),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            Task { @MainActor in
                self?.isPublishing = false

                if let error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    func updateAnnouncement(
        announcement: Announcement,
        title: String,
        details: String,
        category: String,
        eventDateTime: Date,
        actorName: String,
        actorRole: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, !cleanDetails.isEmpty else {
            completion(false, "Please fill out the title and details.")
            return
        }

        isSavingAnnouncement = true

        db.collection("announcements").document(announcement.id).updateData([
            "title": cleanTitle,
            "details": cleanDetails,
            "category": category,
            "eventDateTime": Timestamp(date: eventDateTime),
            "eventDate": eventDateTime.acadvisoryDateOnlyString(),
            "eventTime": eventDateTime.acadvisoryTimeOnlyString(),
            "updatedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            guard let self else { return }

            if let error {
                Task { @MainActor in
                    self.isSavingAnnouncement = false
                    completion(false, error.localizedDescription)
                }
                return
            }

            Task { @MainActor in
                self.addAnnouncementHistory(
                    action: "edited",
                    announcementId: announcement.id,
                    title: cleanTitle,
                    details: cleanDetails,
                    category: category,
                    eventDateTime: eventDateTime,
                    oldEventDateTime: announcement.eventDateTime,
                    newEventDateTime: eventDateTime,
                    oldTitle: announcement.title,
                    newTitle: cleanTitle,
                    oldDetails: announcement.details,
                    newDetails: cleanDetails,
                    oldCategory: announcement.category,
                    newCategory: category,
                    actorName: actorName,
                    actorRole: actorRole
                ) { historyError in
                    Task { @MainActor in
                        self.isSavingAnnouncement = false

                        if let historyError {
                            completion(false, "Announcement was updated, but history was not saved: \(historyError.localizedDescription)")
                        } else {
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }

    func deleteAnnouncement(
        announcement: Announcement,
        actorName: String,
        actorRole: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        isDeletingAnnouncement = true

        db.collection("announcements").document(announcement.id).delete { [weak self] error in
            guard let self else { return }

            if let error {
                Task { @MainActor in
                    self.isDeletingAnnouncement = false
                    completion(false, error.localizedDescription)
                }
                return
            }

            Task { @MainActor in
                self.addAnnouncementHistory(
                    action: "deleted",
                    announcementId: announcement.id,
                    title: announcement.title,
                    details: announcement.details,
                    category: announcement.category,
                    eventDateTime: announcement.eventDateTime,
                    oldEventDateTime: announcement.eventDateTime,
                    newEventDateTime: nil,
                    oldTitle: announcement.title,
                    newTitle: "",
                    oldDetails: announcement.details,
                    newDetails: "",
                    oldCategory: announcement.category,
                    newCategory: "",
                    actorName: actorName,
                    actorRole: actorRole
                ) { historyError in
                    Task { @MainActor in
                        self.isDeletingAnnouncement = false

                        if let historyError {
                            completion(false, "Announcement was deleted, but history was not saved: \(historyError.localizedDescription)")
                        } else {
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }

    private func addAnnouncementHistory(
        action: String,
        announcementId: String,
        title: String,
        details: String,
        category: String,
        eventDateTime: Date?,
        oldEventDateTime: Date?,
        newEventDateTime: Date?,
        oldTitle: String,
        newTitle: String,
        oldDetails: String,
        newDetails: String,
        oldCategory: String,
        newCategory: String,
        actorName: String,
        actorRole: String,
        completion: @escaping (Error?) -> Void
    ) {
        var historyData: [String: Any] = [
            "action": action,
            "announcementId": announcementId,
            "title": title,
            "details": details,
            "category": category,
            "oldTitle": oldTitle,
            "newTitle": newTitle,
            "oldDetails": oldDetails,
            "newDetails": newDetails,
            "oldCategory": oldCategory,
            "newCategory": newCategory,
            "actorName": actorName,
            "actorRole": actorRole,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let eventDateTime {
            historyData["eventDateTime"] = Timestamp(date: eventDateTime)
        }

        if let oldEventDateTime {
            historyData["oldEventDateTime"] = Timestamp(date: oldEventDateTime)
        }

        if let newEventDateTime {
            historyData["newEventDateTime"] = Timestamp(date: newEventDateTime)
        }

        db.collection("announcement_history").addDocument(data: historyData) { error in
            completion(error)
        }
    }
}

extension UIImage {
    func acadvisoryCompressedProfileData(maxDimension: CGFloat = 300, compressionQuality: CGFloat = 0.35) -> Data? {
        let largestSide = max(size.width, size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
}
