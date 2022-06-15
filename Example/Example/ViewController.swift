//
//  ViewController.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/18.
//

import UIKit
import ChatRoom

class ViewController: ChatRoomViewController {

    let viewModel: ChatViewModel = ChatViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // test item
        let barItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(testAction))
        navigationItem.rightBarButtonItems = [barItem]
        bindData()
        initView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            var addMessages: [TextModel] = []
            for index in 0..<26 {
                let attributedText = NSAttributedString(string: "new message \(self.viewModel.count) - \(index)")
                let model = TextModel(text: attributedText, direction: .left, contentSize: CGSize(width: 200, height: 40))
                addMessages.append(model)
            }
            self.viewModel.messages.append(contentsOf: addMessages)
            self.reloadDataWhenDataFirstLoad()
        }
        
        do {
            let text = "[微笑]123[微笑][微了][微笑]01234[微笑]dfdf[微笑]"
            let attributedText = NSMutableAttributedString()
            let regex = try NSRegularExpression(pattern: #"[\u0391-\uFFE5]+]"#)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            var lastRange: NSRange = NSRange()
            results.forEach {
                let range = $0.range
                let startIndex = text.index(text.startIndex, offsetBy: range.location-1)
                let endIndex = text.index(text.startIndex, offsetBy: range.location+range.length)
                
                if let emojiDesc = text[startIndex..<endIndex] {
                    let start = text.index(text.startIndex, offsetBy: lastRange.location + lastRange.length)
                    var end = text.index(text.startIndex, offsetBy: range.location - 1)
                    if emojiDesc != "[微笑]" {
                        end = endIndex
                    }
                    let text = String(text[start..<end])
                    attributedText.append(NSAttributedString(string: text))
                    
                    lastRange = range
                    
                    if emojiDesc == "[微笑]" {
                        let inserLocation = attributedText.length
                        let attachment = EmojiAttachment(emoji: Emoji(name: "ej_1", desc: "[微笑]"))
                        let lineHeight = chatInputView.textView.font!.lineHeight
                        let spacing = chatInputView.textView.font!.descender
                        attachment.bounds = CGRect(x: 0, y: spacing, width: lineHeight, height: lineHeight)
                        let emojiAttributedString = NSAttributedString(attachment: attachment)
                        attributedText.insert(emojiAttributedString, at: inserLocation)
                    }
                }
            }
            
            if let res = results.last {
                let suffixStringStartPosition = res.range.location + res.range.length
                let suffixStringEndPosition = text.count
                if suffixStringStartPosition < suffixStringEndPosition {
                    let startIndex = text.index(text.startIndex, offsetBy: suffixStringStartPosition)
                    let endIndex = text.index(text.startIndex, offsetBy: suffixStringEndPosition)
                    let text = text[startIndex..<endIndex]
                    attributedText.append(NSAttributedString(string: String(text)))
                }
            }
            attributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, attributedText.length))
            chatInputView.textView.attributedText = attributedText
        } catch {
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        reloadDataWhenDataFirstLoad()
    }
    
    @objc func testAction() {
//        viewModel.messages.removeAll()
//        indicatorView.stopAnimating()
//        tableView.tableHeaderView = nil
//        reloadDataWhenLoadingPage()
        let attributedText = chatInputView.textView.attributedText!
//        let image = UIImage(named: "ej_1")!
//        let fileWrapper = FileWrapper(regularFileWithContents: image.pngData()!)
//        fileWrapper.preferredFilename = "ej_1.png"
//        let attachData = NSTextAttachment()
//        attachData.fileWrapper = fileWrapper
        
//        let attachData = NSTextAttachment(data: nil, ofType: "ej_1")
//        attachData.fileWrapper?.fileAttributes = ["hello": "word"]
//        attachData.image = image
        let attachData = EmojiAttachment(emoji: Emoji(name: "ej_1", desc: "[微笑]"))
      
        let lineHeight = chatInputView.textView.font!.lineHeight
        let spacing = chatInputView.textView.font!.descender
        attachData.bounds = CGRect(x: 0, y: spacing, width: lineHeight, height: lineHeight)
        let emojiSymbol = NSAttributedString(attachment: attachData)
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedText.append(emojiSymbol)
        mutableAttributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, mutableAttributedText.length))
        chatInputView.textView.attributedText = mutableAttributedText
        
        var formatString = ""
        mutableAttributedText.enumerateAttributes(in: NSMakeRange(0, mutableAttributedText.length)) { attributes, range, stop in
            if attributes.contains { $0.key == .attachment } {
                if let attachment = attributes[.attachment] as? EmojiAttachment {
                    formatString.append(attachment.emoji.desc)
                }
            } else {
                let subString = mutableAttributedText.attributedSubstring(from: range)
                formatString.append(subString.string)
            }
        }
        print(formatString)
       
        
    }
    
    func initView() {
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: "TextMessageCell")
        
        let button1: VoiceButton = {
            let button = VoiceButton()
            button.button.setImage(UIImage(named: "icon_voice"), for: .normal)
            return button
        }()
        
        let button2: VoiceButton = {
            let button = VoiceButton()
            button.button.setImage(UIImage(named: "icon_expression"), for: .normal)
            return button
        }()
        
        let button3: VoiceButton = {
            let button = VoiceButton()
            button.button.setImage(UIImage(named: "icon_more2"), for: .normal)
            return button
        }()
        
        let contentView1 = VoiceAssessoryContentView(frame: CGRect(x: 0, y: 0, width: 0, height: 200))
        contentView1.backgroundColor = .blue
        let contentView2 = VoiceAssessoryContentView(frame: CGRect(x: 0, y: 0, width: 0, height: 220))
        contentView2.backgroundColor = .purple
        let contentView3 = VoiceAssessoryContentView(frame: CGRect(x: 0, y: 0, width: 0, height: 240))
        contentView3.backgroundColor = .green
        contentView3.position = .coverInput

        chatInputView.addLeftAccessoryViews {
            InputAccessoryView(titleView: button1, contentView: contentView1)
        }
        chatInputView.addRightAccessoryViews {
            InputAccessoryView(titleView: button2, contentView: contentView2)
            InputAccessoryView(titleView: button3, contentView: contentView3)
        }
        
        let bottomAttachView = UIButton()
        bottomAttachView.setTitle("Hello, SwiftUI", for: .normal)
        bottomAttachView.backgroundColor = .purple
        bottomAttachView.contentEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        chatInputBottomAttachView = bottomAttachView
    }
    
    func bindData() {
        viewModel.addNewMessageCompleteHandler = { [weak self] in
            guard let self = self else { return }
            self.layoutUIWhenReceiveMessage()
        }
        
        viewModel.loadHistoryMessageCompleteHandler = { [weak self] insertCount in
            guard let self = self else { return }
            self.reloadDataWhenLoadingPage()
        }
    }
    
    override func inputViewTextDidChanged(_ attributed: NSAttributedString?) {
        print(attributed)
    }
    
    override func inputViewConfirmInput(_ attributedText: NSAttributedString) {
        viewModel.addMessage(attributedText)
    }
    
    override func loadingHistoryMessages(completion: (Bool) -> Void) {
        // load history message here, if `hasHistoryMessage` return true
        self.viewModel.loadMoreMessage()
        // return true, if loading successful. otherwise return false
        completion(true)
    }
    
    override func hasHistoryMessage() -> Bool {
        return viewModel.count < 30
    }
    
}


extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextMessageCell") as! TextMessageCell
        let model = viewModel.messages[indexPath.item]
        cell.configureCellWith(model: model)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.cellHeight(at: indexPath)
    }
    
}

//
