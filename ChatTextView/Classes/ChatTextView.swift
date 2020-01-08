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
    var maxHeight: CGFloat?
    var chatTextViewDelegate: ChatTextViewDelegate?
    var heightLayoutConstraint: NSLayoutConstraint? {
        self.constraints.first { c in
            return c.firstAttribute == .height
        }
    }
    var usedEmojis: [TextTypeCustomEmoji] = []

    public func setup(delegate: ChatTextViewDelegate) {
        self.delegate = self
        self.chatTextViewDelegate = delegate
        setEmptyHeight()
    }

    public func insert(emoji: TextTypeCustomEmoji) {
        usedEmojis.append(emoji)
        usedEmojis = Array(Set(usedEmojis))

        let attarchment = NSTextAttachment()
        attarchment.image = {
            if emoji.displayImageUrl.pathExtension == "gif" {
                return nil
            }
            return createAnimatedImage(imageUrl: emoji.displayImageUrl)
        }()
        attarchment.bounds = .init(origin: .zero, size: emoji.size)
        let attr = NSMutableAttributedString(attachment: attarchment)
        attr.addAttribute(
            customEmojiAttrKey,
            value: emoji.displayImageUrl.absoluteString,
            range: NSRange(location: 0, length: attr.length)
        )

        let origin = NSMutableAttributedString(attributedString: self.attributedText)
        origin.insert(attr, at: currentCursorPosition())
        self.attributedText = origin
        textViewDidChange(self)
    }

    public func getCurrentTextTypes() -> [TextType] {
        let parsed = Parser.parse(
            attributedText: self.attributedText,
            usedEmojis: usedEmojis
        )
        return parsed
    }

    public func clear() {
        self.text = ""
        self.attributedText = NSAttributedString()
        setEmptyHeight()
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

    func createAnimatedImage(imageUrl: URL) -> UIImage? {
        if imageUrl.pathExtension == "gif" {
            return UIImage.gifImageWithURL(imageUrl.absoluteString)
        }

        guard let data = try? Data(contentsOf: imageUrl) else { return nil }
        return UIImage(data: data)
    }

    func setAnimatedGif() {
        subviews.forEach { v in
            if v is UIImageView {
                v.removeFromSuperview()
            }
        }
        let lastCursorPosition = currentCursorPosition()
        let fullRange = NSRange(location: 0, length: attributedText.length)

        attributedText.enumerateAttribute(customEmojiAttrKey, in: fullRange, options: []) { urlString, range, _ in
            guard let u = urlString as? String, let url = URL(string: u) else { return }
            guard url.pathExtension == "gif" else { return }

            selectedRange = range
            defer {
                selectedRange = NSRange(location: lastCursorPosition, length: 0)
            }

            guard let selectedTextRange = selectedTextRange else { return }
            var rect = firstRect(for: selectedTextRange)
            rect.origin.y += (rect.size.height - 14)
            rect.size = CGSize(width: 14, height: 14)

            let image = createAnimatedImage(imageUrl: url)
            let iv = UIImageView(frame: rect)
            iv.image = image
            addSubview(iv)
        }
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
            usedEmojis: usedEmojis
        )
        self.chatTextViewDelegate?.didChange(textTypes: parsed)
        setAnimatedGif()
    }
}
