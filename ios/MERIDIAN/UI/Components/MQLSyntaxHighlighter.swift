import Foundation
import SwiftUI

struct MQLSyntaxHighlighter {
    private let keywordColour = Color.meridianAccent
    private let stringColour = Color.meridianGreen
    private let numberColour = Color.meridianGold
    private let operatorColour = Color.white
    private let commentColour = Color(hex: "#6B7280")
    private let defaultColour = Color.primary

    private let keywords: Set<String> = [
        "SCAN", "SHOW", "OPPORTUNITIES", "WHERE", "ALERT", "HELP",
        "AND", "OR", "NOT", "ABOVE", "BELOW", "SCORE", "MARKET",
        "GEOGRAPHY", "CURRENCY", "TOP", "LIMIT", "ORDER", "BY",
        "ASC", "DESC", "FILTER", "GENERATE", "CREATIVE", "FOR"
    ]

    private let operatorTokens: Set<String> = [">", "<", ">=", "<=", "==", "!=", "=", "+", "-", "*", "/"]

    func highlight(_ text: String) -> AttributedString {
        var result = AttributedString(text)

        let tokens = tokenise(text)
        var charIndex = text.startIndex

        for token in tokens {
            guard let range = findRange(of: token.value, in: text, from: charIndex) else { continue }

            let attrRange = AttributedString.Index(range.lowerBound, within: result)!
                ..< AttributedString.Index(range.upperBound, within: result)!

            var colour: Color
            switch token.type {
            case .keyword:
                colour = keywordColour
            case .string:
                colour = stringColour
            case .number:
                colour = numberColour
            case .operator_:
                colour = operatorColour
            case .comment:
                colour = commentColour
            case .default_:
                colour = defaultColour
            }

            result[attrRange].foregroundColor = colour

            if token.type == .keyword {
                result[attrRange].font = .system(.body, design: .monospaced).bold()
            } else {
                result[attrRange].font = .system(.body, design: .monospaced)
            }

            charIndex = range.upperBound
        }

        return result
    }

    private func tokenise(_ text: String) -> [Token] {
        var tokens: [Token] = []
        var remaining = text
        var position = text.startIndex

        while position < text.endIndex {
            let char = text[position]

            if char == "-" && text.index(after: position) < text.endIndex && text[text.index(after: position)] == "-" {
                let lineEnd = text[position...].firstIndex(of: "\n") ?? text.endIndex
                let comment = String(text[position..<lineEnd])
                tokens.append(Token(type: .comment, value: comment))
                position = lineEnd
                if position < text.endIndex { position = text.index(after: position) }
                continue
            }

            if char == "\"" || char == "'" {
                let quote = char
                var end = text.index(after: position)
                while end < text.endIndex && text[end] != quote {
                    end = text.index(after: end)
                }
                if end < text.endIndex {
                    end = text.index(after: end)
                }
                let str = String(text[position..<end])
                tokens.append(Token(type: .string, value: str))
                position = end
                continue
            }

            if char.isNumber {
                var end = position
                while end < text.endIndex && (text[end].isNumber || text[end] == ".") {
                    end = text.index(after: end)
                }
                let number = String(text[position..<end])
                tokens.append(Token(type: .number, value: number))
                position = end
                continue
            }

            if char.isLetter || char == "_" {
                var end = position
                while end < text.endIndex && (text[end].isLetter || text[end].isNumber || text[end] == "_") {
                    end = text.index(after: end)
                }
                let word = String(text[position..<end])
                let type: TokenType = keywords.contains(word.uppercased()) ? .keyword : .default_
                tokens.append(Token(type: type, value: word))
                position = end
                continue
            }

            let opStr = String(char)
            if operatorTokens.contains(opStr) {
                tokens.append(Token(type: .operator_, value: opStr))
            } else {
                tokens.append(Token(type: .default_, value: opStr))
            }
            position = text.index(after: position)
        }

        return tokens
    }

    private func findRange(of value: String, in text: String, from start: String.Index) -> Range<String.Index>? {
        guard start <= text.endIndex else { return nil }
        return text.range(of: value, options: [], range: start..<text.endIndex)
    }
}

private enum TokenType {
    case keyword
    case string
    case number
    case operator_
    case comment
    case default_
}

private struct Token {
    let type: TokenType
    let value: String
}

struct HighlightedMQLText: View {
    let text: String
    private let highlighter = MQLSyntaxHighlighter()

    var body: some View {
        Text(highlighter.highlight(text))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        HighlightedMQLText(text: "SCAN shopify.com")
        HighlightedMQLText(text: "SHOW OPPORTUNITIES WHERE score > 80")
        HighlightedMQLText(text: "ALERT GBP/USD ABOVE 1.30")
        HighlightedMQLText(text: "-- This is a comment")
        HighlightedMQLText(text: "ORDER BY score DESC LIMIT 10")
    }
    .padding()
    .meridianBackground()
    .preferredColorScheme(.dark)
}
