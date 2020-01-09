import XCTest
import ChatTextView

class ChatTextViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetCurrentTextTypes1() {
        let t = ChatTextView()
        t.attributedText = NSAttributedString(string: "hello")
        let result = t.getCurrentTextTypes()
        let expect: [TextType] = [TextType.plain("hello")]
        XCTAssert(result == expect)
    }

    func testGetCurrentTextTypes2() {
        let exp = expectation(description: "exp")

        let t = ChatTextView()
        let e = TextTypeCustomEmoji(
            displayImageUrl: URL(string: "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif")!,
            escapedString: ":hoge:",
            size: CGSize(width: 14, height: 14)
        )
        t.insert(emoji: e) {
            let result = t.getCurrentTextTypes()
            let expect: [TextType] = [TextType.customEmoji(e)]
            XCTAssert(result == expect)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5)
    }

    func testGetCurrentTextTypes3() {
        let exp = expectation(description: "exp")

        let t = ChatTextView()
        t.attributedText = NSAttributedString(string: "hello")
        let e = TextTypeCustomEmoji(
            displayImageUrl: URL(string: "https://emoji.slack-edge.com/T02DMDKPY/parrot/2c74b5af5aa44406.gif")!,
            escapedString: ":hoge:",
            size: CGSize(width: 14, height: 14)
        )
        t.insert(emoji: e) {
            t.insert(plain: "world")

            let result = t.getCurrentTextTypes()
            let expect: [TextType] = [
                TextType.plain("hello"),
                TextType.customEmoji(e),
                TextType.plain("world")
            ]
            XCTAssert(result == expect)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5)
    }

    func testGetCurrentTextTypes4() {
        let t = ChatTextView()
        let m = TextTypeMention(displayString: "@here", escapedString: "@here")
        t.insert(mention: m)
        let result = t.getCurrentTextTypes()
        let expect: [TextType] = [
            TextType.mention(m),
            TextType.plain(" ")
        ]
        XCTAssert(result == expect)
    }

    func testGetCurrentTextTypes5() {
        let t = ChatTextView()

        let m1 = TextTypeMention(displayString: "@here", escapedString: "@here")
        t.insert(mention: m1)

        let m2 = TextTypeMention(displayString: "@channel", escapedString: "@channel")
        t.insert(mention: m2)

        let result = t.getCurrentTextTypes()
        let expect: [TextType] = [
            TextType.mention(m1),
            TextType.plain(" "),
            TextType.mention(m2),
            TextType.plain(" ")
        ]
        print(result)
        XCTAssert(result == expect)
    }
}
