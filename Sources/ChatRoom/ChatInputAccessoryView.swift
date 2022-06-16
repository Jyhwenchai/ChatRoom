//
//  ChatInputAccessoryView.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2022/6/1.
//

import UIKit
import Combine

public class InputAccessoryViewGroup {
    
    var accessoryViews: [InputAccessoryView] = []
    init(accessoryViews: [InputAccessoryView]) {
        self.accessoryViews = accessoryViews
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


public class InputAccessoryView: UIView, Identifiable {
    
    private let actionSubject: PassthroughSubject<Void, Never> = PassthroughSubject()
    public var action: AnyPublisher<Void, Never> { actionSubject.eraseToAnyPublisher() }
    
    public var id = UUID().uuidString
    
    public let titleView: InputAccessoryTitleViewProtocol
    public let contentView: InputAssessoryContentViewProtocol?
    
    public init(titleView: InputAccessoryTitleViewProtocol,
         contentView: InputAssessoryContentViewProtocol? = nil) {
        self.titleView = titleView
        self.contentView = contentView
        super.init(frame: .zero)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(gesture)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapAction() {
        actionSubject.send()
    }
}

// MARK: -
public protocol InputAccessoryTitleViewProtocol: UIView {}

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

public protocol InputBottomAccessoryViewProtocol: UIView {
    var accessoryViews: [InputAccessoryView] { get set}
}

