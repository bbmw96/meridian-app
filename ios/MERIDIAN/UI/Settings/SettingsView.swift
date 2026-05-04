import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var currencySearch = ""
    @State private var languageSearch = ""
    @State private var showingPrivacySheet = false

    private let languageEngine = LanguageEngine()

    private var filteredCurrencies: [String] {
        let all = SupportedCurrency.all
        guard !currencySearch.isEmpty else { return all.map(\.code) }
        return all.filter {
            $0.code.contains(currencySearch.uppercased()) ||
            $0.name.lowercased().contains(currencySearch.lowercased())
        }.map(\.code)
    }

    private var filteredLanguages: [SupportedLanguage] {
        languageEngine.searchLanguages(query: languageSearch)
    }

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            ZStack {
                GradientBackground()
                Form {
                    currencySection(state: state)
                    languageSection(state: state)
                    connectionStatusSection
                    aboutSection
                    dataPrivacySection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPrivacySheet) {
                PrivacySheet()
            }
        }
    }

    @ViewBuilder
    private func currencySection(state: AppState) -> some View {
        Section {
            HStack {
                TextField("Search currencies...", text: $currencySearch)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !currencySearch.isEmpty {
                    Button { currencySearch = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }

            Picker("Preferred Currency", selection: Binding(
                get: { state.preferredCurrency },
                set: { state.preferredCurrency = $0; state.persistPreferences() }
            )) {
                ForEach(filteredCurrencies.prefix(30), id: \.self) { code in
                    let currency = SupportedCurrency.all.first { $0.code == code }
                    Text("\(code) — \(currency?.name ?? code)").tag(code)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        } header: {
            Text("Currency")
        }
    }

    @ViewBuilder
    private func languageSection(state: AppState) -> some View {
        Section {
            HStack {
                TextField("Search languages...", text: $languageSearch)
                    .autocorrectionDisabled()
                if !languageSearch.isEmpty {
                    Button { languageSearch = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }

            Picker("Preferred Language", selection: Binding(
                get: { state.preferredLanguage },
                set: { state.preferredLanguage = $0; state.persistPreferences() }
            )) {
                ForEach(filteredLanguages.prefix(30)) { lang in
                    HStack {
                        Text(lang.nativeName)
                        Spacer()
                        Text(lang.englishName)
                            .foregroundStyle(.secondary)
                    }
                    .tag(lang.id)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        } header: {
            Text("Language")
        }
    }

    private var connectionStatusSection: some View {
        Section("API Connections") {
            ConnectionStatusRow(name: "Intelligence API", endpoint: "api.meridian.io", isConnected: true)
            ConnectionStatusRow(name: "Currency WebSocket", endpoint: "ws.meridian.io", isConnected: true)
            ConnectionStatusRow(name: "GraphQL BFF", endpoint: "bff.meridian.io", isConnected: false)
            ConnectionStatusRow(name: "CloudKit Sync", endpoint: "iCloud", isConnected: true)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
            LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
            LabeledContent("MQL Version", value: "1.0")
            LabeledContent("Intelligence Engine", value: "MERIDIAN Core v2")
        }
    }

    private var dataPrivacySection: some View {
        Section("Data and Privacy") {
            Button {
                showingPrivacySheet = true
            } label: {
                Label("Privacy Policy (GDPR)", systemImage: "lock.shield.fill")
                    .foregroundStyle(Color.meridianAccent)
            }

            Button {
                UIPasteboard.general.string = UIDevice.current.identifierForVendor?.uuidString ?? ""
            } label: {
                Label("Copy Device ID", systemImage: "doc.on.clipboard")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                Task { await CacheManager.shared.clearAll() }
            } label: {
                Label("Clear Cache", systemImage: "trash")
            }
        }
    }
}

struct ConnectionStatusRow: View {
    let name: String
    let endpoint: String
    let isConnected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                Text(endpoint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.meridianGreen : Color.meridianRed)
                    .frame(width: 8, height: 8)
                Text(isConnected ? "Connected" : "Offline")
                    .font(.caption)
                    .foregroundStyle(isConnected ? Color.meridianGreen : Color.meridianRed)
            }
        }
    }
}

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MERIDIAN processes the following data:")
                            .font(.headline)

                        PrivacyItem(
                            icon: "globe",
                            title: "Domain Scan Data",
                            description: "Domains you scan are sent to MERIDIAN servers for intelligence analysis. Results are cached locally and in iCloud."
                        )
                        PrivacyItem(
                            icon: "arrow.left.arrow.right.circle",
                            title: "Currency Rates",
                            description: "Live currency rates are streamed from our WebSocket service. No personal financial data is collected."
                        )
                        PrivacyItem(
                            icon: "icloud",
                            title: "CloudKit Sync",
                            description: "Saved domains, pinned opportunities, and alerts are synced via your private iCloud container."
                        )
                        PrivacyItem(
                            icon: "location.slash",
                            title: "No Location Data",
                            description: "MERIDIAN does not collect or store your geographic location."
                        )

                        Text("Data Controller: MERIDIAN Intelligence Ltd., registered in England and Wales.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top)

                        Text("To request deletion of your data, contact: privacy@meridian.io")
                            .font(.caption)
                            .foregroundStyle(Color.meridianAccent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PrivacyItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.meridianAccent)
                .frame(width: 36, height: 36)
                .background(Color.meridianAccent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .meridianCard()
    }
}

struct SupportedCurrency {
    let code: String
    let name: String

    static let all: [SupportedCurrency] = [
        SupportedCurrency(code: "AED", name: "UAE Dirham"),
        SupportedCurrency(code: "AFN", name: "Afghan Afghani"),
        SupportedCurrency(code: "ALL", name: "Albanian Lek"),
        SupportedCurrency(code: "AMD", name: "Armenian Dram"),
        SupportedCurrency(code: "ANG", name: "Netherlands Antillean Guilder"),
        SupportedCurrency(code: "AOA", name: "Angolan Kwanza"),
        SupportedCurrency(code: "ARS", name: "Argentine Peso"),
        SupportedCurrency(code: "AUD", name: "Australian Dollar"),
        SupportedCurrency(code: "AWG", name: "Aruban Florin"),
        SupportedCurrency(code: "AZN", name: "Azerbaijani Manat"),
        SupportedCurrency(code: "BAM", name: "Bosnia-Herzegovina Convertible Mark"),
        SupportedCurrency(code: "BBD", name: "Barbadian Dollar"),
        SupportedCurrency(code: "BDT", name: "Bangladeshi Taka"),
        SupportedCurrency(code: "BGN", name: "Bulgarian Lev"),
        SupportedCurrency(code: "BHD", name: "Bahraini Dinar"),
        SupportedCurrency(code: "BIF", name: "Burundian Franc"),
        SupportedCurrency(code: "BMD", name: "Bermudan Dollar"),
        SupportedCurrency(code: "BND", name: "Brunei Dollar"),
        SupportedCurrency(code: "BOB", name: "Bolivian Boliviano"),
        SupportedCurrency(code: "BRL", name: "Brazilian Real"),
        SupportedCurrency(code: "BSD", name: "Bahamian Dollar"),
        SupportedCurrency(code: "BTN", name: "Bhutanese Ngultrum"),
        SupportedCurrency(code: "BWP", name: "Botswanan Pula"),
        SupportedCurrency(code: "BYN", name: "Belarusian Ruble"),
        SupportedCurrency(code: "BZD", name: "Belize Dollar"),
        SupportedCurrency(code: "CAD", name: "Canadian Dollar"),
        SupportedCurrency(code: "CDF", name: "Congolese Franc"),
        SupportedCurrency(code: "CHF", name: "Swiss Franc"),
        SupportedCurrency(code: "CLP", name: "Chilean Peso"),
        SupportedCurrency(code: "CNY", name: "Chinese Yuan"),
        SupportedCurrency(code: "COP", name: "Colombian Peso"),
        SupportedCurrency(code: "CRC", name: "Costa Rican Colón"),
        SupportedCurrency(code: "CUP", name: "Cuban Peso"),
        SupportedCurrency(code: "CVE", name: "Cape Verdean Escudo"),
        SupportedCurrency(code: "CZK", name: "Czech Koruna"),
        SupportedCurrency(code: "DJF", name: "Djiboutian Franc"),
        SupportedCurrency(code: "DKK", name: "Danish Krone"),
        SupportedCurrency(code: "DOP", name: "Dominican Peso"),
        SupportedCurrency(code: "DZD", name: "Algerian Dinar"),
        SupportedCurrency(code: "EGP", name: "Egyptian Pound"),
        SupportedCurrency(code: "ERN", name: "Eritrean Nakfa"),
        SupportedCurrency(code: "ETB", name: "Ethiopian Birr"),
        SupportedCurrency(code: "EUR", name: "Euro"),
        SupportedCurrency(code: "FJD", name: "Fijian Dollar"),
        SupportedCurrency(code: "GBP", name: "British Pound Sterling"),
        SupportedCurrency(code: "GEL", name: "Georgian Lari"),
        SupportedCurrency(code: "GHS", name: "Ghanaian Cedi"),
        SupportedCurrency(code: "GMD", name: "Gambian Dalasi"),
        SupportedCurrency(code: "GNF", name: "Guinean Franc"),
        SupportedCurrency(code: "GTQ", name: "Guatemalan Quetzal"),
        SupportedCurrency(code: "GYD", name: "Guyanaese Dollar"),
        SupportedCurrency(code: "HKD", name: "Hong Kong Dollar"),
        SupportedCurrency(code: "HNL", name: "Honduran Lempira"),
        SupportedCurrency(code: "HRK", name: "Croatian Kuna"),
        SupportedCurrency(code: "HTG", name: "Haitian Gourde"),
        SupportedCurrency(code: "HUF", name: "Hungarian Forint"),
        SupportedCurrency(code: "IDR", name: "Indonesian Rupiah"),
        SupportedCurrency(code: "ILS", name: "Israeli New Shekel"),
        SupportedCurrency(code: "INR", name: "Indian Rupee"),
        SupportedCurrency(code: "IQD", name: "Iraqi Dinar"),
        SupportedCurrency(code: "IRR", name: "Iranian Rial"),
        SupportedCurrency(code: "ISK", name: "Icelandic Króna"),
        SupportedCurrency(code: "JMD", name: "Jamaican Dollar"),
        SupportedCurrency(code: "JOD", name: "Jordanian Dinar"),
        SupportedCurrency(code: "JPY", name: "Japanese Yen"),
        SupportedCurrency(code: "KES", name: "Kenyan Shilling"),
        SupportedCurrency(code: "KGS", name: "Kyrgystani Som"),
        SupportedCurrency(code: "KHR", name: "Cambodian Riel"),
        SupportedCurrency(code: "KMF", name: "Comorian Franc"),
        SupportedCurrency(code: "KRW", name: "South Korean Won"),
        SupportedCurrency(code: "KWD", name: "Kuwaiti Dinar"),
        SupportedCurrency(code: "KYD", name: "Cayman Islands Dollar"),
        SupportedCurrency(code: "KZT", name: "Kazakhstani Tenge"),
        SupportedCurrency(code: "LAK", name: "Laotian Kip"),
        SupportedCurrency(code: "LBP", name: "Lebanese Pound"),
        SupportedCurrency(code: "LKR", name: "Sri Lankan Rupee"),
        SupportedCurrency(code: "LRD", name: "Liberian Dollar"),
        SupportedCurrency(code: "LSL", name: "Lesotho Loti"),
        SupportedCurrency(code: "LYD", name: "Libyan Dinar"),
        SupportedCurrency(code: "MAD", name: "Moroccan Dirham"),
        SupportedCurrency(code: "MDL", name: "Moldovan Leu"),
        SupportedCurrency(code: "MGA", name: "Malagasy Ariary"),
        SupportedCurrency(code: "MKD", name: "Macedonian Denar"),
        SupportedCurrency(code: "MMK", name: "Myanma Kyat"),
        SupportedCurrency(code: "MNT", name: "Mongolian Tugrik"),
        SupportedCurrency(code: "MOP", name: "Macanese Pataca"),
        SupportedCurrency(code: "MRU", name: "Mauritanian Ouguiya"),
        SupportedCurrency(code: "MUR", name: "Mauritian Rupee"),
        SupportedCurrency(code: "MVR", name: "Maldivian Rufiyaa"),
        SupportedCurrency(code: "MWK", name: "Malawian Kwacha"),
        SupportedCurrency(code: "MXN", name: "Mexican Peso"),
        SupportedCurrency(code: "MYR", name: "Malaysian Ringgit"),
        SupportedCurrency(code: "MZN", name: "Mozambican Metical"),
        SupportedCurrency(code: "NAD", name: "Namibian Dollar"),
        SupportedCurrency(code: "NGN", name: "Nigerian Naira"),
        SupportedCurrency(code: "NIO", name: "Nicaraguan Córdoba"),
        SupportedCurrency(code: "NOK", name: "Norwegian Krone"),
        SupportedCurrency(code: "NPR", name: "Nepalese Rupee"),
        SupportedCurrency(code: "NZD", name: "New Zealand Dollar"),
        SupportedCurrency(code: "OMR", name: "Omani Rial"),
        SupportedCurrency(code: "PAB", name: "Panamanian Balboa"),
        SupportedCurrency(code: "PEN", name: "Peruvian Nuevo Sol"),
        SupportedCurrency(code: "PGK", name: "Papua New Guinean Kina"),
        SupportedCurrency(code: "PHP", name: "Philippine Peso"),
        SupportedCurrency(code: "PKR", name: "Pakistani Rupee"),
        SupportedCurrency(code: "PLN", name: "Polish Zloty"),
        SupportedCurrency(code: "PYG", name: "Paraguayan Guarani"),
        SupportedCurrency(code: "QAR", name: "Qatari Rial"),
        SupportedCurrency(code: "RON", name: "Romanian Leu"),
        SupportedCurrency(code: "RSD", name: "Serbian Dinar"),
        SupportedCurrency(code: "RUB", name: "Russian Ruble"),
        SupportedCurrency(code: "RWF", name: "Rwandan Franc"),
        SupportedCurrency(code: "SAR", name: "Saudi Riyal"),
        SupportedCurrency(code: "SBD", name: "Solomon Islands Dollar"),
        SupportedCurrency(code: "SCR", name: "Seychellois Rupee"),
        SupportedCurrency(code: "SDG", name: "Sudanese Pound"),
        SupportedCurrency(code: "SEK", name: "Swedish Krona"),
        SupportedCurrency(code: "SGD", name: "Singapore Dollar"),
        SupportedCurrency(code: "SHP", name: "Saint Helena Pound"),
        SupportedCurrency(code: "SLL", name: "Sierra Leonean Leone"),
        SupportedCurrency(code: "SOS", name: "Somali Shilling"),
        SupportedCurrency(code: "SRD", name: "Surinamese Dollar"),
        SupportedCurrency(code: "STN", name: "São Tomé and Príncipe Dobra"),
        SupportedCurrency(code: "SVC", name: "Salvadoran Colón"),
        SupportedCurrency(code: "SYP", name: "Syrian Pound"),
        SupportedCurrency(code: "SZL", name: "Swazi Lilangeni"),
        SupportedCurrency(code: "THB", name: "Thai Baht"),
        SupportedCurrency(code: "TJS", name: "Tajikistani Somoni"),
        SupportedCurrency(code: "TMT", name: "Turkmenistani Manat"),
        SupportedCurrency(code: "TND", name: "Tunisian Dinar"),
        SupportedCurrency(code: "TOP", name: "Tongan Paʻanga"),
        SupportedCurrency(code: "TRY", name: "Turkish Lira"),
        SupportedCurrency(code: "TTD", name: "Trinidad and Tobago Dollar"),
        SupportedCurrency(code: "TWD", name: "New Taiwan Dollar"),
        SupportedCurrency(code: "TZS", name: "Tanzanian Shilling"),
        SupportedCurrency(code: "UAH", name: "Ukrainian Hryvnia"),
        SupportedCurrency(code: "UGX", name: "Ugandan Shilling"),
        SupportedCurrency(code: "USD", name: "US Dollar"),
        SupportedCurrency(code: "UYU", name: "Uruguayan Peso"),
        SupportedCurrency(code: "UZS", name: "Uzbekistan Som"),
        SupportedCurrency(code: "VES", name: "Venezuelan Bolívar"),
        SupportedCurrency(code: "VND", name: "Vietnamese Dong"),
        SupportedCurrency(code: "VUV", name: "Vanuatu Vatu"),
        SupportedCurrency(code: "WST", name: "Samoan Tala"),
        SupportedCurrency(code: "XAF", name: "CFA Franc BEAC"),
        SupportedCurrency(code: "XCD", name: "East Caribbean Dollar"),
        SupportedCurrency(code: "XOF", name: "CFA Franc BCEAO"),
        SupportedCurrency(code: "XPF", name: "CFP Franc"),
        SupportedCurrency(code: "YER", name: "Yemeni Rial"),
        SupportedCurrency(code: "ZAR", name: "South African Rand"),
        SupportedCurrency(code: "ZMW", name: "Zambian Kwacha"),
        SupportedCurrency(code: "ZWL", name: "Zimbabwean Dollar")
    ]
}

#Preview {
    SettingsView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
