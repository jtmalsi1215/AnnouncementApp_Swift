import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: AnnouncementStore
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    var initialAnnouncementId: String? = nil

    @State private var selectedDateKey: String?
    @State private var selectedAnnouncementIndex = 0
    @State private var didApplyInitialSelection = false
    @State private var announcementToDelete: Announcement?
    @State private var showDeleteConfirmation = false
    @State private var showActionAlert = false
    @State private var actionAlertText = ""

    private var groupedAnnouncements: [String: [Announcement]] {
        Dictionary(grouping: store.announcements) { $0.calendarDate.acadvisoryDateKey() }
    }

    private var dateKeys: [String] {
        groupedAnnouncements.keys.sorted()
    }

    private var selectedAnnouncements: [Announcement] {
        guard let selectedDateKey else { return [] }
        return groupedAnnouncements[selectedDateKey] ?? []
    }

    private var selectedAnnouncement: Announcement? {
        guard selectedAnnouncementIndex >= 0, selectedAnnouncementIndex < selectedAnnouncements.count else { return selectedAnnouncements.first }
        return selectedAnnouncements[selectedAnnouncementIndex]
    }

    private var otherAnnouncements: [Announcement] {
        guard let selectedAnnouncement else { return store.announcements }
        return store.announcements
            .filter { $0.id != selectedAnnouncement.id }
            .sorted { first, second in
                abs(first.calendarDate.timeIntervalSince(selectedAnnouncement.calendarDate)) < abs(second.calendarDate.timeIntervalSince(selectedAnnouncement.calendarDate))
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            if store.announcements.isEmpty {
                emptyCalendar
            } else {
                calendarContent
            }

            BottomNavBar(active: .calendar)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Delete this announcement?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Announcement", role: .destructive) {
                if let announcementToDelete {
                    deleteAnnouncement(announcementToDelete)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the announcement from the live list and save it in History.")
        }
        .alert("ACADvisory", isPresented: $showActionAlert) {
            Button("OK") { }
        } message: {
            Text(actionAlertText)
        }
        .onAppear(perform: applyInitialSelectionIfNeeded)
        .onChange(of: store.announcements) { _ in
            applyInitialSelectionIfNeeded()
        }
    }

    private var calendarContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HeaderPlaceholderView()

                    Spacer().frame(height: 30)

                    Button {
                        if let latest = store.announcements.first {
                            select(announcement: latest)
                        }
                    } label: {
                        Text("WHAT’S NEW")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 170)
                            .padding(.vertical, 12)
                            .background(Color(red: 1.0, green: 0.796, blue: 0.271))
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: 22)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(dateKeys, id: \.self) { key in
                                DatePillView(dateKey: key, selected: selectedDateKey == key) {
                                    selectedDateKey = key
                                    selectedAnnouncementIndex = 0
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        proxy.scrollTo(key, anchor: .center)
                                    }
                                }
                                .id(key)
                            }
                        }
                        .padding(.horizontal, 140)
                    }
                    .frame(height: 75)

                    Spacer().frame(height: 18)

                    if let selectedAnnouncement {
                        HStack(spacing: 6) {
                            Image(systemName: AnnouncementCategory.from(selectedAnnouncement.category).iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.categoryStrong(selectedAnnouncement.category))
                            Text("\(selectedAnnouncement.category) Announcement")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.categoryStrong(selectedAnnouncement.category))
                        }
                        .frame(maxWidth: .infinity)

                        Spacer().frame(height: 12)

                        TabView(selection: $selectedAnnouncementIndex) {
                            ForEach(Array(selectedAnnouncements.enumerated()), id: \.element.id) { index, announcement in
                                AnnouncementDetailCard(announcement: announcement)
                                    .tag(index)
                            }
                        }
                        .frame(height: 330)
                        .tabViewStyle(.page(indexDisplayMode: .never))

                        Spacer().frame(height: 14)

                        if selectedAnnouncements.count > 1 {
                            Text("\(selectedAnnouncementIndex + 1) of \(selectedAnnouncements.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                        }

                        if auth.isAdmin {
                            Spacer().frame(height: 12)

                            AdminAnnouncementActionBar(
                                announcement: selectedAnnouncement,
                                isDeleting: store.isDeletingAnnouncement
                            ) { announcement in
                                announcementToDelete = announcement
                                showDeleteConfirmation = true
                            }
                        }
                    }

                    Spacer().frame(height: 12)

                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)

                    Spacer().frame(height: 14)

                    Text("Recent Updates")
                        .font(.system(size: 15, weight: .bold))

                    Spacer().frame(height: 10)

                    if otherAnnouncements.isEmpty {
                        Text("No other announcements.")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(otherAnnouncements) { announcement in
                                Button {
                                    select(announcement: announcement)
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        proxy.scrollTo(announcement.calendarDate.acadvisoryDateKey(), anchor: .center)
                                    }
                                } label: {
                                    SmallAnnouncementRow(announcement: announcement)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 120)
            }
            .onChange(of: selectedDateKey) { key in
                if let key {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(key, anchor: .center)
                    }
                }
            }
        }
    }

    private var emptyCalendar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HeaderPlaceholderView()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer().frame(height: 80)

                Text("WHAT’S NEW")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 170)
                    .padding(.vertical, 12)
                    .background(Color(red: 1.0, green: 0.796, blue: 0.271))
                    .clipShape(RoundedRectangle(cornerRadius: 30))

                Spacer().frame(height: 40)

                Text("No announcements yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 120)
        }
    }

    private func applyInitialSelectionIfNeeded() {
        guard !store.announcements.isEmpty else { return }

        if didApplyInitialSelection, let selectedDateKey, dateKeys.contains(selectedDateKey) {
            return
        }

        let target: Announcement
        if let initialAnnouncementId,
           let match = store.announcements.first(where: { $0.id == initialAnnouncementId }) {
            target = match
        } else {
            target = store.announcements.first!
        }

        select(announcement: target)
        didApplyInitialSelection = true
    }

    private func deleteAnnouncement(_ announcement: Announcement) {
        store.deleteAnnouncement(
            announcement: announcement,
            actorName: auth.currentActorName,
            actorRole: auth.currentActorRole
        ) { success, message in
            if success {
                didApplyInitialSelection = false
                selectedDateKey = nil
                selectedAnnouncementIndex = 0
                actionAlertText = "Announcement deleted and saved in History."
            } else {
                actionAlertText = message ?? "Unable to delete announcement."
            }

            showActionAlert = true
            announcementToDelete = nil
        }
    }

    private func select(announcement: Announcement) {
        let key = announcement.calendarDate.acadvisoryDateKey()
        selectedDateKey = key
        let list = groupedAnnouncements[key] ?? []
        selectedAnnouncementIndex = list.firstIndex(where: { $0.id == announcement.id }) ?? 0
    }
}

struct DatePillView: View {
    let dateKey: String
    let selected: Bool
    let action: () -> Void

    private var date: Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateKey) ?? Date()
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(date.acadvisoryMonthShort())
                    .font(.system(size: selected ? 12 : 10, weight: .bold))
                    .foregroundStyle(selected ? .white : .gray)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: selected ? 22 : 18, weight: .bold))
                    .foregroundStyle(selected ? .white : .gray)
            }
            .frame(width: 62, height: 70)
            .background(selected ? Color.black : Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(selected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct AnnouncementDetailCard: View {
    let announcement: Announcement

    var body: some View {
        VStack(spacing: 0) {
            Text(announcement.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Spacer().frame(height: 8)

            VStack(spacing: 4) {
                Text("Posted: \(announcement.createdAt.acadvisoryLongString())")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)

                Text("Event Date and Time: \(announcement.eventDateTimeText)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 10)

            ScrollView(showsIndicators: true) {
                Text(announcement.details)
                    .font(.system(size: 11))
                    .lineSpacing(3)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Color.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(16)
        .background(AppTheme.categoryBackground(announcement.category))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 6)
    }
}

struct SmallAnnouncementRow: View {
    let announcement: Announcement

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.categoryBackground(announcement.category))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: AnnouncementCategory.from(announcement.category).iconName)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(AppTheme.categoryStrong(announcement.category))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(announcement.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                Text("Posted: \(announcement.createdAt.acadvisoryLongString())")
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                Text(announcement.details.acadvisoryLimited())
                    .font(.system(size: 9))
                    .foregroundStyle(.black)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
        }
        .padding(9)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.categoryBackground(announcement.category), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
    }
}

struct AdminAnnouncementActionBar: View {
    let announcement: Announcement
    let isDeleting: Bool
    let deleteAction: (Announcement) -> Void

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: EditAnnouncementView(announcement: announcement).navigationBarBackButtonHidden(true)) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.accentYellow)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                deleteAction(announcement)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text(isDeleting ? "Deleting..." : "Delete")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        }
    }
}
