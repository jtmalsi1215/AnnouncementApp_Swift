import SwiftUI

struct NewAnnouncementView: View {
    @EnvironmentObject private var store: AnnouncementStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var details = ""
    @State private var selectedCategory = AnnouncementCategory.academics.rawValue
    @State private var alertText = ""
    @State private var showAlert = false
    @State private var shouldDismissAfterAlert = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                NewAnnouncementContent(
                    title: $title,
                    eventDate: $eventDate,
                    eventTime: $eventTime,
                    details: $details,
                    selectedCategory: $selectedCategory,
                    isPublishing: store.isPublishing,
                    cancelAction: cancelForm,
                    publishAction: publishAnnouncement
                )
                .padding(20)
                .padding(.bottom, 120)
            }

            BottomNavBar(active: .newPost)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .alert("ACADvisory", isPresented: $showAlert) {
            Button("OK") {
                if shouldDismissAfterAlert {
                    dismiss()
                }
            }
        } message: {
            Text(alertText)
        }
    }

    private func cancelForm() {
        dismiss()
    }

    private func publishAnnouncement() {
        let eventDateTime = acadvisoryCombine(date: eventDate, time: eventTime)

        store.publishAnnouncement(title: title, details: details, category: selectedCategory, eventDateTime: eventDateTime) { success, message in
            if success {
                title = ""
                details = ""
                eventDate = Date()
                eventTime = Date()
                shouldDismissAfterAlert = true
                alertText = "Announcement published successfully!"
            } else {
                shouldDismissAfterAlert = false
                alertText = message ?? "Unable to publish announcement."
            }

            showAlert = true
        }
    }
}

struct NewAnnouncementContent: View {
    @Binding var title: String
    @Binding var eventDate: Date
    @Binding var eventTime: Date
    @Binding var details: String
    @Binding var selectedCategory: String

    let isPublishing: Bool
    let cancelAction: () -> Void
    let publishAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderPlaceholderView()

            Spacer().frame(height: 35)

            NewAnnouncementTitleBanner()

            Spacer().frame(height: 12)

            NewAnnouncementFormCard(
                title: $title,
                eventDate: $eventDate,
                eventTime: $eventTime,
                details: $details,
                selectedCategory: $selectedCategory
            )

            Spacer().frame(height: 14)

            NewAnnouncementActionButtons(
                isPublishing: isPublishing,
                cancelAction: cancelAction,
                publishAction: publishAction
            )
        }
    }
}

struct NewAnnouncementTitleBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))

            Text("NEW ANNOUNCEMENT")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(red: 1.0, green: 0.796, blue: 0.271))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

struct NewAnnouncementFormCard: View {
    @Binding var title: String
    @Binding var eventDate: Date
    @Binding var eventTime: Date
    @Binding var details: String
    @Binding var selectedCategory: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NewAnnouncementTitleField(title: $title)

            Spacer().frame(height: 14)

            NewAnnouncementEventDateTimeFields(eventDate: $eventDate, eventTime: $eventTime)

            Spacer().frame(height: 14)

            NewAnnouncementDetailsField(details: $details)

            Spacer().frame(height: 18)

            NewAnnouncementCategorySelector(selectedCategory: $selectedCategory)
        }
        .padding(15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.24), radius: 12, x: 0, y: 5)
    }
}

struct NewAnnouncementTitleField: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            NewAnnouncementFieldLabel(icon: "doc.text", text: "Announcement Title")

            TextField("", text: $title)
                .font(.system(size: 14))
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )
        }
    }
}

struct NewAnnouncementEventDateTimeFields: View {
    @Binding var eventDate: Date
    @Binding var eventTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NewAnnouncementFieldLabel(icon: "calendar", text: "Date of Event")

            DatePicker("", selection: $eventDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )

            NewAnnouncementFieldLabel(icon: "clock", text: "Time of Event")

            DatePicker("", selection: $eventTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )
        }
    }
}

struct NewAnnouncementDetailsField: View {
    @Binding var details: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            NewAnnouncementFieldLabel(icon: "square.and.pencil", text: "Details")

            TextEditor(text: $details)
                .font(.system(size: 14))
                .frame(height: 150)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )
        }
    }
}

struct NewAnnouncementCategorySelector: View {
    @Binding var selectedCategory: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NewAnnouncementFieldLabel(icon: "folder", text: "Category")

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    NewAnnouncementCategoryButton(category: .academics, selectedCategory: $selectedCategory)
                    NewAnnouncementCategoryButton(category: .events, selectedCategory: $selectedCategory)
                    NewAnnouncementCategoryButton(category: .urgent, selectedCategory: $selectedCategory)
                }

                HStack(spacing: 8) {
                    NewAnnouncementCategoryButton(category: .organization, selectedCategory: $selectedCategory)
                    NewAnnouncementCategoryButton(category: .campusUpdates, selectedCategory: $selectedCategory)
                    Spacer()
                }
            }
        }
    }
}

struct NewAnnouncementCategoryButton: View {
    let category: AnnouncementCategory
    @Binding var selectedCategory: String

    private var isSelected: Bool {
        selectedCategory == category.rawValue
    }

    var body: some View {
        Button {
            selectedCategory = category.rawValue
        } label: {
            HStack(spacing: 5) {
                Image(systemName: category.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.categoryStrong(category.rawValue))

                Text(category.rawValue)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.black)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(AppTheme.categoryBackground(category.rawValue))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 1.3)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct NewAnnouncementActionButtons: View {
    let isPublishing: Bool
    let cancelAction: () -> Void
    let publishAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: cancelAction) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: publishAction) {
                Text(isPublishing ? "Publishing..." : "Publish")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isPublishing)
        }
    }
}

struct NewAnnouncementFieldLabel: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.769, green: 0.604, blue: 0.173))
                .frame(width: 21, height: 21)
                .background(Color(red: 1.0, green: 0.91, blue: 0.639))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.black)
        }
    }
}

struct EditAnnouncementView: View {
    @EnvironmentObject private var store: AnnouncementStore
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    let announcement: Announcement

    @State private var title: String
    @State private var eventDate: Date
    @State private var eventTime: Date
    @State private var details: String
    @State private var selectedCategory: String
    @State private var alertText = ""
    @State private var showAlert = false
    @State private var shouldDismissAfterAlert = false

    init(announcement: Announcement) {
        self.announcement = announcement
        let initialEventDateTime = announcement.eventDateTime ?? Date()
        _title = State(initialValue: announcement.title)
        _eventDate = State(initialValue: initialEventDateTime)
        _eventTime = State(initialValue: initialEventDateTime)
        _details = State(initialValue: announcement.details)
        _selectedCategory = State(initialValue: announcement.category)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                EditAnnouncementContent(
                    title: $title,
                    eventDate: $eventDate,
                    eventTime: $eventTime,
                    details: $details,
                    selectedCategory: $selectedCategory,
                    isSaving: store.isSavingAnnouncement,
                    cancelAction: { dismiss() },
                    saveAction: saveAnnouncement
                )
                .padding(20)
                .padding(.bottom, 120)
            }

            BottomNavBar(active: .calendar)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .alert("ACADvisory", isPresented: $showAlert) {
            Button("OK") {
                if shouldDismissAfterAlert {
                    dismiss()
                }
            }
        } message: {
            Text(alertText)
        }
    }

    private func saveAnnouncement() {
        guard auth.isAdmin else {
            shouldDismissAfterAlert = false
            alertText = "Only admin accounts can edit announcements."
            showAlert = true
            return
        }

        let eventDateTime = acadvisoryCombine(date: eventDate, time: eventTime)

        store.updateAnnouncement(
            announcement: announcement,
            title: title,
            details: details,
            category: selectedCategory,
            eventDateTime: eventDateTime,
            actorName: auth.currentActorName,
            actorRole: auth.currentActorRole
        ) { success, message in
            if success {
                shouldDismissAfterAlert = true
                alertText = "Announcement updated successfully."
            } else {
                shouldDismissAfterAlert = false
                alertText = message ?? "Unable to update announcement."
            }

            showAlert = true
        }
    }
}

struct EditAnnouncementContent: View {
    @Binding var title: String
    @Binding var eventDate: Date
    @Binding var eventTime: Date
    @Binding var details: String
    @Binding var selectedCategory: String

    let isSaving: Bool
    let cancelAction: () -> Void
    let saveAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderPlaceholderView()

            Spacer().frame(height: 35)

            EditAnnouncementTitleBanner()

            Spacer().frame(height: 12)

            NewAnnouncementFormCard(
                title: $title,
                eventDate: $eventDate,
                eventTime: $eventTime,
                details: $details,
                selectedCategory: $selectedCategory
            )

            Spacer().frame(height: 14)

            EditAnnouncementActionButtons(
                isSaving: isSaving,
                cancelAction: cancelAction,
                saveAction: saveAction
            )
        }
    }
}

struct EditAnnouncementTitleBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil")
                .font(.system(size: 18, weight: .bold))

            Text("EDIT ANNOUNCEMENT")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(red: 1.0, green: 0.796, blue: 0.271))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

struct EditAnnouncementActionButtons: View {
    let isSaving: Bool
    let cancelAction: () -> Void
    let saveAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: cancelAction) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button(action: saveAction) {
                Text(isSaving ? "Saving..." : "Save Changes")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
    }
}

private func acadvisoryCombine(date: Date, time: Date) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute

    return calendar.date(from: combined) ?? date
}
