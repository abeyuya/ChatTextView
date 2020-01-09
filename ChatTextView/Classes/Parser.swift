//
//  Parser.swift
//  ChatTextView
//
//  Created by abeyuya on 2020/01/06.
//

import Foundation

public struct TextTypeMention: Equatable {
    public let displayString: String
    public let hiddenString: String

    public init(displayString: String, hiddenString: String) {
        self.displayString = displayString
        self.hiddenString = hiddenString
    }
}

public struct TextTypeCustomEmoji: Hashable {
    public let displayImageUrl: URL
    public let escapedString: String
    public let size: CGSize

    public init(displayImageUrl: URL, escapedString: String, size: CGSize) {
        self.displayImageUrl = displayImageUrl
        self.escapedString = escapedString
        self.size = size
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.escapedString)
    }
}

public enum TextType: Equatable {
    case plain(String)
    case mention(TextTypeMention)
    case customEmoji(TextTypeCustomEmoji)
}

private let customEmojiUtf16Value = 65532

internal let customEmojiImageUrlAttrKey = NSAttributedString.Key(rawValue: "customEmojiImageUrl")
internal let customEmojiIdAttrKey = NSAttributedString.Key(rawValue: "customEmojiIdImageUrl")
internal let mentionAttrKey = NSAttributedString.Key(rawValue: "mention")

enum Parser {
    static func parse(
        attributedText: NSAttributedString,
        usedEmojis: [TextTypeCustomEmoji],
        usedMentions: [TextTypeMention]
    ) -> [TextType] {
        var result: [TextType] = []

        let string = attributedText.string
        for i in 0..<(string.count) {
            let character = String(Array(string)[i])

            let lengthIndex = convertToLengthIndex(at: i, attributedString: attributedText)
            let attr = attributedText.attributes(at: lengthIndex, effectiveRange: nil)

            // customEmoji
            if let v = character.utf16.first, v == customEmojiUtf16Value {
                if let emojiImageUrl = attr[customEmojiImageUrlAttrKey] as? String,
                    let usedEmoji = usedEmojis.first(where: { $0.displayImageUrl.absoluteString == emojiImageUrl }) {
                    result.append(TextType.customEmoji(usedEmoji))
                }
                continue
            }

            // mention
            if let isMention = attr[mentionAttrKey] as? Bool, isMention {
                let m = TextTypeMention(
                    displayString: character,
                    hiddenString: character
                )
                result.append(TextType.mention(m))
                continue
            }

            // plain
            result.append(TextType.plain(character))
        }

        return bundle(parsedResult: result, usedMentions: usedMentions)
    }

    private static func convertToLengthIndex(at: Int, attributedString: NSAttributedString) -> Int {
        let string = attributedString.string

        let startIndex: Int = {
            if at == 0 {
                return 0
            }

            var offset = 0
            for j in 0..<at {
                let c = String(Array(string)[j])
                offset += c.utf16.count
            }
            return offset
        }()

        return startIndex
    }

    private static func bundle(
        parsedResult: [TextType],
        usedMentions: [TextTypeMention]
    ) -> [TextType] {
        var result: [TextType] = []
        var prev: TextType?
        var bundlingPlain: String?
        var bundlingMention: String?

        let insertBundlingPlain = {
            guard let b = bundlingPlain else { return }
            result.append(TextType.plain(b))
            bundlingPlain = nil
        }
        let insertBundlingMention = {
            guard let b = bundlingMention else { return }
            guard let usedMention = usedMentions.first(where: { $0.displayString == b }) else { return }
            result.append(TextType.mention(usedMention))
            bundlingMention = nil
        }

        for t in parsedResult {
            defer {
                prev = t
            }

            switch t {
            case .plain(let string):
                guard let p = prev else {
                    bundlingPlain = string
                    continue
                }
                switch p {
                case .plain:
                    bundlingPlain?.append(string)
                case .customEmoji:
                    bundlingPlain = string
                case .mention:
                    insertBundlingMention()
                    bundlingPlain = string
                }
            case .customEmoji:
                insertBundlingPlain()
                insertBundlingMention()
                result.append(t)
            case .mention(let value):
                guard let p = prev else {
                    bundlingMention = value.displayString
                    continue
                }
                switch p {
                case .mention:
                    bundlingMention?.append(value.displayString)
                case .customEmoji, .plain:
                    insertBundlingPlain()
                    insertBundlingMention()
                    bundlingMention = value.displayString
                }
            }
        }

        insertBundlingPlain()
        insertBundlingMention()

        return removeInvalidMentions(textTypes: result, usedMentions: usedMentions)
    }

    private static func removeInvalidMentions(
        textTypes: [TextType],
        usedMentions: [TextTypeMention]
    ) -> [TextType] {
        return textTypes.filter { t in
            switch t {
            case .plain, .customEmoji:
                return true
            case .mention(let value):
                let existValid = usedMentions.first(where: { $0.displayString == value.displayString })

                return existValid != nil
            }
        }
    }
}
