//
//  Parser.swift
//  ChatTextView
//
//  Created by abeyuya on 2020/01/06.
//

import Foundation

public struct TextTypeMention: Equatable {
    public let displayString: String
    public let metadata: String

    public init(displayString: String, metadata: String) {
        self.displayString = displayString
        self.metadata = metadata
    }
}

public struct TextTypeCustomEmoji: Hashable {
    public let displayImageUrl: URL
    public let escapedString: String

    public init(displayImageUrl: URL, escapedString: String) {
        self.displayImageUrl = displayImageUrl
        self.escapedString = escapedString
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
internal let customEmojiIdAttrKey = NSAttributedString.Key(rawValue: "customEmojiId")
internal let mentionIdAttrKey = NSAttributedString.Key(rawValue: "mentionId")

enum Parser {
    static func parse(
        attributedText: NSAttributedString,
        usedEmojis: [TextTypeCustomEmoji],
        usedMentions: [TextTypeMention]
    ) -> [TextType] {
        var result: [TextType] = []
        var allCharacterLength = 0

        let string = attributedText.string
        for i in 0..<(string.count) {
            let character = String(Array(string)[i])
            let characterLength = utf16Length(string: character)

            defer {
                allCharacterLength += characterLength
            }

            let attr = getAttributes(index: allCharacterLength, attributedText: attributedText)

            // customEmoji
            if let v = character.utf16.first, v == customEmojiUtf16Value {
                if let emojiImageUrl = attr[customEmojiImageUrlAttrKey] as? String,
                    let usedEmoji = usedEmojis.first(where: { $0.displayImageUrl.absoluteString == emojiImageUrl }) {
                    result.append(TextType.customEmoji(usedEmoji))
                }
                continue
            }

            // mention
            if let mentionId = attr[mentionIdAttrKey] as? String, !mentionId.isEmpty {
                let m = TextTypeMention(
                    displayString: character,
                    metadata: ""
                )
                result.append(TextType.mention(m))
                continue
            }

            // plain
            result.append(TextType.plain(character))
        }

        return bundle(parsedResult: result, usedMentions: usedMentions)
    }

    private static func getAttributes(
        index: Int,
        attributedText: NSAttributedString
    ) -> [NSAttributedString.Key : Any] {

        let attr = attributedText.attributes(at: index, effectiveRange: nil)
        return attr
    }

    private static func utf16Length(string: String) -> Int {
        return string.utf16.count
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

        return result
    }
}
