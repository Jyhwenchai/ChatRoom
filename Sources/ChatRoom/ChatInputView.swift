//
//  ChatInputView.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import UIKit
import Combine

private let maxInputHeight: CGFloat = 100.0
private let minInputHeight: CGFloat = 36.0
private let inputMarginSpacing: CGFloat = 16

protocol InputViewDelegate: NSObjectProtocol {
    func inputView(_ inputView: ChatInputView,
                   show newSelectAccessoryView: ChatInputView.SelectAccessoryView,
                   dismiss oldSelectAccessoryView: ChatInputView.SelectAccessoryView?)
}

public class ChatInputView: UIView {
    
    enum SelectAccessoryView: Equatable {
        case input
        case selected(InputAccessoryView)
    }
    
    /// 可能所有的组件视图都没有被选中，包括 TextField
    var selectAccessoryView: SelectAccessoryView? = nil
    var leftAccessoryViewGroup: InputAccessoryViewGroup?
    var rightAccessoryViewGroup: InputAccessoryViewGroup?
    
    weak var delegate: InputViewDelegate?
    
    var confirmInputClosure: ((NSAttributedString) -> Void)?
    var textDidChangedClosure: ((NSAttributedString?) -> Void)?
    var updateFrameClosure: ((CGFloat) -> Void)?
    public var isHiddenSeperate: Bool = false {
        didSet { lineView.isHidden = isHiddenSeperate }
    }
    
    /// available left and right
    public var contentInsets = UIEdgeInsets.zero
    
    public let textView: UITextView = {
        let textField = UITextView()
        textField.backgroundColor = UIColor.white
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = UIColor.darkText
        textField.layer.cornerRadius = 4
        textField.tintColor = UIColor.systemRed
        textField.returnKeyType = .send
        textField.enablesReturnKeyAutomatically = true
        return textField
    }()
    
    let lineView = UIView()
    let contentView = UIView()
    var bottomAccessoryView: InputBottomAccessoryViewProtocol? {
        didSet {
            if let bottomAccessoryView {
                addAccessoryViews(bottomAccessoryView.accessoryViews)
                addSubview(bottomAccessoryView)
            }
        }
    }
    
    var cancellable = Set<AnyCancellable>()
    var observation: NSKeyValueObservation?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 241.0/255, green: 241.0/255, blue: 241/255, alpha: 1)
        textView.delegate = self
        addSubview(contentView)
        contentView.addSubview(textView)
        contentView.addSubview(lineView)
        lineView.backgroundColor = UIColor(red: 225.0/255, green: 225.0/255, blue: 225/255, alpha: 1)
        
        textView.publisher(for: \.attributedText)
            .sink { [weak self] attributedText in
                guard let self = self else { return }
                self.textViewDidChange(self.textView)
            }
            .store(in: &cancellable)
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapAction(recognizer:)))
//        tapGesture.numberOfTapsRequired = 1
//        textView.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textViewTapAction(recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        textView.isEditable = true
        textView.becomeFirstResponder()
        let location = recognizer.location(in: textView)
        if let position = textView.closestPosition(to: location) {
            let uiTextRange = textView.textRange(from: position, to: position)
            
            if let start = uiTextRange?.start, let end = uiTextRange?.end {
                let loc = textView.offset(from: textView.beginningOfDocument, to: position)
                let length = textView.offset(from: start, to: end)
                
                textView.selectedRange = NSMakeRange(loc, length)
                
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let bottomAccessorySize = bottomAccessoryView?.sizeThatFits(.zero) ?? .zero
        if let bottomAccessoryView {
            bottomAccessoryView.frame = CGRect(x: 0, y: height - bottomAccessorySize.height, width: width, height: bottomAccessorySize.height)
        }
        contentView.frame = CGRect(x: contentInsets.left, y: 0, width: width - contentInsets.left - contentInsets.right, height: height - bottomAccessorySize.height)
        lineView.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        
        var reduceWidth: CGFloat = 0
        var groupViewMaxX: CGFloat = 0
        if let leftAccessoryViewGroup = leftAccessoryViewGroup {
            let groupView = leftAccessoryViewGroup.titleGroupView()
            var frame = groupView.frame
            frame.size.height = minInputHeight + inputMarginSpacing
            frame.origin.y = contentView.height - frame.size.height
            groupView.frame = frame
            reduceWidth += frame.width
            groupViewMaxX = frame.width
        }
        
        if let rightAccessoryViewGroup = rightAccessoryViewGroup {
            let groupView = rightAccessoryViewGroup.titleGroupView()
            var frame = groupView.frame
            frame.origin.x = contentView.width - frame.width
            frame.size.height = minInputHeight + inputMarginSpacing
            frame.origin.y = contentView.height - frame.size.height
            groupView.frame = frame
            reduceWidth += frame.width
        }
        
        let remainWidth = bounds.width - reduceWidth - contentInsets.left - contentInsets.right
        textView.frame = CGRect(x: groupViewMaxX, y: inputMarginSpacing / 2, width: remainWidth, height: contentView.height - inputMarginSpacing)
    }
    
    
    public func addLeftAccessoryViews(@InputAccessoryBuilder _ viewBuilder: () -> InputAccessoryViewGroup) {
        leftAccessoryViewGroup = viewBuilder()
        addAccessoryViews(from: leftAccessoryViewGroup!)
    }
    
    public func addRightAccessoryViews(@InputAccessoryBuilder _ viewBuilder: () -> InputAccessoryViewGroup) {
        rightAccessoryViewGroup = viewBuilder()
        addAccessoryViews(from: rightAccessoryViewGroup!)
    }
    
    func addAccessoryViews(from group: InputAccessoryViewGroup) {
        contentView.addSubview(group.titleGroupView())
        addAccessoryViews(group.accessoryViews)
    }
    
    func addAccessoryViews(_ views: [InputAccessoryView]) {
        for view in views {
            if view.contentView == nil { continue }
            view.action
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.updateSelectedAccessoryView(view)
                }
                .store(in: &cancellable)
        }
    }
    
    func updateSelectedAccessoryView(_ accessoryView: InputAccessoryView) {
        if selectAccessoryView == nil {
            selectAccessoryView = .selected(accessoryView)
            delegate?.inputView(self, show: selectAccessoryView!, dismiss: nil)
            return
        }
        
        let oldSelectAccessoryView = selectAccessoryView!
        switch oldSelectAccessoryView {
        case .input:
            selectAccessoryView = .selected(accessoryView)
        case .selected(let currentAccessoryView):
            if accessoryView == currentAccessoryView {
                selectAccessoryView = .input
                textView.becomeFirstResponder()
            } else {
                selectAccessoryView = .selected(accessoryView)
            }
        }
        delegate?.inputView(self, show: selectAccessoryView!, dismiss: oldSelectAccessoryView)
    }
    
    
}

extension ChatInputView: UITextViewDelegate {
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let oldSelectAccessoryView = selectAccessoryView
        selectAccessoryView = .input
        delegate?.inputView(self, show: selectAccessoryView!, dismiss: oldSelectAccessoryView)
        return true
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let text = textView.attributedText {
                confirmInputClosure?(text)
                textView.attributedText = nil
            }
            return false
        }
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        textDidChangedClosure?(textView.attributedText)
        if let _ = textView.attributedText {
            let size = textView.sizeThatFits(CGSize(width: textView.width, height: 0))
            let bottomAccessoryViewHeight = bottomAccessoryView?.sizeThatFits(.zero).height ?? 0
            let viewHeight: CGFloat = min(max(ceil(size.height), minInputHeight), maxInputHeight) + bottomAccessoryViewHeight + inputMarginSpacing
            if viewHeight != height {
                updateFrameClosure?(viewHeight)
            }
        }
    }
    
}

extension ChatInputView {
    var minHeight: CGFloat {
        minInputHeight + inputMarginSpacing + (bottomAccessoryView?.sizeThatFits(.zero).height ?? 0)
    }
    
    var maxHeight: CGFloat {
        maxInputHeight + inputMarginSpacing + (bottomAccessoryView?.sizeThatFits(.zero).height ?? 0)
    }
}
