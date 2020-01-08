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
        attarchment.image = emoji.displayImage
        attarchment.bounds = .init(origin: .zero, size: emoji.size)
        let attr = NSAttributedString(attachment: attarchment)

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
    }
}
