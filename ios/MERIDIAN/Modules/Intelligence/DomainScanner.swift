import Foundation

struct DomainScanner {
    private let validTLDs = Set([
        "com", "co.uk", "io", "net", "org", "gov", "edu", "co", "app",
        "dev", "ai", "tech", "store", "shop", "online", "info", "biz",
        "uk", "us", "eu", "de", "fr", "es", "it", "nl", "au", "ca",
        "jp", "cn", "br", "in", "ru", "pl", "se", "no", "dk", "fi",
        "ch", "at", "be", "sg", "nz", "za", "mx", "ar", "ae", "hk"
    ])

    func normalise(input: String) -> String {
        var result = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let prefixes = ["https://www.", "http://www.", "https://", "http://", "www."]
        for prefix in prefixes {
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
                break
            }
        }

        if let slashIndex = result.firstIndex(of: "/") {
            result = String(result[result.startIndex..<slashIndex])
        }

        if let queryIndex = result.firstIndex(of: "?") {
            result = String(result[result.startIndex..<queryIndex])
        }

        if let hashIndex = result.firstIndex(of: "#") {
            result = String(result[result.startIndex..<hashIndex])
        }

        return result
    }

    func isValid(domain: String) -> Bool {
        let normalised = normalise(input: domain)

        guard !normalised.isEmpty else { return false }
        guard normalised.count >= 3 && normalised.count <= 253 else { return false }
        guard !normalised.hasPrefix("-") && !normalised.hasSuffix("-") else { return false }
        guard normalised.contains(".") else { return false }

        let parts = normalised.components(separatedBy: ".")
        guard parts.count >= 2 else { return false }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        for part in parts {
            guard !part.isEmpty else { return false }
            guard part.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else { return false }
        }

        let tld = parts.suffix(2).joined(separator: ".")
        let simpleTLD = parts.last ?? ""
        return validTLDs.contains(tld) || validTLDs.contains(simpleTLD) || simpleTLD.count >= 2
    }

    func extractDomainName(from domain: String) -> String {
        let parts = domain.components(separatedBy: ".")
        if parts.count >= 2 {
            return parts[parts.count - 2].capitalized
        }
        return domain.capitalized
    }

    func guessFromQRCode(_ rawValue: String) -> String? {
        let normalised = normalise(input: rawValue)
        return isValid(domain: normalised) ? normalised : nil
    }
}
