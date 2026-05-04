import Foundation
import Observation

@Observable
final class CurrencyEngine {
    var rates: [CurrencyRate] = []
    var alerts: [RateAlert] = []
    var isLive = false
    var connectionError: String?

    private let apiClient = APIClient.shared
    private let wsClient = WebSocketClient.shared
    private let cache = CacheManager.shared
    private var liveTask: Task<Void, Never>?

    private let majorPairs = [
        "GBP/USD", "GBP/EUR", "EUR/USD", "USD/JPY",
        "GBP/JPY", "EUR/JPY", "USD/CHF", "AUD/USD",
        "USD/CAD", "NZD/USD", "EUR/GBP", "GBP/CHF"
    ]

    func startLiveFeed() async {
        rates = CurrencyRate.previewList

        liveTask?.cancel()
        liveTask = Task {
            let wsURL = URL(string: "wss://ws.meridian.io/rates")!
            await wsClient.connect(to: wsURL)
            isLive = true

            let stream = await wsClient.subscribe(topic: "rates:live")
            for await message in stream {
                guard !Task.isCancelled else { break }
                if message.event == "rate_update" {
                    await handleRateUpdate(message.payload)
                }
            }
            isLive = false
        }
    }

    func stopLiveFeed() async {
        liveTask?.cancel()
        await wsClient.disconnect()
        isLive = false
    }

    func addAlert(_ alert: RateAlert) {
        alerts.removeAll { $0.id == alert.id }
        alerts.append(alert)
        PersistenceController.shared.saveRateAlert(alert)
    }

    func removeAlert(id: UUID) {
        alerts.removeAll { $0.id == id }
    }

    func toggleAlert(id: UUID) {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].isActive.toggle()
            PersistenceController.shared.saveRateAlert(alerts[index])
        }
    }

    func convert(amount: Double, from: String, to: String) -> Double? {
        if from == to { return amount }

        let directPair = "\(from)/\(to)"
        if let rate = rates.first(where: { $0.id == directPair }) {
            return amount * rate.rate
        }

        let inversePair = "\(to)/\(from)"
        if let rate = rates.first(where: { $0.id == inversePair }), rate.rate != 0 {
            return amount / rate.rate
        }

        let toUSD = rates.first(where: { $0.id == "\(from)/USD" })?.rate
        let fromUSD = rates.first(where: { $0.id == "USD/\(to)" })?.rate

        if let toUSD, let fromUSD {
            return amount * toUSD * fromUSD
        }

        return nil
    }

    func historicalRates(pair: String, days: Int) async throws -> [CurrencyRate] {
        if let cached = await cache.retrieveRates(pair: pair) {
            return cached
        }

        let allRates: [CurrencyRate] = try await apiClient.fetch(.getRates([pair]))
        await cache.cacheRates(allRates, pair: pair)
        return allRates
    }

    func rate(for pair: String) -> CurrencyRate? {
        rates.first { $0.id == pair }
    }

    private func handleRateUpdate(_ payload: [String: AnyCodable]) async {
        guard let pairValue = payload["pair"]?.value as? String,
              let rateValue = payload["rate"]?.value as? Double else { return }

        let previousRate = rates.first(where: { $0.id == pairValue })?.rate ?? rateValue

        let updated = CurrencyRate(
            id: pairValue,
            rate: rateValue,
            previousRate: previousRate,
            timestamp: Date(),
            source: payload["source"]?.value as? String ?? "WS"
        )

        if let index = rates.firstIndex(where: { $0.id == pairValue }) {
            rates[index] = updated
        } else {
            rates.append(updated)
        }

        await checkAlerts(for: updated)
    }

    private func checkAlerts(for rate: CurrencyRate) async {
        for alert in alerts where alert.isActive && alert.pair == rate.id {
            let triggered = alert.direction == .above
                ? rate.rate > alert.threshold
                : rate.rate < alert.threshold
            if triggered {
                scheduleAlertNotification(alert: alert, currentRate: rate.rate)
            }
        }
    }

    private func scheduleAlertNotification(alert: RateAlert, currentRate: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Rate Alert: \(alert.pair)"
        content.body = "\(alert.pair) is now \(String(format: "%.4f", currentRate)) — \(alert.description)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "alert_\(alert.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

import UserNotifications
