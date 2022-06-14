//
//  MessageModel.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import UIKit

struct TextModel {
    
    enum Direction {
        case left
        case right
    }

    var text: NSAttributedString
    var direction: Direction
    var contentSize: CGSize
}


struct Emoji {
    var name: String
    var desc: String
}

class EmojiAttachment: NSTextAttachment {
    var emoji: Emoji
    init(emoji: Emoji) {
        self.emoji = emoji
        super.init(data: nil, ofType: nil)
        image = UIImage(named: emoji.name)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
