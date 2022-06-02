//
//  ChatViewModel.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import UIKit

class ChatViewModel {
    
    let cellSpacing: CGFloat = 16
    
    var messages: [TextModel] = []
    
    var addNewMessageCompleteHandler: (() -> Void)?
    var loadHistoryMessageCompleteHandler: ((Int) -> Void)?
    
    init() {
        var addMessages: [TextModel] = []
        for index in 0..<20 {
            let model = TextModel(text: "new message \(count) - \(index)", direction: .left, contentSize: CGSize(width: 200, height: 40))
            addMessages.append(model)
        }
        messages.append(contentsOf: addMessages)
    }
    
    func addMessage(_ text: String) {
        let direction: TextModel.Direction = Int8.random(in: 1...Int8.max) % 2 == 0 ? .left : .right
        let size = calculateMessageSize(text)
        let model = TextModel(text: text, direction: direction, contentSize: size)
        messages.append(model)
        addNewMessageCompleteHandler?()
    }
    
    
    private func calculateMessageSize(_ message: String) -> CGSize {
        
        var contentSize: CGSize = .zero
        
        let desc = message as NSString
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineBreakMode = .byWordWrapping
        
        let textMargin: CGFloat = 193.0
        let bubbleMargin: CGFloat = 169.0
        
        let screenWidth = UIScreen.main.bounds.width
        contentSize = desc.boundingRect(with: CGSize(width: screenWidth - textMargin, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: UIFont.systemFont(ofSize: 14), .paragraphStyle: style], context: nil).size

        let minBubbleHeight: CGFloat = 40.0
        let bubbleHorizontalPadding: CGFloat = 24
        let bubbleVerticalPadding: CGFloat = 20
        
        let contentHeight: CGFloat = contentSize.height < 25 ? minBubbleHeight : ceil(contentSize.height) + bubbleVerticalPadding
        let contentWidth: CGFloat = min(screenWidth - bubbleMargin, ceil(contentSize.width) + bubbleHorizontalPadding)
        contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        return contentSize
    }
    
    func cellHeight(at indexPath: IndexPath) -> CGFloat {
        messages[indexPath.item].contentSize.height + cellSpacing
    }
    
    var count = 0
    func loadMoreMessage() {
        var addMessages: [TextModel] = []
        for index in 0..<10 {
            let model = TextModel(text: "new message \(count) - \(index)", direction: .left, contentSize: CGSize(width: 200, height: 40))
            addMessages.append(model)
        }
        count += 10
        messages.insert(contentsOf: addMessages, at: 0)
        loadHistoryMessageCompleteHandler?(addMessages.count)
    }
}
