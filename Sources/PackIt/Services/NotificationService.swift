import Foundation
import PackItKit
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        return UNUserNotificationCenter.current()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        guard let center else { return false }
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        guard let center else { return false }
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    func scheduleDepartureReminder(tripID: UUID, tripName: String, departureDate: Date) async {
        guard let center else { return }
        let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: departureDate)!
        guard oneDayBefore > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Trip Tomorrow"
        content.body = "\(tripName) — departure is tomorrow! Check your packing list."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: oneDayBefore)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let id = departureReminderID(tripID: tripID)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleOverdueItemReminder(tripID: UUID, tripName: String, itemName: String, dueDate: Date) async {
        guard let center else { return }
        guard dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Packing Reminder"
        content.body = "\(tripName): \"\(itemName)\" is due today."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let id = itemReminderID(tripID: tripID, itemName: itemName)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func postIncomingShareNotification(count: Int, authors: [String]) async {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        let sortedAuthors = authors.sorted()
        if count == 1, let author = sortedAuthors.first {
            content.title = "PackIt: New from \(author)"
            content.body = "Open PackIt to see what was shared with you."
        } else if sortedAuthors.count == 1, let author = sortedAuthors.first {
            content.title = "PackIt: \(count) new items from \(author)"
            content.body = "Open PackIt to see them."
        } else {
            content.title = "PackIt: \(count) new shared items"
            let joined = sortedAuthors.joined(separator: ", ")
            content.body = "Shared by \(joined). Open PackIt to see them."
        }
        content.sound = .default

        let id = "packit-incoming-share-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        try? await center.add(request)
    }

    // MARK: - Cancellation

    func cancelDepartureReminder(tripID: UUID) async {
        guard let center else { return }
        center.removePendingNotificationRequests(withIdentifiers: [departureReminderID(tripID: tripID)])
    }

    func cancelAllReminders(tripID: UUID) async {
        guard let center else { return }
        let pending = await center.pendingNotificationRequests()
        let prefix = "packit-\(tripID.uuidString)"
        let matching = pending.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: matching)
    }

    // MARK: - Sync

    /// Reschedule all relevant reminders for a trip. Call after trip updates.
    func syncReminders(trip: TripInstance) async {
        await cancelAllReminders(tripID: trip.id)

        guard trip.status == .planning || trip.status == .active else { return }

        await scheduleDepartureReminder(tripID: trip.id, tripName: trip.name, departureDate: trip.departureDate)

        for item in trip.items where !item.isPacked {
            if let dueDate = item.dueDate, item.priority >= .high {
                await scheduleOverdueItemReminder(tripID: trip.id, tripName: trip.name, itemName: item.name, dueDate: dueDate)
            }
        }
    }

    // MARK: - Pending Info

    func pendingCount(for tripID: UUID) async -> Int {
        guard let center else { return 0 }
        let pending = await center.pendingNotificationRequests()
        let prefix = "packit-\(tripID.uuidString)"
        return pending.filter { $0.identifier.hasPrefix(prefix) }.count
    }

    // MARK: - Identifiers

    private func departureReminderID(tripID: UUID) -> String {
        "packit-\(tripID.uuidString)-departure"
    }

    private func itemReminderID(tripID: UUID, itemName: String) -> String {
        let sanitized = itemName.lowercased().replacingOccurrences(of: " ", with: "-")
        return "packit-\(tripID.uuidString)-item-\(sanitized)"
    }
}
