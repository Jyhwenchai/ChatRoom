//
//  ChatInputAccessoryView.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2022/6/1.
//

import UIKit

public class InputAccessoryViewGroup {
    
    var selectedClosure: ((InputAccessoryView) -> Void)?
    
    var accessoryViews: [InputAccessoryView] = []
    init(accessoryViews: [InputAccessoryView]) {
        self.accessoryViews = accessoryViews
        for (index, view) in accessoryViews.enumerated() {
            view.index = index
            let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            gesture.name = "\(view.index)"
            view.titleView.isUserInteractionEnabled = true
            view.titleView.addGestureRecognizer(gesture)
        }
    }
    
    @objc func tapAction(_ gesture: UITapGestureRecognizer) {
        guard let flag = Int(gesture.name!) else { return }
        let accessoryView = accessoryViews[flag]
        selectedClosure?(accessoryView)
    }
    
    lazy var containerView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.alignment = .center
        return stackView
    }()
    
    func titleGroupView() -> UIView {
        let titleViews = accessoryViews.map { $0.titleView }
        let width = titleViews.reduce(0) {
            $0 + $1.sizeThatFits(.zero).width
        }
        titleViews.forEach(containerView.addArrangedSubview(_:))
        containerView.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        return containerView
    }

}


public class InputAccessoryView: UIView {
    
    let titleView: InputAccessoryTitleViewProtocol
    let contentView: InputAssessoryContentViewProtocol
    
    var index: Int = 0
    
    public init(titleView: InputAccessoryTitleViewProtocol,
         contentView: InputAssessoryContentViewProtocol) {
        self.titleView = titleView
        self.contentView = contentView
        super.init(frame: .zero)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: -
public protocol InputAccessoryTitleViewProtocol: UIView {
    var isSelected: Bool { get set }
}

public enum ContentPosition {
    case coverInput
    case extraSpace
}

public protocol InputAssessoryContentViewProtocol: UIView {
    var position: ContentPosition { get set }
}

@resultBuilder
public struct InputAccessoryBuilder {
    public static func buildBlock(_ components: InputAccessoryView...) -> InputAccessoryViewGroup {
       InputAccessoryViewGroup(accessoryViews: components)
    }
}

