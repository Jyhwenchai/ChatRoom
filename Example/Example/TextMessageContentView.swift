//
//  TextMessageContentView.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import UIKit


class TextMessageContentView: UIView {
    
    var textView: UITextView = {
        let view = UITextView()
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = UIColor.clear
        view.isEditable = false
        view.isScrollEnabled = false
        view.font = UIFont.systemFont(ofSize: 14)
        view.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        return view
    }()
    
    private var calculateLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    
    var bgView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        addSubview(bgView)
        addSubview(textView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = bounds
        textView.frame = bounds
    }
    
}
