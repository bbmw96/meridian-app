import Foundation

private struct CacheEntry<T> {
    let value: T
    let expiresAt: Date
    var isExpired: Bool { Date() > expiresAt }
}

actor CacheManager {
    static let shared = CacheManager()

    private var store: [String: Any] = [:]
    private let maxEntries = 256

    private init() {}

    func cache<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval) {
        if store.count >= maxEntries {
            evictOldest()
        }
        let entry = CacheEntry(value: value, expiresAt: Date().addingTimeInterval(ttl))
        store[key] = entry
    }

    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let entry = store[key] as? CacheEntry<T> else { return nil }
        if entry.isExpired {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func invalidate(key: String) {
        store.removeValue(forKey: key)
    }

    func invalidatePrefix(_ prefix: String) {
        let keysToRemove = store.keys.filter { $0.hasPrefix(prefix) }
        keysToRemove.forEach { store.removeValue(forKey: $0) }
    }

    func clearAll() {
        store.removeAll()
    }

    private func evictOldest() {
        let now = Date()
        let expiredKeys = store.keys.filter { key in
            guard let entry = store[key] as? (any HasExpiry) else { return true }
            return entry.expired(at: now)
        }
        if !expiredKeys.isEmpty {
            expiredKeys.forEach { store.removeValue(forKey: $0) }
        } else {
            if let first = store.keys.first {
                store.removeValue(forKey: first)
            }
        }
    }
}

private protocol HasExpiry {
    func expired(at date: Date) -> Bool
}

extension CacheEntry: HasExpiry {
    func expired(at date: Date) -> Bool { date > expiresAt }
}

extension CacheManager {
    static let domainTTL: TimeInterval = 300
    static let ratesTTL: TimeInterval = 30
    static let opportunitiesTTL: TimeInterval = 120

    func cacheDomain(_ profile: DomainProfile) async {
        cache(profile, forKey: "domain_\(profile.url)", ttl: CacheManager.domainTTL)
    }

    func retrieveDomain(url: String) async -> DomainProfile? {
        retrieve(DomainProfile.self, forKey: "domain_\(url)")
    }

    func cacheRates(_ rates: [CurrencyRate], pair: String) async {
        cache(rates, forKey: "rates_\(pair)", ttl: CacheManager.ratesTTL)
    }

    func retrieveRates(pair: String) async -> [CurrencyRate]? {
        retrieve([CurrencyRate].self, forKey: "rates_\(pair)")
    }

    func cacheOpportunities(_ opportunities: [Opportunity]) async {
        cache(opportunities, forKey: "opportunities", ttl: CacheManager.opportunitiesTTL)
    }

    func retrieveOpportunities() async -> [Opportunity]? {
        retrieve([Opportunity].self, forKey: "opportunities")
    }
}
