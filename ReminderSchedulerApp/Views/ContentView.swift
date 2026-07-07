import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var isAddingReminder = false
    @State private var activeCall: ReminderItem?

    var body: some View {
        NavigationStack {
            Group {
                if store.reminders.isEmpty {
                    ContentUnavailableView(
                        "No future calls",
                        systemImage: "phone.down.waves.left.and.right",
                        description: Text("Record a message and schedule when your future self should receive it.")
                    )
                } else {
                    List {
                        ForEach(store.reminders) { reminder in
                            ReminderRowView(reminder: reminder) {
                                store.toggleDone(reminder)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Future Call")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingReminder = true
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingReminder) {
                AddReminderView()
                    .environmentObject(store)
            }
            .fullScreenCover(item: $activeCall) { reminder in
                IncomingCallView(
                    reminder: reminder,
                    onComplete: {
                        store.complete(reminder)
                        activeCall = nil
                    },
                    onDismiss: {
                        activeCall = nil
                    }
                )
            }
            .onAppear(perform: showIncomingCallIfNeeded)
            .onChange(of: store.reminders) {
                showIncomingCallIfNeeded()
            }
        }
    }

    private func showIncomingCallIfNeeded() {
        guard activeCall == nil else { return }
        activeCall = store.nextIncomingCall
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
}
