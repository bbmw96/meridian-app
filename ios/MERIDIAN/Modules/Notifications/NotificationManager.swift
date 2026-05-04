import UserNotifications
import Observation

@Observable
final class NotificationManager: NSObject {

    var isPermissionGranted: Bool = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshPermissionState()
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isPermissionGranted = granted
            return granted
        } catch {
            isPermissionGranted = false
            return false
        }
    }

    func scheduleRateAlert(
        pair: String,
        threshold: Double,
        direction: String,
        message: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Rate Alert: \(pair)")
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "meridian.rateAlert"
        content.userInfo = [
            "pair": pair,
            "threshold": threshold,
            "direction": direction
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let id = "meridian.rate.\(pair).\(direction).\(threshold)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelAlert(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func refreshPermissionState() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
