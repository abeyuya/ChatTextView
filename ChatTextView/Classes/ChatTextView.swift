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

    var maxHeight: CGFloat?
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
        usedEmojis.append(emoji)
        usedEmojis = Array(Set(usedEmojis))

        createAnimatedImage(imageUrl: emoji.displayImageUrl) { image in
            let attarchment = NSTextAttachment()
            if emoji.displayImageUrl.pathExtension != "gif" {
                attarchment.image = image
            } else {
                attarchment.image = UIImage()
            }
            attarchment.bounds = .init(origin: .zero, size: emoji.size)
            let attr = NSMutableAttributedString(attachment: attarchment)
            let id = UUID().uuidString
            attr.addAttributes(
                [
                    customEmojiImageUrlAttrKey: emoji.displayImageUrl.absoluteString,
                    customEmojiIdAttrKey: id
                ],
                range: NSRange(location: 0, length: attr.length)
            )

            let origin = NSMutableAttributedString(attributedString: self.attributedText)
            origin.insert(attr, at: self.currentCursorPosition())
            self.attributedText = origin
            self.textViewDidChange(self)
            completion()
        }
    }

    public func insert(mention: TextTypeMention) {
        let attr = NSAttributedString(
            string: mention.displayString,
            attributes: [
                .foregroundColor: UIColor.blue,
                mentionAttrKey: true
            ]
        )

        let origin = NSMutableAttributedString(attributedString: self.attributedText)
        origin.insert(attr, at: self.currentCursorPosition())
        self.attributedText = origin
        insert(plain: " ")
        usedMentions.append(mention)
    }

    public func insert(plain: String) {
        let attr = NSAttributedString(string: plain)
        let origin = NSMutableAttributedString(attributedString: self.attributedText)
        origin.insert(attr, at: self.currentCursorPosition())
        self.attributedText = origin
        self.textViewDidChange(self)
    }

    public func getCurrentTextTypes() -> [TextType] {
        let parsed = Parser.parse(
            attributedText: self.attributedText,
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
        guard let selectedRange = self.selectedTextRange else { return 0 }
        let cursorPosition = self.offset(
            from: self.beginningOfDocument,
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
        let newFrame = calcLimitedFrame(text: textView.text)
        update(frame: newFrame)

        let parsed = Parser.parse(
            attributedText: textView.attributedText,
            usedEmojis: usedEmojis,
            usedMentions: usedMentions
        )
        self.chatTextViewDelegate?.didChange(textTypes: parsed)
        updateAnimatedGif()
    }
}
