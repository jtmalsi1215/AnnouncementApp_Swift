import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AnnouncementStore

    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var showNotifications = false

    private var filteredAnnouncements: [Announcement] {
        store.announcements.filter { announcement in
            let matchesCategory = selectedCategory == nil || announcement.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            guard !query.isEmpty else { return matchesCategory }

            let matchesSearch = announcement.title.lowercased().contains(query) ||
                announcement.details.lowercased().contains(query) ||
                announcement.category.lowercased().contains(query)

            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    DashboardUserHeader {
                        showNotifications = true
                    }

                    Spacer().frame(height: 24)

                    DashboardSearchBar(searchText: $searchText)

                    Spacer().frame(height: 22)

                    Text("Featured Update")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)

                    Spacer().frame(height: 10)

                    if let first = store.announcements.first {
                        FeaturedUpdateCard(announcement: first)
                    } else {
                        EmptyFeaturedCard()
                    }

                    Spacer().frame(height: 20)

                    Text("Browse")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)

                    Spacer().frame(height: 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(AnnouncementCategory.allCases) { category in
                                DashboardCategoryChip(
                                    category: category.rawValue,
                                    selected: selectedCategory == category.rawValue
                                ) {
                                    selectedCategory = selectedCategory == category.rawValue ? nil : category.rawValue
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 2)
                    }

                    Spacer().frame(height: 14)

                    HStack {
                        Text("Recent Updates")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                        if selectedCategory != nil {
                            Button("Clear") {
                                selectedCategory = nil
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray)
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer().frame(height: 12)

                    recentList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 130)
            }

            BottomNavBar(active: .home)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showNotifications) {
            AnnouncementNotificationsView()
                .environmentObject(auth)
                .environmentObject(store)
        }
    }

    @ViewBuilder
    private var recentList: some View {
        if store.announcements.isEmpty {
            Text("No announcements yet.")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
        } else if filteredAnnouncements.isEmpty {
            Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No \(selectedCategory ?? "") announcements." : "No announcements found.")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
        } else {
            LazyVStack(spacing: 9) {
                ForEach(filteredAnnouncements) { announcement in
                    NavigationLink(destination: CalendarView(initialAnnouncementId: announcement.id).navigationBarBackButtonHidden(true)) {
                        UpdateCard(announcement: announcement)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct DashboardUserHeader: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AnnouncementStore

    let onBellTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                ProfilePhotoView(
                    photoUrl: auth.appUser?.photoUrl ?? auth.firebaseUser?.photoURL?.absoluteString ?? "",
                    photoBase64: auth.appUser?.photoBase64 ?? "",
                    size: 44,
                    cornerRadius: 10
                )

                Spacer()

                NotificationBellButton(
                    unreadCount: auth.isAdmin ? 0 : store.unreadAnnouncementCount,
                    action: onBellTap
                )
            }

            Spacer().frame(height: 24)

            Text("HELLO,")
                .font(.system(size: 28, weight: .regular))
                .tracking(2)
                .foregroundStyle(.black)

            Text(auth.appUser?.firstNameUppercase ?? auth.firebaseUser?.displayName?.components(separatedBy: " ").first?.uppercased() ?? "USER")
                .font(.system(size: 29, weight: .black))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer().frame(height: 8)

            Text("Stay updated with the latest announcements.")
                .font(.system(size: 12))
                .foregroundStyle(.gray.opacity(0.75))
        }
    }
}

struct DashboardSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.gray.opacity(0.55))

            TextField("Search announcements", text: $searchText)
                .font(.system(size: 12))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 18)
        .frame(height: 50)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.gray.opacity(0.45), lineWidth: 1.2)
        )
    }
}

struct FeaturedUpdateCard: View {
    let announcement: Announcement

    var body: some View {
        NavigationLink(destination: CalendarView(initialAnnouncementId: announcement.id).navigationBarBackButtonHidden(true)) {
            ZStack(alignment: .topLeading) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 14)

                        Text(announcement.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)
                            .lineLimit(2)

                        Spacer().frame(height: 7)

                        HStack(spacing: 6) {
                            Text(announcement.createdAt.dashboardShortDate())
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black)
                                .clipShape(Capsule())

                            Text(announcement.createdAt.dashboardTime())
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black)
                                .clipShape(Capsule())
                        }

                        Spacer().frame(height: 8)

                        Text(announcement.details.acadvisoryLimited(to: 58))
                            .font(.system(size: 11))
                            .foregroundStyle(.black)
                            .lineLimit(2)

                        Spacer().frame(height: 10)

                        HStack(spacing: 7) {
                            Text("Read more")
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(.black)
                        .clipShape(Capsule())
                    }

                    Spacer(minLength: 6)

                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.898, blue: 0.58))
                            .frame(width: 76, height: 76)

                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(Color(red: 0.74, green: 0.21, blue: 0.84))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
                .background(Color(red: 1.0, green: 0.853, blue: 0.431))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 6)

                Text(announcement.category.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.categoryStrong(announcement.category))
                    .clipShape(Capsule())
                    .offset(x: 22, y: -9)
            }
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyFeaturedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No featured announcement yet.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            Text("Published announcements will appear here.")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(18)
        .background(Color(red: 1.0, green: 0.853, blue: 0.431))
        .clipShape(RoundedRectangle(cornerRadius: 27))
        .shadow(color: .black.opacity(0.14), radius: 7, x: 0, y: 5)
    }
}

struct DashboardCategoryChip: View {
    let category: String
    let selected: Bool
    let action: () -> Void

    private var resolvedCategory: AnnouncementCategory {
        AnnouncementCategory.from(category)
    }

    private var title: String {
        resolvedCategory == .campusUpdates ? "Campus Update" : category
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.categoryStrong(category).opacity(0.22))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: resolvedCategory.iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.categoryStrong(category))
                    )

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .padding(.vertical, 6)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? AppTheme.categoryStrong(category) : Color.gray.opacity(0.22), lineWidth: selected ? 2 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.17), radius: 4, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct UpdateCard: View {
    let announcement: Announcement

    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 9)
                .fill(AppTheme.categoryStrong(announcement.category).opacity(0.18))
                .frame(width: 76, height: 76)
                .overlay(
                    Image(systemName: AnnouncementCategory.from(announcement.category).iconName)
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(AppTheme.categoryStrong(announcement.category))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(announcement.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(announcement.createdAt.dashboardCompactDate())
                    Circle()
                        .fill(Color.gray.opacity(0.45))
                        .frame(width: 5, height: 5)
                    Text(announcement.createdAt.dashboardTime())
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.black.opacity(0.72))
                .lineLimit(1)

                Text(announcement.details.acadvisoryLimited(to: 58))
                    .font(.system(size: 11))
                    .foregroundStyle(.black.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(AppTheme.categoryBackground(announcement.category).opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(AppTheme.categoryStrong(announcement.category).opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: .black.opacity(0.14), radius: 4, x: 0, y: 2)
    }
}

private extension Date {
    func dashboardShortDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self).uppercased()
    }

    func dashboardCompactDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }

    func dashboardTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: self)
    }
}
