//
//  Parser.swift
//  ChatTextView
//
//  Created by abeyuya on 2020/01/06.
//

import Foundation

public struct TextTypeMension {
    let displayString: String
    let escapedString: String
}

public struct TextTypeEmoji: Hashable {
    public let displayImage: UIImage?
    public let escapedString: String
    public let size: CGSize

    public init(displayImage: UIImage?, escapedString: String, size: CGSize) {
        self.displayImage = displayImage
        self.escapedString = escapedString
        self.size = size
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.escapedString)
    }
}

public enum TextType {
    case plain(String)
    //    case mention(TextTypeMension)
    case emoji(TextTypeEmoji)
}

enum Parser {
    static func parse(attributedText: NSAttributedString, usedEmojis: [TextTypeEmoji]) -> [TextType] {
        var result: [TextType] = []

        for i in 0..<(attributedText.length) {
            let str = attributedText.attributes(at: i, effectiveRange: nil)

            if let emoji = str[.attachment] as? NSTextAttachment,
                let usedEmoji = usedEmojis.first(where: { $0.displayImage == emoji.image }) {
                result.append(TextType.emoji(usedEmoji))
                continue
            }

            let r = attributedText.attributedSubstring(from: NSRange(location: i, length: 1))
            result.append(TextType.plain(r.string))
        }

        return bundle(parsedResult: result)
    }

    private static func bundle(parsedResult: [TextType]) -> [TextType] {
        var result: [TextType] = []
        var prev: TextType?
        var bundlingPlain: String?

        for t in parsedResult {
            defer {
                prev = t
            }

            switch t {
            case .emoji:
                if let b = bundlingPlain {
                    result.append(TextType.plain(b))
                    bundlingPlain = nil
                }
                result.append(t)
                continue
            case .plain(let string):
                guard let p = prev else {
                    bundlingPlain = string
                    continue
                }
                switch p {
                case .plain:
                    bundlingPlain?.append(string)
                case .emoji:
                    bundlingPlain = string
                }
            }
        }

        if let b = bundlingPlain {
            result.append(TextType.plain(b))
            bundlingPlain = nil
        }

        return result
    }
}
