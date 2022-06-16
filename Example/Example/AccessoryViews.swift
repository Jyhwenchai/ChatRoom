//
//  AccessoryViews.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2022/6/2.
//

import UIKit
import ChatRoom
import Combine

class AccessoryButton: UIView, InputAccessoryTitleViewProtocol {
    
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
        CGSize(width: 40, height: 40)
    }
}

class AssessoryContentView: UIView, InputAssessoryContentViewProtocol {
    var position: ContentPosition = .extraSpace
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: 0, height: bounds.height)
    }
}

class BottomView: UIView, InputBottomAccessoryViewProtocol {
    
    var accessoryViews: [InputAccessoryView] = []
    lazy var audioView: InputAccessoryView = {
        let title = createButton(with: "im_icon_mapmicrophone")
        let content = AssessoryContentView(frame: CGRect(x: 0, y: 0, width: 0, height: 160))
        content.backgroundColor = UIColor.orange
        return InputAccessoryView(titleView: title, contentView: content)
    }()
    
    lazy var cameraView: InputAccessoryView = {
        let title = createButton(with: "im_icon_camera")
        return InputAccessoryView(titleView: title)
    }()
    
    lazy var photoView: InputAccessoryView = {
        let title = createButton(with: "im_icon_image")
        return InputAccessoryView(titleView: title)
    }()
    
    lazy var addressView: InputAccessoryView = {
        let title = createButton(with: "im_icon_map")
        return InputAccessoryView(titleView: title)
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.addArrangedSubview(audioView.titleView)
        stackView.addArrangedSubview(cameraView.titleView)
        stackView.addArrangedSubview(photoView.titleView)
        stackView.addArrangedSubview(addressView.titleView)
        accessoryViews.append(audioView)
        accessoryViews.append(cameraView)
        accessoryViews.append(photoView)
        accessoryViews.append(addressView)
        return stackView
    }()
    
    var cancellable = Set<AnyCancellable>()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        cameraView.action
            .sink { _ in
               print("camera item action")
            }
            .store(in: &cancellable)
    }
   
    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createButton(with image: String) -> InputAccessoryTitleViewProtocol {
        let view = AccessoryButton()
        view.isUserInteractionEnabled = true
        view.button.setImage(UIImage(named: image), for: .normal)
        return view
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: UIScreen.main.bounds.width, height: 49)
    }
}


