//
//  AccessoryViews.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2022/6/2.
//

import UIKit
import ChatRoom

class TestButton: UIView {}

class VoiceButton: UIView, InputAccessoryTitleViewProtocol {
    
    var isSelected: Bool {
        get { button.isSelected }
        set { button.isSelected = newValue }
    }
    
    let button: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.setTitleColor(.red, for: .selected)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: 40, height: 40)
    }
    
    override var intrinsicContentSize: CGSize {
//       button.sizeThatFits(.zero)
        CGSize(width: 40, height: 40)
    }
}

class VoiceAssessoryContentView: UIView, InputAssessoryContentViewProtocol {
    var position: ContentPosition = .extraSpace
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: 0, height: bounds.height)
    }
}
