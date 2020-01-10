//
//  ChatTextView.swift
//  ChatTextView
//
//  Created by abeyuya on 2020/01/06.
//

import UIKit

public protocol ChatTextViewDelegate: class {
    func didChange(textTypes: [TextType])
}

public class ChatTextView: UITextView {
    struct RenderingGifImageView {
        let id: String
        let imageView: UIImageView
    }

    // settings
    var maxHeight: CGFloat?
    var defaultTextColor: UIColor = .black

    var chatTextViewDelegate: ChatTextViewDelegate?
    var heightLayoutConstraint: NSLayoutConstraint? {
        self.constraints.first { c in
            return c.firstAttribute == .height
        }
    }
    var usedEmojis: [TextTypeCustomEmoji] = []
    var usedMentions: [TextTypeMention] = []
    var renderingGifImageViews: [RenderingGifImageView] = []

    public func setup(delegate: ChatTextViewDelegate) {
        self.delegate = self
        self.chatTextViewDelegate = delegate
        setEmptyHeight()
    }

    public func insert(emoji: TextTypeCustomEmoji, completion: @escaping () -> Void) {
        render(idPrefix: UUID().uuidString, customEmoji: emoji) {
            self.textViewDidChange(self)
            completion()
        }
    }

    public func insert(mention: TextTypeMention) {
        render(mention: mention)
        insert(plain: " ")
    }

    public func insert(plain: String) {
        render(plain: plain)
        textViewDidChange(self)
    }

    public func getCurrentTextTypes() -> [TextType] {
        let parsed = Parser.parse(
            attributedText: attributedText,
            usedEmojis: usedEmojis,
            usedMentions: usedMentions
        )
        return parsed
    }

    public func clear() {
        self.text = ""
        self.attributedText = NSAttributedString()
        textViewDidChange(self)
        setEmptyHeight()
        removeAllAnimatedGif()
        usedMentions = []
    }
}

private extension ChatTextView {
    func render(mention: TextTypeMention) {
        usedMentions.append(mention)
        let attrString = NSAttributedString(
            string: mention.displayString,
            attributes: [
                .foregroundColor: UIColor.blue,
                mentionIdAttrKey: UUID().uuidString
            ]
        )

        let origin = NSMutableAttributedString(attributedString: self.attributedText)
        origin.insert(attrString, at: currentCursorPosition())
        self.attributedText = origin
    }

    func render(
        idPrefix: String,
        customEmoji: TextTypeCustomEmoji,
        completion: @escaping () -> Void
    ) {
        usedEmojis.append(customEmoji)
        usedEmojis = Array(Set(usedEmojis))
        let id = "\(idPrefix)-\(customEmoji.displayImageUrl.absoluteString)"

        if self.renderingGifImageViews.first(where: { $0.id == id }) != nil {
            return
        }

        let cursorPosition = currentCursorPosition()

        createAnimatedImage(imageUrl: customEmoji.displayImageUrl) { image in
            let attarchment = NSTextAttachment()
            if customEmoji.displayImageUrl.pathExtension != "gif" {
                attarchment.image = image
            } else {
                attarchment.image = UIImage()
            }
            attarchment.bounds = .init(origin: .zero, size: customEmoji.size)
            let attr = NSMutableAttributedString(attachment: attarchment)
            attr.addAttributes(
                [
                    customEmojiImageUrlAttrKey: customEmoji.displayImageUrl.absoluteString,
                    customEmojiIdAttrKey: id
                ],
                range: NSRange(location: 0, length: attr.length)
            )

            let origin = NSMutableAttributedString(attributedString: self.attributedText)
            origin.insert(attr, at: cursorPosition)
            self.attributedText = origin
            completion()
        }
    }

    func render(plain: String) {
        let attr = NSAttributedString(string: plain)
        let origin = NSMutableAttributedString(attributedString: attributedText)
        origin.insert(attr, at: currentCursorPosition())
        attributedText = origin
    }

    func setEmptyHeight() {
        let newFrame = calcLimitedFrame(text: "")
        update(frame: newFrame)
    }

    func calcLimitedFrame(text: String?) -> CGRect {
        let rawFrame = calcFrame(text: text)
        let height: CGFloat = {
            if rawFrame.size.height < (maxHeight ?? calcDefaultMaxFrame().size.height) {
                return rawFrame.size.height
            }
            return maxHeight ?? calcDefaultMaxFrame().size.height
        }()

        var newFrame = rawFrame

        newFrame.size = CGSize(
            width: rawFrame.size.width,
            height: height
        )
        return newFrame
    }

    func calcFrame(text: String?) -> CGRect {
        guard let textView = try? self.copyObject() as? UITextView else {
            return .zero
        }

        textView.text = text ?? ""
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(
            width: fixedWidth,
            height: CGFloat.greatestFiniteMagnitude
        ))
        let newSize = textView.sizeThatFits(CGSize(
            width: fixedWidth,
            height: CGFloat.greatestFiniteMagnitude
        ))
        var newFrame = textView.frame
        newFrame.size = CGSize(
            width: max(newSize.width, fixedWidth),
            height: newSize.height
        )
        return newFrame
    }

    func calcDefaultMaxFrame() -> CGRect {
        return calcFrame(text: "\n\n\n")
    }

    func update(frame: CGRect) {
        if self.translatesAutoresizingMaskIntoConstraints {
            self.frame = frame
        } else {
            heightLayoutConstraint?.constant = frame.size.height
        }
    }

    func currentCursorPosition() -> Int {
        guard let selectedRange = selectedTextRange else { return 0 }
        let cursorPosition = offset(
            from: beginningOfDocument,
            to: selectedRange.start
        )
        return cursorPosition
    }

    func createAnimatedImage(imageUrl: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            if imageUrl.pathExtension == "gif" {
                let i = UIImage.gifImageWithURL(imageUrl.absoluteString)
                DispatchQueue.main.async {
                    completion(i)
                }
                return
            }

            guard let data = try? Data(contentsOf: imageUrl) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let i = UIImage(data: data)
            DispatchQueue.main.async {
                completion(i)
            }
        }
    }

    func updateAnimatedGif() {
        let lastCursorPosition = currentCursorPosition()
        let fullRange = NSRange(location: 0, length: attributedText.length)

        attributedText.enumerateAttribute(
            customEmojiImageUrlAttrKey,
            in: fullRange,
            options: []
        ) { urlString, range, _ in
            guard let u = urlString as? String, let url = URL(string: u) else { return }
            guard url.pathExtension == "gif" else { return }
            guard let usingEmoji = usedEmojis.first(where: { $0.displayImageUrl.absoluteString == u }) else { return }

            let attr = attributedText.attributedSubstring(from: range)
            guard let id = attr.attribute(customEmojiIdAttrKey, at: 0, effectiveRange: nil) as? String else { return }

            selectedRange = range
            defer {
                selectedRange = NSRange(location: lastCursorPosition, length: 0)
            }

            guard let selectedTextRange = selectedTextRange else { return }
            var rect = firstRect(for: selectedTextRange)
            rect.origin.y += (rect.size.height - usingEmoji.size.height)
            rect.size = usingEmoji.size

            if let v = renderingGifImageViews.first(where: { $0.id == id }) {
                v.imageView.frame = rect
                return
            }

            createAnimatedImage(imageUrl: url) { image in
                let iv = UIImageView(frame: rect)
                iv.image = image
                self.addSubview(iv)
                self.renderingGifImageViews.append(RenderingGifImageView(id: id, imageView: iv))
            }
        }
    }

    func removeAllAnimatedGif() {
        renderingGifImageViews.forEach { $0.imageView.removeFromSuperview() }
        renderingGifImageViews = []
    }
}

private extension NSObject {
    func copyObject<T:NSObject>() throws -> T? {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject:self,
            requiringSecureCoding:false
        )
        return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
    }
}

extension ChatTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        textView.typingAttributes = [
            .foregroundColor: defaultTextColor
        ]
        let parsed = Parser.parse(
            attributedText: textView.attributedText,
            usedEmojis: usedEmojis,
            usedMentions: usedMentions
        )

        let newFrame = calcLimitedFrame(text: text)
        update(frame: newFrame)
        updateAnimatedGif()
        self.chatTextViewDelegate?.didChange(textTypes: parsed)
    }

    public func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard text.isEmpty else { return true }
        let attrText = textView.attributedText.attributedSubstring(from: range)

        if attrText.string.isEmpty {
            // all character deleted
            removeAllAnimatedGif()
            usedMentions = []
            return true
        }

        // delete custom emoji
        if let id = attrText.attribute(customEmojiIdAttrKey, at: 0, effectiveRange: nil) as? String {
            if let i = renderingGifImageViews.firstIndex(where: { $0.id == id }) {
                renderingGifImageViews[i].imageView.removeFromSuperview()
                renderingGifImageViews.remove(at: i)
            }
            return true
        }

        // delete mention
        if let targetMentionId = attrText.attribute(mentionIdAttrKey, at: 0, effectiveRange: nil) as? String, !targetMentionId.isEmpty {
            textView.attributedText.enumerateAttribute(
                mentionIdAttrKey,
                in: NSRange(location: 0, length: textView.attributedText.length),
                options: []
            ) { mentionId, range, _ in
                guard let mentionId = mentionId as? String else { return }
                guard mentionId == targetMentionId else { return }
                let mu = NSMutableAttributedString(attributedString: textView.attributedText)
                mu.deleteCharacters(in: range)
                textView.attributedText = mu
            }
            return false
        }

        return true
    }
}
