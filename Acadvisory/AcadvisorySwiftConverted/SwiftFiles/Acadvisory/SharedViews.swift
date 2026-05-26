import SwiftUI
import FirebaseAuth
import PhotosUI
import UIKit

struct AcadvisoryLogoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: -9) {
            Text("the")
                .font(.system(size: 42, weight: .light))
                .tracking(2)
                .foregroundStyle(.black)
            Text("ACADvisory")
                .font(.system(size: 44, weight: .black))
                .tracking(-2)
                .foregroundStyle(.black)
            Text("Stay updated with the latest announcements.")
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.435, green: 0.435, blue: 0.435))
                .padding(.top, 6)
        }
    }
}

struct AuthInputField: View {
    let placeholder: String
    @Binding var text: String
    var fillColor: Color
    var isSecure: Bool = false
    var hasShadow: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isEnabled: Bool = true

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 14))
        .disabled(!isEnabled)
        .padding(.horizontal, 32)
        .frame(height: 58)
        .background(fillColor)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: hasShadow ? .black.opacity(0.22) : .clear, radius: 6, x: 0, y: 4)
    }
}

struct AuthMessageView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.18), lineWidth: 1)
            )
    }
}

struct RoundedActionButton: View {
    let title: String
    let background: Color
    let foreground: Color
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .opacity(disabled ? 0.7 : 1)
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

struct BackCircleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 0.416, green: 0.416, blue: 0.416))
                .frame(width: 52, height: 52)
                .background(.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(red: 0.741, green: 0.741, blue: 0.741), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct BottomNavBar: View {
    @EnvironmentObject private var auth: AuthService

    enum ActiveItem {
        case home
        case calendar
        case newPost
        case profile
    }

    let active: ActiveItem

    private var thirdTabIcon: String {
        auth.isAdmin ? "bubble.left" : "bell"
    }

    private var thirdTabDestination: AnyView {
        if auth.isAdmin {
            return AnyView(NewAnnouncementView())
        }

        return AnyView(StudentNotificationTabView())
    }

    var body: some View {
        HStack {
            navItem(icon: "house.fill", item: .home, destination: AnyView(DashboardView()))
            navItem(icon: "calendar", item: .calendar, destination: AnyView(CalendarView()))
            navItem(icon: thirdTabIcon, item: .newPost, destination: thirdTabDestination)
            navItem(icon: "person", item: .profile, destination: AnyView(ProfileView()))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .padding(15)
    }

    @ViewBuilder
    private func navItem(icon: String, item: ActiveItem, destination: AnyView) -> some View {
        if active == item {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 42, height: 42)
                .background(.white)
                .clipShape(Circle())
                .frame(maxWidth: .infinity)
        } else {
            NavigationLink(destination: destination.navigationBarBackButtonHidden(true)) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.black)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }
}

struct StudentNotificationTabView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AnnouncementStore

    @State private var alertText = ""
    @State private var showAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderPlaceholderView()
                        .padding(.top, 34)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTIFICATIONS")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.black)

                        Text("Unread announcements: \(store.unreadAnnouncementCount)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.gray)
                    }

                    if store.unreadAnnouncementCount > 0 {
                        Button {
                            markAllAsRead()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(store.isMarkingNotification ? "Marking..." : "Mark all as read")
                            }
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.accentYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isMarkingNotification)
                    }

                    if store.announcements.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.gray)

                            Text("No announcements yet.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 70)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.announcements) { announcement in
                                NotificationAnnouncementCard(
                                    announcement: announcement,
                                    isRead: store.isAnnouncementRead(announcement.id),
                                    canMarkRead: true,
                                    isLoading: store.isMarkingNotification
                                ) {
                                    markAsRead(announcement)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 28)
            }
            .background(Color.white.ignoresSafeArea())

            BottomNavBar(active: .newPost)
        }
        .alert("ACADvisory", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertText)
        }
    }

    private func markAsRead(_ announcement: Announcement) {
        store.markAnnouncementAsRead(announcement: announcement, userId: auth.firebaseUser?.uid) { success, message in
            if !success {
                alertText = message ?? "Unable to mark this announcement as read."
                showAlert = true
            }
        }
    }

    private func markAllAsRead() {
        store.markAllAnnouncementsAsRead(userId: auth.firebaseUser?.uid) { success, message in
            if !success {
                alertText = message ?? "Unable to mark all announcements as read."
                showAlert = true
            }
        }
    }
}

struct HeaderPlaceholderView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AnnouncementStore
    @State private var showNotifications = false

    var body: some View {
        HStack {
            ProfilePhotoView(
                photoUrl: auth.appUser?.photoUrl ?? auth.firebaseUser?.photoURL?.absoluteString ?? "",
                photoBase64: auth.appUser?.photoBase64 ?? "",
                size: 40,
                cornerRadius: 10
            )
            Spacer()
            NotificationBellButton(
                unreadCount: auth.isAdmin ? 0 : store.unreadAnnouncementCount
            ) {
                showNotifications = true
            }
        }
        .sheet(isPresented: $showNotifications) {
            AnnouncementNotificationsView()
                .environmentObject(auth)
                .environmentObject(store)
        }
    }
}

struct NotificationBellButton: View {
    let unreadCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(.white)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "bell").foregroundStyle(.black))

                if unreadCount > 0 {
                    Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                        .font(.system(size: unreadCount > 99 ? 8 : 10, weight: .black))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .frame(minWidth: 18, minHeight: 18)
                        .padding(.horizontal, unreadCount > 9 ? 3 : 0)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Notifications")
    }
}

struct AnnouncementNotificationsView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AnnouncementStore
    @Environment(\.dismiss) private var dismiss

    @State private var alertText = ""
    @State private var showAlert = false

    private var unreadCount: Int {
        store.unreadAnnouncementCount
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                notificationsHeader

                if store.announcements.isEmpty {
                    emptyNotifications
                } else {
                    notificationsList
                }
            }
            .background(Color.white.ignoresSafeArea())
            .alert("ACADvisory", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertText)
            }
        }
    }

    private var notificationsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifications")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.black)

                    Text(auth.isAdmin ? "Latest announcement activity." : "Unread announcements: \(unreadCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.profileGray)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if !auth.isAdmin && unreadCount > 0 {
                Button {
                    markAllAsRead()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(store.isMarkingNotification ? "Marking..." : "Mark all as read")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(store.isMarkingNotification)
            }

            if let message = store.notificationMessage, !message.isEmpty {
                Text(message)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private var emptyNotifications: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.gray)

            Text("No announcements yet.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(store.announcements) { announcement in
                    NotificationAnnouncementCard(
                        announcement: announcement,
                        isRead: store.isAnnouncementRead(announcement.id),
                        canMarkRead: !auth.isAdmin,
                        isLoading: store.isMarkingNotification
                    ) {
                        markAsRead(announcement)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 4)
            .padding(.bottom, 30)
        }
    }

    private func markAsRead(_ announcement: Announcement) {
        store.markAnnouncementAsRead(announcement: announcement, userId: auth.firebaseUser?.uid) { success, message in
            if !success {
                alertText = message ?? "Unable to mark this announcement as read."
                showAlert = true
            }
        }
    }

    private func markAllAsRead() {
        store.markAllAnnouncementsAsRead(userId: auth.firebaseUser?.uid) { success, message in
            if !success {
                alertText = message ?? "Unable to mark all announcements as read."
                showAlert = true
            }
        }
    }
}

struct NotificationAnnouncementCard: View {
    let announcement: Announcement
    let isRead: Bool
    let canMarkRead: Bool
    let isLoading: Bool
    let markReadAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.categoryBackground(announcement.category))
                        .frame(width: 48, height: 48)

                    Image(systemName: AnnouncementCategory.from(announcement.category).iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.categoryStrong(announcement.category))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if !isRead {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }

                        Text(announcement.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .lineLimit(2)
                    }

                    Text(announcement.createdAt.acadvisoryLongString())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.gray)

                    Text(announcement.details.acadvisoryLimited(to: 90))
                        .font(.system(size: 11))
                        .foregroundStyle(.black.opacity(0.74))
                        .lineLimit(3)
                }

                Spacer()
            }

            if canMarkRead {
                Spacer().frame(height: 12)

                Button(action: markReadAction) {
                    HStack(spacing: 7) {
                        Image(systemName: isRead ? "checkmark.circle.fill" : "circle")
                        Text(isRead ? "Read" : "Tick as read")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isRead ? .gray : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isRead ? AppTheme.profileGray : AppTheme.accentYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(isRead || isLoading)
            }
        }
        .padding(14)
        .background(isRead ? AppTheme.profileGray.opacity(0.65) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isRead ? Color.gray.opacity(0.18) : AppTheme.accentYellow.opacity(0.85), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct ProfilePhotoView: View {
    let photoUrl: String
    let photoBase64: String
    let size: CGFloat
    let cornerRadius: CGFloat
    var personIconColor: Color = .black.opacity(0.52)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.28))

            if let image = base64Image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.45))
                            .foregroundStyle(personIconColor)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(personIconColor)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var base64Image: UIImage? {
        guard !photoBase64.isEmpty, let data = Data(base64Encoded: photoBase64) else { return nil }
        return UIImage(data: data)
    }
}

struct EditableProfilePhotoView: View {
    @EnvironmentObject private var auth: AuthService
    let photoUrl: String
    let photoBase64: String
    let size: CGFloat
    @State private var selectedItem: PhotosPickerItem?
    @State private var toastText: String?

    var body: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    ProfilePhotoView(
                        photoUrl: photoUrl,
                        photoBase64: photoBase64,
                        size: size,
                        cornerRadius: size / 2,
                        personIconColor: .white
                    )
                    .background(Color(red: 0.722, green: 0.722, blue: 0.722))
                    .clipShape(Circle())

                    ZStack {
                        Circle()
                            .fill(.black)
                            .frame(width: 38, height: 38)
                            .overlay(Circle().stroke(.white, lineWidth: 3))

                        if auth.isUploadingPhoto {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(auth.isUploadingPhoto)
            .onChange(of: selectedItem) { item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let compressed = image.acadvisoryCompressedProfileData() else {
                        toastText = "Unable to save profile picture. Please choose a smaller image."
                        return
                    }

                    auth.saveProfileImage(compressed) { success in
                        toastText = success ? "Profile picture saved." : "Unable to save profile picture. Please choose a smaller image."
                    }
                }
            }

            Text("Tap photo to choose")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(red: 0.416, green: 0.416, blue: 0.416))
        }
        .alert("ACADvisory", isPresented: Binding(get: { toastText != nil }, set: { if !$0 { toastText = nil } })) {
            Button("OK", role: .cancel) { toastText = nil }
        } message: {
            Text(toastText ?? "")
        }
    }
}

struct CategoryChip: View {
    let category: String
    var selected: Bool = false
    var smallText: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: AnnouncementCategory.from(category).iconName)
                    .font(.system(size: smallText ? 13 : 15, weight: .semibold))
                    .foregroundStyle(AppTheme.categoryStrong(category))
                Text(category)
                    .font(.system(size: smallText ? 8 : 11, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, smallText ? 8 : 10)
            .padding(.vertical, smallText ? 7 : 8)
            .background(AppTheme.categoryBackground(category))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? .black : .clear, lineWidth: 1.3)
            )
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
