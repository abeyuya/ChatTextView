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
                let r = TextTypeEmoji(
                    displayImage: nil,
                    escapedString: usedEmoji.escapedString,
                    size: .zero
                )
                result.append(TextType.emoji(r))
                continue
            }

            let r = attributedText.attributedSubstring(from: NSRange(location: i, length: 1))
            result.append(TextType.plain(r.string))
        }

        return result
    }
}
