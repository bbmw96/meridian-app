import SwiftUI
import Combine

@Observable
final class CurrencyViewModel {

    var fromCurrency: String = "GBP"
    var toCurrency: String = "USD"
    var inputAmount: String = "100"
    var convertedAmount: Double?
    var rates: [CurrencyRate] = []
    var alerts: [RateAlert] = []
    var isAddingAlert: Bool = false
    var newAlertPair: String = ""
    var newAlertThreshold: String = ""
    var newAlertDirection: CurrencyDirection = .above

    private let currencyEngine: CurrencyEngine

    init(currencyEngine: CurrencyEngine) {
        self.currencyEngine = currencyEngine
    }

    var displayedRates: [CurrencyRate] {
        let majorPairs = ["GBP/USD", "EUR/GBP", "USD/JPY", "GBP/AUD",
                         "GBP/CAD", "USD/CHF", "USD/CNY", "GBP/INR"]
        let major = rates.filter { majorPairs.contains($0.id) }
        let rest = rates.filter { !majorPairs.contains($0.id) }
        return major + rest
    }

    func onAppear() async {
        rates = currencyEngine.rates
        alerts = currencyEngine.alerts
        await currencyEngine.startLiveFeed()
        performConversion()
    }

    func performConversion() {
        guard let amount = Double(inputAmount), !inputAmount.isEmpty else {
            convertedAmount = nil
            return
        }
        convertedAmount = currencyEngine.convert(amount: amount, from: fromCurrency, to: toCurrency)
    }

    func submitNewAlert() {
        guard
            !newAlertPair.isEmpty,
            let threshold = Double(newAlertThreshold)
        else { return }
        let alert = RateAlert(
            id: UUID(),
            pair: newAlertPair,
            threshold: threshold,
            direction: newAlertDirection,
            isActive: true
        )
        currencyEngine.addAlert(alert)
        alerts = currencyEngine.alerts
        isAddingAlert = false
        newAlertPair = ""
        newAlertThreshold = ""
    }

    func deleteAlert(id: UUID) {
        currencyEngine.removeAlert(id: id)
        alerts = currencyEngine.alerts
    }

    func swapCurrencies() {
        let tmp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = tmp
        performConversion()
    }
}
