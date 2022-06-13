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
