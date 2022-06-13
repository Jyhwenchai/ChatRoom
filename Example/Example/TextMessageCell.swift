//
//  TextMessageCell.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/18.
//

import UIKit



class TextMessageCell: UITableViewCell {
    
    var isSender: Bool = false
    var contentSize: CGSize = .zero
    
    //MARK: - Views
    let messageView = TextMessageContentView()
    
    var avatar: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.layer.cornerRadius = 20
        view.backgroundColor = UIColor.systemTeal
        view.layer.masksToBounds = true
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(avatar)
        contentView.addSubview(messageView)
        contentView.backgroundColor = UIColor(hex: "f1f1f1")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var x: CGFloat = 0
        if !isSender {
            avatar.frame = CGRect(x: 15, y: 16, width: 40, height: 40)
            x = avatar.maxX + 5
        } else {
            avatar.frame = CGRect(x: contentView.width - 15 - 40, y: 16, width: 40, height: 40)
            x = avatar.minX - contentSize.width - 5
        }
        
        messageView.frame = CGRect(origin: CGPoint(x: x, y: avatar.y), size: contentSize)
    }
    
    func configureCellWith(model: TextModel) {
        messageView.textView.attributedText = model.text
        contentSize = model.contentSize
        isSender = model.direction == .right
        if model.direction == .left {
            messageView.bgView.backgroundColor = UIColor.white
            messageView.textView.textColor = UIColor.darkText
        } else {
            messageView.bgView.backgroundColor = UIColor.systemOrange
            messageView.textView.textColor = UIColor.white
        }
    }
}
