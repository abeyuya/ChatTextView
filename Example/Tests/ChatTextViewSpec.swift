//
//  ChatTextViewSpec.swift
//  ChatTextView_Example
//
//  Created by abeyuya on 2020/01/11.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mockit
import ChatTextView

class DelegateStub: Stub, ChatTextViewDelegate {
    func didChange(textView: ChatTextView, contentSize: CGSize) {
    }

    func didChange(textView: ChatTextView, isFocused: Bool) {
    }

    func didChange(textView: ChatTextView, textBlocks: [TextBlock]) {
        callCount += 1
    }
}

class ChatTextViewSpec: QuickSpec {
    override func spec() {
        describe("input only plain text") {
            it("has only plain text") {
                let t = ChatTextView()
                t.attributedText = NSAttributedString(string: "hello")
                let result = t.getCurrentTextBlocks()
                let expectResult: [TextBlock] = [TextBlock.plain("hello")]
                expect(result).to(equal(expectResult))
            }
        }

        describe("input only custom emoji") {
            it("has only custom emoji") {
                let t = ChatTextView()
                let e = TextBlockCustomEmoji(
                    displayImageUrl: URL(string: "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif")!,
                    escapedString: ":hoge:"
                )

                waitUntil { done in
                    t.insert(emoji: e) {
                        let result = t.getCurrentTextBlocks()
                        let expectResult: [TextBlock] = [TextBlock.customEmoji(e)]
                        expect(result).to(equal(expectResult))
                        done()
                    }
                }
            }
        }

        describe("input plain text and custom emoji") {
            it("has plain text and custom emoji") {
                let t = ChatTextView()
                t.attributedText = NSAttributedString(string: "hello")

                let e = TextBlockCustomEmoji(
                    displayImageUrl: URL(string: "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif")!,
                    escapedString: ":hoge:"
                )

                waitUntil { done in
                    t.insert(emoji: e) {
                        t.insert(plain: "world")

                        let result = t.getCurrentTextBlocks()
                        let expectResult: [TextBlock] = [
                            TextBlock.plain("hello"),
                            TextBlock.customEmoji(e),
                            TextBlock.plain("world")
                        ]

                        expect(result).to(equal(expectResult))
                        done()
                    }
                }
            }
        }

        describe("input only mention") {
            it("has mention") {
                let t = ChatTextView()
                let m = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )
                t.insert(mention: m)
                let result = t.getCurrentTextBlocks()
                let expectResult: [TextBlock] = [
                    TextBlock.mention(m),
                    TextBlock.plain(" ")
                ]

                expect(result).to(equal(expectResult))
            }
        }

        describe("input many mention") {
            it("has many mention") {
                let t = ChatTextView()

                let m1 = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )
                t.insert(mention: m1)
 
                let m2 = TextBlockMention(
                    displayString: "@user_name",
                    metadata: ""
                )
                t.insert(mention: m2)

                let result = t.getCurrentTextBlocks()
                let expectResult: [TextBlock] = [
                    TextBlock.mention(m1),
                    TextBlock.plain(" "),
                    TextBlock.mention(m2),
                    TextBlock.plain(" ")
                ]

                expect(result).to(equal(expectResult))
            }
        }

        describe("when delete mention") {
            it("remove mention") {
                let t = ChatTextView()

                let m1 = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )
                t.insert(mention: m1)

                let m2 = TextBlockMention(
                    displayString: "@user_name",
                    metadata: ""
                )
                t.insert(mention: m2)

                t.deleteBackward()
                t.deleteBackward()

                let result = t.getCurrentTextBlocks()
                let expectResult: [TextBlock] = [
                    TextBlock.mention(m1),
                    TextBlock.plain(" "),
                ]

                expect(result).to(equal(expectResult))
            }
        }

        describe("when delete mention") {
            it("call delegate correctly") {
                let t = ChatTextView()
                let stub = DelegateStub()

                t.setup(delegate: stub)
                expect(stub.callCount).to(equal(0))

                let m1 = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )
                t.insert(mention: m1)
                expect(stub.callCount).to(equal(1))

                t.deleteBackward()
                expect(stub.callCount).to(equal(2))

                t.deleteBackward()
                expect(stub.callCount).to(equal(3))
            }
        }

        describe("when insert text in mention-block") {
            it("should delete mention-block and remain input text") {
                let t = ChatTextView()
                let stub = DelegateStub()

                t.setup(delegate: stub)
                expect(stub.callCount).to(equal(0))

                let m1 = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )
                t.insert(mention: m1)
                expect(stub.callCount).to(equal(1))

                t.insertWithIndex(plain: "insert", at: 3)
                expect(stub.callCount).to(equal(2))

                let textBlocks = t.getCurrentTextBlocks()
                expect(textBlocks).to(equal([.plain("insert"), .plain(" ")]))

                //
                // TODO: simulate insert text in mention-block
                //
                // let visibleString = t.attributedText.string
                // expect(visibleString).to(equal("insert "))
            }
        }

        describe("when insert text immediately before mention-block") {
            it("remain insert text and mention-block") {
                let t = ChatTextView()
                let stub = DelegateStub()

                t.setup(delegate: stub)
                expect(stub.callCount).to(equal(0))

                let m1 = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )
                t.insert(mention: m1)
                expect(stub.callCount).to(equal(1))

                t.insertWithIndex(plain: "insert", at: 0)
                expect(stub.callCount).to(equal(2))

                let textBlocks = t.getCurrentTextBlocks()
                expect(textBlocks).to(equal([
                    .plain("insert"),
                    .mention(m1),
                    .plain(" ")
                ]))

                //
                // TODO: simulate insert text in mention-block
                //
                // let visibleString = t.attributedText.string
                // expect(visibleString).to(equal("insert "))
            }
        }

        describe("render textBlocks") {
            it("become equal input and output") {
                let t = ChatTextView()

                let m1 = TextBlockMention(
                    displayString: "@channel",
                    metadata: ""
                )

                let e = TextBlockCustomEmoji(
                    displayImageUrl: URL(string: "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif")!,
                    escapedString: ":hoge:"
                )

                let textBlocks: [TextBlock] = [
                    TextBlock.mention(m1),
                    TextBlock.customEmoji(e),
                    TextBlock.plain("hello")
                ]

                waitUntil { done in
                    t.render(textBlocks: textBlocks) {
                        let result = t.getCurrentTextBlocks()
                        expect(result).to(equal(textBlocks))
                        done()
                    }
                }
            }
        }
    }
}
