import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    func scheduleDepartureReminder(tripID: UUID, tripName: String, departureDate: Date) async {
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

    // MARK: - Cancellation

    func cancelDepartureReminder(tripID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [departureReminderID(tripID: tripID)])
    }

    func cancelAllReminders(tripID: UUID) async {
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
