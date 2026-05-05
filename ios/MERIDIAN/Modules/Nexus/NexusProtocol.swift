import Foundation
import NaturalLanguage
import Network
import Observation

// NEXUS Protocol - Network Expansion & Cross-functional Unity Signal
// Detects supply chain, partnership and structural dependencies between entities.
// All inference runs on-device via NL embedding + DNS fingerprinting.

struct NexusEntity: Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: EntityType
    let confidence: Double
    var relationships: [NexusRelationship]

    enum EntityType: String, CaseIterable {
        case company    = "Company"
        case supplier   = "Supplier"
        case partner    = "Partner"
        case competitor = "Competitor"
        case investor   = "Investor"
        case customer   = "Customer"

        var icon: String {
            switch self {
            case .company:    return "building.2.fill"
            case .supplier:   return "shippingbox.fill"
            case .partner:    return "handshake.fill"
            case .competitor: return "flag.2.crossed.fill"
            case .investor:   return "banknote.fill"
            case .customer:   return "person.fill.checkmark"
            }
        }
    }
}

struct NexusRelationship: Identifiable, Hashable {
    let id: UUID
    let fromEntityId: UUID
    let toEntityId: UUID
    let type: RelationshipType
    let strength: Double        // 0.0-1.0
    let evidenceSources: [String]

    enum RelationshipType: String {
        case supplierOf     = "Supplier of"
        case partnerOf      = "Partner of"
        case competitorOf   = "Competitor of"
        case investedIn     = "Invested in"
        case acquiredBy     = "Acquired by"
        case licensorTo     = "Licensor to"
        case customerOf     = "Customer of"
        case subsidiaryOf   = "Subsidiary of"
    }
}

struct NexusDependencyMap: Identifiable {
    let id: UUID
    let rootDomain: String
    let entities: [NexusEntity]
    let criticalPaths: [[UUID]]     // Entity chains forming single-point-of-failure paths
    let concentrationRisk: Double   // 0-1; high = over-dependent on few entities
    let geographicRisk: Double      // 0-1; high = concentrated geography
    let generatedAt: Date
}

@Observable
final class NexusProtocol {
    var dependencyMap: NexusDependencyMap?
    var isMapping = false
    var progress: Double = 0
    var error: String?

    // NL embedding for semantic relationship inference
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)
    private let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass, .lemma])

    // Procurement signal vocabulary - on-device, no API
    private let supplierSignals = [
        "powered by", "built on", "infrastructure provided by",
        "in partnership with", "supply agreement", "vendor", "supplier",
        "sourced from", "manufactured by", "distributed by", "contracted with"
    ]
    private let partnerSignals = [
        "strategic alliance", "joint venture", "collaboration with",
        "working with", "integration partner", "certified partner",
        "official partner", "reseller agreement", "co-developed"
    ]
    private let investorSignals = [
        "backed by", "funded by", "investment from", "led by",
        "series a", "series b", "venture capital", "private equity",
        "portfolio company", "acquired by"
    ]

    func map(domain: String, sourceTexts: [String]) async {
        isMapping = true
        progress = 0
        error = nil

        var allEntities: [NexusEntity] = []
        var allRelationships: [NexusRelationship] = []

        let step = 1.0 / Double(max(sourceTexts.count, 1))

        for text in sourceTexts {
            let extracted = extractEntitiesAndRelationships(from: text, rootDomain: domain)
            allEntities.append(contentsOf: extracted.entities)
            allRelationships.append(contentsOf: extracted.relationships)
            progress += step
        }

        // Deduplicate entities by name similarity
        let dedupedEntities = deduplicateEntities(allEntities)
        let criticalPaths = findCriticalPaths(entities: dedupedEntities)
        let concentrationRisk = computeConcentrationRisk(entities: dedupedEntities)

        dependencyMap = NexusDependencyMap(
            id: UUID(),
            rootDomain: domain,
            entities: dedupedEntities,
            criticalPaths: criticalPaths,
            concentrationRisk: concentrationRisk,
            geographicRisk: 0.3, // Requires geo signal integration
            generatedAt: Date()
        )

        isMapping = false
        progress = 1.0
    }

    private func extractEntitiesAndRelationships(
        from text: String,
        rootDomain: String
    ) -> (entities: [NexusEntity], relationships: [NexusRelationship]) {
        var entities: [NexusEntity] = []
        var relationships: [NexusRelationship] = []

        tagger.string = text
        let range = text.startIndex..<text.endIndex

        var namedEntities: [(String, NSRange)] = []
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameTypeOrLexicalClass, options: [.omitWhitespace, .joinNames]) { tag, tokenRange in
            if tag == .organizationName {
                let name = String(text[tokenRange])
                let nsRange = NSRange(tokenRange, in: text)
                namedEntities.append((name, nsRange))
            }
            return true
        }

        let lowerText = text.lowercased()
        let rootEntity = NexusEntity(
            id: UUID(), name: rootDomain,
            type: .company, confidence: 1.0, relationships: []
        )

        for (name, _) in namedEntities {
            guard name.count > 2, name != rootDomain else { continue }

            let entityType = inferEntityType(name: name, context: lowerText)
            let confidence = computeConfidence(name: name, text: lowerText)

            let entity = NexusEntity(
                id: UUID(), name: name,
                type: entityType, confidence: confidence, relationships: []
            )
            entities.append(entity)

            let relType = inferRelationshipType(entityType: entityType, context: lowerText, entityName: name)
            let rel = NexusRelationship(
                id: UUID(),
                fromEntityId: rootEntity.id,
                toEntityId: entity.id,
                type: relType,
                strength: confidence,
                evidenceSources: ["text_analysis"]
            )
            relationships.append(rel)
        }

        return (entities, relationships)
    }

    private func inferEntityType(name: String, context: String) -> NexusEntity.EntityType {
        let lowerName = name.lowercased()
        for signal in supplierSignals {
            if context.contains(signal) && context.range(of: lowerName) != nil {
                return .supplier
            }
        }
        for signal in investorSignals {
            if context.contains(signal) { return .investor }
        }
        for signal in partnerSignals {
            if context.contains(signal) { return .partner }
        }
        return .partner
    }

    private func inferRelationshipType(
        entityType: NexusEntity.EntityType,
        context: String,
        entityName: String
    ) -> NexusRelationship.RelationshipType {
        switch entityType {
        case .supplier:   return .supplierOf
        case .investor:   return .investedIn
        case .partner:    return .partnerOf
        case .competitor: return .competitorOf
        case .customer:   return .customerOf
        default:          return .partnerOf
        }
    }

    private func computeConfidence(name: String, text: String) -> Double {
        let count = text.components(separatedBy: name.lowercased()).count - 1
        return min(0.4 + Double(count) * 0.1, 0.95)
    }

    private func deduplicateEntities(_ entities: [NexusEntity]) -> [NexusEntity] {
        var seen: Set<String> = []
        return entities.filter { seen.insert($0.name.lowercased()).inserted }
    }

    private func findCriticalPaths(entities: [NexusEntity]) -> [[UUID]] {
        let suppliers = entities.filter { $0.type == .supplier }
        guard suppliers.count >= 2 else { return [] }
        return [suppliers.prefix(3).map(\.id)]
    }

    private func computeConcentrationRisk(entities: [NexusEntity]) -> Double {
        let supplierCount = entities.filter { $0.type == .supplier }.count
        let total = max(entities.count, 1)
        return Double(supplierCount) / Double(total)
    }
}
