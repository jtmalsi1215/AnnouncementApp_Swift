import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    private var displayName: String {
        if let appUser = auth.appUser { return appUser.displayNameUppercase }
        if let name = auth.firebaseUser?.displayName, !name.isEmpty { return name.uppercased() }
        return auth.firebaseUser?.email?.uppercased() ?? "USER"
    }

    private var role: String {
        (auth.appUser?.role ?? "Student").uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    BackCircleButton { dismiss() }

                    Spacer().frame(height: 26)

                    HStack {
                        ProfilePill(text: "PROFILE", color: AppTheme.accentYellow)
                        Spacer()
                        NavigationLink(destination: EditProfileView().navigationBarBackButtonHidden(true)) {
                            ProfilePill(text: "EDIT PROFILE", color: AppTheme.softYellow)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 16)

                    VStack(spacing: 0) {
                        EditableProfilePhotoView(
                            photoUrl: auth.appUser?.photoUrl ?? auth.firebaseUser?.photoURL?.absoluteString ?? "",
                            photoBase64: auth.appUser?.photoBase64 ?? "",
                            size: 156
                        )

                        Spacer().frame(height: 14)

                        Text(displayName)
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 2)

                        Text(role)
                            .font(.system(size: 17))
                            .foregroundStyle(.black.opacity(0.87))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .background(AppTheme.profileGray)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    Spacer().frame(height: 14)

                    ProfileMenuItem(text: "Language")
                    Spacer().frame(height: 6)
                    ProfileNavigationMenuItem(text: "History", destination: AnyView(AnnouncementHistoryView()))
                    Spacer().frame(height: 6)
                    ProfileMenuItem(text: "Change Password")
                    Spacer().frame(height: 28)
                    ProfileMenuItem(text: "Help")
                    Spacer().frame(height: 6)
                    ProfileMenuItem(text: "Change User")
                    Spacer().frame(height: 6)
                    ProfileMenuItem(text: "Logout") {
                        auth.logout()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 120)
            }

            BottomNavBar(active: .profile)
                .padding(.top, 0)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var didLoad = false
    @State private var showSavedAlert = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    BackCircleButton { dismiss() }

                    Spacer().frame(height: 26)

                    HStack {
                        ProfilePill(text: "EDIT PROFILE", color: AppTheme.accentYellow)
                        Spacer()
                        ProfilePill(text: "PROFILE", color: AppTheme.softYellow)
                    }

                    Spacer().frame(height: 16)

                    VStack(spacing: 0) {
                        EditableProfilePhotoView(
                            photoUrl: auth.appUser?.photoUrl ?? auth.firebaseUser?.photoURL?.absoluteString ?? "",
                            photoBase64: auth.appUser?.photoBase64 ?? "",
                            size: 116
                        )

                        Spacer().frame(height: 22)

                        EditProfileTextField(label: "First Name", text: $firstName, isEnabled: !auth.isSavingProfile)
                        Spacer().frame(height: 12)
                        EditProfileTextField(label: "Last Name", text: $lastName, isEnabled: !auth.isSavingProfile)
                        Spacer().frame(height: 12)
                        EditProfileTextField(label: "Username", text: $username, isEnabled: !auth.isSavingProfile)
                        Spacer().frame(height: 12)
                        EditProfileTextField(label: "Email", text: $email, keyboardType: .emailAddress, isEnabled: !auth.isSavingProfile)

                        if let message = auth.profileMessage {
                            Spacer().frame(height: 14)
                            AuthMessageView(text: message)
                        }

                        Spacer().frame(height: 22)

                        RoundedActionButton(
                            title: auth.isSavingProfile ? "Saving..." : "Save Profile",
                            background: .black,
                            foreground: .white,
                            disabled: auth.isSavingProfile
                        ) {
                            auth.saveProfile(firstName: firstName, lastName: lastName, username: username, email: email) {
                                showSavedAlert = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .background(AppTheme.profileGray)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 120)
            }

            BottomNavBar(active: .profile)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: loadUserDataOnce)
        .onChange(of: auth.appUser) { _ in
            loadUserDataOnce()
        }
        .alert("ACADvisory", isPresented: $showSavedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Profile updated successfully.")
        }
    }

    private func loadUserDataOnce() {
        guard !didLoad else { return }

        if let appUser = auth.appUser {
            firstName = appUser.firstName
            lastName = appUser.lastName
            username = appUser.username
            email = appUser.email.isEmpty ? auth.firebaseUser?.email ?? "" : appUser.email
            didLoad = true
        } else if let user = auth.firebaseUser {
            let displayName = user.displayName ?? ""
            let parts = displayName.components(separatedBy: " ")
            firstName = parts.first ?? ""
            lastName = parts.count > 1 ? parts.dropFirst().joined(separator: " ") : ""
            username = ""
            email = user.email ?? ""
            didLoad = true
        }
    }
}

struct ProfilePill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}

struct ProfileMenuItem: View {
    let text: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(red: 0.416, green: 0.416, blue: 0.416))
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(AppTheme.profileGray)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct EditProfileTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isEnabled = true

    var body: some View {
        TextField(label, text: $text)
            .font(.system(size: 14))
            .keyboardType(keyboardType)
            .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            .autocorrectionDisabled(keyboardType == .emailAddress)
            .disabled(!isEnabled)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.416, green: 0.416, blue: 0.416))
                    .padding(.horizontal, 4)
                    .background(.white)
                    .offset(x: 16, y: -7)
            }
    }
}

struct ProfileNavigationMenuItem: View {
    let text: String
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination.navigationBarBackButtonHidden(true)) {
            HStack {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(red: 0.416, green: 0.416, blue: 0.416))
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(AppTheme.profileGray)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct AnnouncementHistoryView: View {
    @EnvironmentObject private var store: AnnouncementStore
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    BackCircleButton { dismiss() }

                    Spacer().frame(height: 26)

                    ProfilePill(text: "HISTORY", color: AppTheme.accentYellow)

                    Spacer().frame(height: 16)

                    if auth.isAdmin {
                        AnnouncementHistoryList(history: store.announcementHistory)
                    } else {
                        HistoryMessageCard(text: "Only admin accounts can view announcement history.")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 120)
            }

            BottomNavBar(active: .profile)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

struct AnnouncementHistoryList: View {
    let history: [AnnouncementHistory]

    var body: some View {
        if history.isEmpty {
            HistoryMessageCard(text: "No edit or delete history yet.")
        } else {
            LazyVStack(spacing: 12) {
                ForEach(history) { item in
                    AnnouncementHistoryCard(item: item)
                }
            }
        }
    }
}

struct HistoryMessageCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(22)
            .background(AppTheme.profileGray)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct AnnouncementHistoryCard: View {
    let item: AnnouncementHistory

    private var isDeleted: Bool {
        item.action.lowercased() == "deleted"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: item.actionIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isDeleted ? .red : .black)
                    .frame(width: 28, height: 28)
                    .background(isDeleted ? Color.red.opacity(0.12) : AppTheme.accentYellow)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.actionLabel)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(isDeleted ? .red : .black)
                    Text(item.createdAt.acadvisoryLongString())
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                }

                Spacer()
            }

            Spacer().frame(height: 10)

            Text(item.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .lineLimit(2)

            Spacer().frame(height: 6)

            Text("Category: \(item.category)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.categoryStrong(item.category))

            Spacer().frame(height: 4)

            Text("Event: \(item.eventDateTimeText)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.black.opacity(0.72))

            Spacer().frame(height: 8)

            if isDeleted {
                Text("Deleted archive: \(item.details.acadvisoryLimited(to: 95))")
                    .font(.system(size: 11))
                    .foregroundStyle(.black.opacity(0.78))
            } else {
                AnnouncementHistoryChanges(item: item)
            }

            Spacer().frame(height: 10)

            Text("By: \(item.actorName) • \(item.actorRole)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.gray)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDeleted ? Color.red.opacity(0.28) : AppTheme.accentYellow.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct AnnouncementHistoryChanges: View {
    let item: AnnouncementHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if item.oldTitle != item.newTitle {
                HistoryChangeLine(label: "Title", oldValue: item.oldTitle, newValue: item.newTitle)
            }

            if item.oldCategory != item.newCategory {
                HistoryChangeLine(label: "Category", oldValue: item.oldCategory, newValue: item.newCategory)
            }

            if item.oldEventDateTimeText != item.newEventDateTimeText {
                HistoryChangeLine(label: "Event Date & Time", oldValue: item.oldEventDateTimeText, newValue: item.newEventDateTimeText)
            }

            if item.oldDetails != item.newDetails {
                HistoryChangeLine(label: "Details", oldValue: item.oldDetails.acadvisoryLimited(to: 60), newValue: item.newDetails.acadvisoryLimited(to: 60))
            }
        }
    }
}

struct HistoryChangeLine: View {
    let label: String
    let oldValue: String
    let newValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.gray)
            Text("From: \(oldValue.isEmpty ? "—" : oldValue)")
                .font(.system(size: 10))
                .foregroundStyle(.black.opacity(0.66))
                .lineLimit(2)
            Text("To: \(newValue.isEmpty ? "—" : newValue)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(2)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.profileGray.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
