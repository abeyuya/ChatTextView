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

public struct TextTypeCustomEmoji: Hashable {
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
    case customEmoji(TextTypeCustomEmoji)
}

private let customAttrKey = NSAttributedString.Key(rawValue: "ChatTextView")
private let customEmojiUtf16Value = 65532

enum Parser {
    static func parse(attributedText: NSAttributedString, usedEmojis: [TextTypeCustomEmoji]) -> [TextType] {
        var result: [TextType] = []

        let string = attributedText.string
        for i in 0..<(string.count) {
            let character = String(Array(string)[i])

            // customEmoji
            if let v = character.utf16.first, v == customEmojiUtf16Value {
                let startIndex: Int = {
                    if i == 0 {
                        return 0
                    }

                    var offset = 0
                    for j in 0..<i {
                        let c = String(Array(string)[j])
                        offset += c.utf16.count
                    }
                    return offset
                }()

                let attr = attributedText.attributes(at: startIndex, effectiveRange: nil)

                if let emoji = attr[.attachment] as? NSTextAttachment,
                    let usedEmoji = usedEmojis.first(where: { $0.displayImage == emoji.image }) {
                    result.append(TextType.customEmoji(usedEmoji))
                }
                continue
            }

            // plain
            result.append(TextType.plain(character))
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
            case .customEmoji:
                if let b = bundlingPlain {
                    result.append(TextType.plain(b))
                    bundlingPlain = nil
                }
                result.append(t)
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
