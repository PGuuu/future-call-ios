import SwiftUI

enum FCTheme {
    static let background = Color(red: 0.125, green: 0.106, blue: 0.09)
    static let card = Color(red: 0.184, green: 0.157, blue: 0.133)
    static let cream = Color(red: 0.949, green: 0.925, blue: 0.878)
    static let warmGray = Color(red: 0.686, green: 0.635, blue: 0.565)
    static let sage = Color(red: 0.573, green: 0.722, blue: 0.51)
    static let sageDeep = Color(red: 0.11, green: 0.19, blue: 0.1)
    static let coral = Color(red: 0.898, green: 0.62, blue: 0.553)
}

struct ContentView: View {
    private enum HomeTab {
        case upcoming
        case history
    }

    @EnvironmentObject private var store: ReminderStore
    @ObservedObject private var router = NotificationRouter.shared
    @State private var isAddingReminder = false
    @State private var reminderToEdit: ReminderItem?
    @State private var activeReminder: ReminderItem?
    @State private var presentAnswered = false
    @State private var selectedTab: HomeTab = .upcoming

    var body: some View {
        ZStack {
            FCTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                List {
                    Group {
                        heroCard

                        if !store.missedReminders.isEmpty {
                            missedStrip
                        }

                        tabPicker

                        if selectedTab == .upcoming {
                            upcomingRows
                        } else {
                            historyRows
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                dialButton
            }

            if let presentedReminder = activeReminder {
                IncomingCallView(
                    reminder: presentedReminder,
                    startAnswered: presentAnswered,
                    onComplete: {
                        store.complete(presentedReminder)
                        withAnimation(.easeIn(duration: 0.2)) {
                            activeReminder = nil
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeIn(duration: 0.2)) {
                            activeReminder = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isAddingReminder) {
            AddReminderView()
                .environmentObject(store)
        }
        .sheet(item: $reminderToEdit) { reminder in
            AddReminderView(reminderToEdit: reminder)
                .environmentObject(store)
        }
        .onChange(of: router.pendingReminderID) {
            presentPendingCall()
        }
        .onAppear {
            presentPendingCall()
        }
    }

    private var header: some View {
        HStack {
            Text("Future Call")
                .font(.title2.weight(.semibold))
                .foregroundStyle(FCTheme.cream)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NEXT CALL")
                .font(.caption2.weight(.medium))
                .tracking(1.2)
                .foregroundStyle(FCTheme.warmGray)

            if let next = store.futureReminders.first {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(FCTheme.cream.opacity(0.1))
                            .frame(width: 46, height: 46)
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundStyle(FCTheme.warmGray)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Past Me")
                            .font(.headline)
                            .foregroundStyle(FCTheme.cream)
                        Text(heroSubtitle(next))
                            .font(.subheadline)
                            .foregroundStyle(FCTheme.warmGray)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: next.timeHidden ? "sparkles" : "clock")
                        .font(.caption)
                    Text(heroTiming(next))
                        .font(.footnote)
                }
                .foregroundStyle(FCTheme.sage)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(FCTheme.sage.opacity(0.14), in: Capsule())
            } else {
                Text("No calls scheduled")
                    .font(.headline)
                    .foregroundStyle(FCTheme.cream)
                Text("Leave one for your future self. It will ring when the time comes.")
                    .font(.subheadline)
                    .foregroundStyle(FCTheme.warmGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(FCTheme.card, in: RoundedRectangle(cornerRadius: 22))
    }

    private var missedStrip: some View {
        Button {
            presentAnswered = false
            if let missed = store.missedReminders.first {
                withAnimation(.easeOut(duration: 0.25)) {
                    activeReminder = missed
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "phone.arrow.down.left")
                    .font(.subheadline)
                Text(missedText)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(FCTheme.coral)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(FCTheme.coral.opacity(0.13), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var missedText: String {
        let count = store.missedReminders.count
        return count == 1 ? "1 missed call from Past Me" : "\(count) missed calls from Past Me"
    }

    private var tabPicker: some View {
        HStack(spacing: 8) {
            tabButton(title: "Upcoming", tab: .upcoming)
            tabButton(title: "History", tab: .history)
            Spacer()
        }
        .padding(.top, 6)
    }

    private func tabButton(title: String, tab: HomeTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(selectedTab == tab ? FCTheme.cream : FCTheme.warmGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    selectedTab == tab ? FCTheme.cream.opacity(0.12) : Color.clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var upcomingRows: some View {
        if store.futureReminders.isEmpty {
            emptyRow("No calls on the way yet.")
        } else {
            ForEach(store.futureReminders) { reminder in
                CallLogRow(
                    icon: rowIcon(reminder),
                    title: rowTitle(reminder),
                    trailing: upcomingTrailing(reminder)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    reminderToEdit = reminder
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.delete(reminder)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        reminderToEdit = reminder
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
    }

    @ViewBuilder
    private var historyRows: some View {
        if store.pastReminders.isEmpty {
            emptyRow("No calls answered yet.")
        } else {
            ForEach(store.pastReminders) { reminder in
                CallLogRow(
                    icon: rowIcon(reminder),
                    title: rowTitle(reminder),
                    trailing: historyTrailing(reminder)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    presentAnswered = true
                    withAnimation(.easeOut(duration: 0.25)) {
                        activeReminder = reminder
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.delete(reminder)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func emptyRow(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(FCTheme.warmGray)
            .padding(.vertical, 14)
    }

    private var dialButton: some View {
        VStack(spacing: 8) {
            Button {
                isAddingReminder = true
            } label: {
                ZStack {
                    Circle()
                        .fill(FCTheme.sage)
                        .frame(width: 66, height: 66)
                    Image(systemName: "phone.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(FCTheme.sageDeep)
                }
            }
            .buttonStyle(.plain)

            Text("Call the Future")
                .font(.footnote)
                .foregroundStyle(FCTheme.warmGray)
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private func rowIcon(_ reminder: ReminderItem) -> String {
        if reminder.mode == .repeating {
            return "bell"
        }
        return reminder.hasVoiceMessage ? "mic" : "message"
    }

    private func rowTitle(_ reminder: ReminderItem) -> String {
        if reminder.title.isEmpty {
            return reminder.hasVoiceMessage ? "Voice message" : "Message"
        }
        return reminder.title
    }

    private func heroSubtitle(_ reminder: ReminderItem) -> String {
        if reminder.title.isEmpty {
            return reminder.hasVoiceMessage ? "A voice message is waiting" : "A message is waiting"
        }
        return reminder.title
    }

    private func heroTiming(_ reminder: ReminderItem) -> String {
        if reminder.mode == .repeating {
            return "Keeps calling every \(intervalText(reminder.repeatIntervalMinutes ?? 0))"
        }
        if reminder.timeHidden {
            return "Calling someday. Past Me decides"
        }
        if reminder.randomTime {
            return "Calling \(monthDayText(reminder.triggerDate)), anytime that day"
        }
        return "Calling \(relativeText(reminder.triggerDate))"
    }

    private func upcomingTrailing(_ reminder: ReminderItem) -> String {
        if reminder.mode == .repeating {
            return "every \(intervalText(reminder.repeatIntervalMinutes ?? 0))"
        }
        if reminder.timeHidden {
            return "someday"
        }
        if reminder.randomTime {
            return "\(monthDayText(reminder.triggerDate)) · anytime"
        }
        return relativeText(reminder.triggerDate)
    }

    private func historyTrailing(_ reminder: ReminderItem) -> String {
        relativeText(reminder.triggerDate)
    }

    private func relativeText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en_US")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func monthDayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func intervalText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours) hr \(mins) min"
        }
        if hours > 0 {
            return "\(hours) hr"
        }
        return "\(mins) min"
    }

    private func presentPendingCall() {
        guard let id = router.pendingReminderID else { return }
        router.clearPendingReminderID()

        guard let reminder = store.reminder(id: id), !reminder.isDone else { return }

        presentAnswered = false
        withAnimation(.easeOut(duration: 0.25)) {
            activeReminder = reminder
        }
    }
}

struct CallLogRow: View {
    let icon: String
    let title: String
    let trailing: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(FCTheme.warmGray)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(FCTheme.cream)
                .lineLimit(1)

            Spacer()

            Text(trailing)
                .font(.footnote)
                .foregroundStyle(FCTheme.warmGray)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(FCTheme.cream.opacity(0.06))
                .frame(height: 0.5)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
}
