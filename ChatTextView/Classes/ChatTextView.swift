//
//  ChatTextView.swift
//  ChatTextView
//
//  Created by abeyuya on 2020/01/06.
//

import UIKit

public protocol ChatTextViewDelegate: class {
}

public class ChatTextView: UITextView {
    var maxHeight: CGFloat?
    var chatTextViewDelegate: ChatTextViewDelegate?
    var heightLayoutConstraint: NSLayoutConstraint? {
        self.constraints.first { c in
            return c.firstAttribute == .height
        }
    }

    public func setup(delegate: ChatTextViewDelegate) {
        self.delegate = self
        self.chatTextViewDelegate = delegate
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
}

private extension NSObject {
    func copyObject<T:NSObject>() throws -> T? {
        let data = try NSKeyedArchiver.archivedData(withRootObject:self, requiringSecureCoding:false)
        return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
    }
}

extension ChatTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        let newFrame = calcLimitedFrame(text: textView.text)
        update(frame: newFrame)
    }
}
