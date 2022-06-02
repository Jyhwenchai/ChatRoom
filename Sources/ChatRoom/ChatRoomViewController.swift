//
//  ChatRoomViewController.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/20.
//

import UIKit

private let tabBarAdditionHeight: CGFloat = ChatRoomContant.bottomSafeAreaHeight
private let tableHeaderHeight: CGFloat = 30.0
private let tableFooterHeight: CGFloat = 12.0

open class ChatRoomViewController: UIViewController {

    /// Delay update UI when loading history messages completed.
    public var delayUpdateUITimeInterval: TimeInterval = 0.6
    
    /// Delay update UI immediately when loading history messages completed.
    public var delayImmediateUpdateUITimeInterval: UInt32 = 150_000
    
    public var globalAnimateTimeInterval: TimeInterval = 0.25
    
    private var keyboardWillShowToken: NSObjectProtocol?
    
    private enum RefreshState {
        case normal
        case prepared
        case loadingData
        case loadingDataCompleted
        case updatingUI
    }
    
    private var refreshState: RefreshState = .normal
    private var loadPageSuccessContentOffset: CGPoint = .zero
    private var viewDidLayout: Bool = false

    private let componentAnimateType: UIView.AnimationOptions = .curveEaseInOut
    
    /// The value is zero when `pinInputViewToBottom` is true.
    private var inputAccessoryContentViewFrame: CGRect = .zero
    private var pingInputViewToBottom: Bool = true {
        didSet {
            if pingInputViewToBottom {
                inputAccessoryContentViewFrame = .zero
            }
        }
    }
    
    //MARK: - Views
    public let chatInputView: ChatInputView = ChatInputView()
    let indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        indicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        indicator.color = UIColor(red: 209.0/255, green: 209.0/255, blue: 209.0/255, alpha: 1)
        return indicator
    }()
    
    lazy var tableHeaderView: UIView = {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: tableHeaderHeight))
        indicatorView.center = headerView.center
        headerView.addSubview(indicatorView)
        return headerView
    }()
    
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: tableFooterHeight))
        return tableView
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        privateInit()
    }
    
    func privateInit() {
        
        func initNav() {
            let appearance = navigationController!.navigationBar.standardAppearance
            appearance.backgroundColor = UIColor(red: 241.0/255, green: 241.0/255, blue: 241/255, alpha: 1)
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        func initView() {
            view.backgroundColor = UIColor(red: 241.0/255, green: 241.0/255, blue: 241/255, alpha: 1)
            
            let inputViewMinHeight = chatInputView.minHeight
            var frame = view.bounds
            frame.size.height = view.height - inputViewMinHeight - tabBarAdditionHeight
            tableView.frame = frame
            view.addSubview(tableView)
            
            chatInputView.frame = CGRect(x: 0, y: frame.height, width: view.width, height: inputViewMinHeight)
            view.addSubview(chatInputView)
            chatInputView.delegate = self
        }

        func initBind() {

            chatInputView.confirmInputClosure = { [weak self] text in
                guard let self = self else { return }
                
                let maxOffset = self.inputAccessoryContentViewFrame.height - tabBarAdditionHeight
                // reset inputView frame and correct tableView offset position
                UIView.animate(withDuration: 0.20, delay: 0, options: self.componentAnimateType) {
                    self.chatInputView.y = self.inputAccessoryContentViewFrame.minY - self.chatInputView.minHeight
                    self.chatInputView.height = self.chatInputView.minHeight
                    self.chatInputView.layoutIfNeeded()
                    if abs(self.tableView.y) > abs(maxOffset) {
                        self.tableView.y = -maxOffset
                    }
                }
                self.inputViewConfirmInput(text)
            }
            
            chatInputView.updateFrameClosure = { [weak self] height in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.20, delay: 0, options: self.componentAnimateType) {
                    self.chatInputView.y -= (height - self.chatInputView.height)
                    self.chatInputView.height = height
                    self.chatInputView.layoutIfNeeded()
                    self.layoutTableView(with: self.inputAccessoryContentViewFrame)
                }
            }
        }
        
        func initNotification() {
            
            self.keyboardWillShowToken = NotificationCenter.default.addObserver(forName: UIViewController.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
                guard let self = self else { return }
                if self.inputAccessoryContentViewFrame == .zero {
                    self.scrollTableViewContentToBottomWhenInputViewComponentWillShow()
                }
                self.inputAccessoryContentViewFrame = notification.keyboardFrame
                self.layoutTableView(with: self.inputAccessoryContentViewFrame)
            }
            
        }
        
        initNav()
        initView()
        initBind()
        initNotification()
    }

    deinit {
        keyboardWillShowToken = nil
    }
    
    //MARK: Main Method
    
    /// Reload data and update UI immediately when drag tableView and refreshState is `loadingDataCompleted`
    private func reloadDataImmidiate() {
        if self.refreshState != .loadingDataCompleted {
            return
        }
        refreshState = .updatingUI
        self.indicatorView.stopAnimating()
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.refreshState = .normal
    }
    
    /// Reload data and update UI when loading history page
    public func reloadDataWhenLoadingPage() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayUpdateUITimeInterval) {
 
            if self.refreshState != .loadingDataCompleted {
                return
            }
            
            self.refreshState = .updatingUI
            self.indicatorView.stopAnimating()
            
            let reloadBeforeCount = self.tableView.numberOfRows(inSection: 0)
            self.tableView.reloadData()
            let reloadEndCount = self.tableView.numberOfRows(inSection: 0)
            
            if !self.hasHistoryMessage() {
                self.tableView.tableHeaderView = nil
            }
            
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
            // keep the original position of cells.
            let addCellsCount = reloadEndCount - reloadBeforeCount
            if let cell = self.tableView.cellForRow(at: IndexPath(row: addCellsCount - 1, section: 0)) {
                let contentOffset = cell.maxY - tableHeaderHeight + self.tableView.contentOffset.y
                self.tableView.setContentOffset(CGPoint(x: 0, y: contentOffset) , animated: false)
            }
            self.refreshState = .normal
        }
       
    }
    
    /// Call this method when receive new message
    public func layoutUIWhenReceiveMessage() {
        self.tableView.reloadData()
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.layoutTableView(with: inputAccessoryContentViewFrame)
        self.scrollTableViewContentToBottomWhenInputViewComponentWillShow()
    }
    
    /// Update tableView frame when keyboard or inputView frame changed.
    private func layoutTableView(with componentFrame: CGRect) {
        
        if componentFrame == .zero {
            // Changing tableView height to the appropriate value if chatInputView's height changed when components hide.
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.width, height: self.view.height - self.chatInputView.height - tabBarAdditionHeight)
                self.chatInputView.y = self.tableView.height
            }
            return
        } else {
            
            // The tableView height should be maintained a fixed value when components showed.
            let minTableHeight = self.view.height - chatInputView.minHeight - tabBarAdditionHeight
            if minTableHeight != tableView.height {
                UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                    self.tableView.height = minTableHeight
                }
            }
        }
        
        let screenHeight = UIScreen.main.bounds.height
        let statusBarAndNavigationBarHeight = ChatRoomContant.statusBarAndNavigationBarHeight
        // 由于 tableView 的高度 = view.height - inputViewHeight - tabBarAdditionHeight
        // 所以最大偏移量 maxOffset 的值计算方式如下 keyboardFrame.height - inputViewMinHeight - tabBarAdditionHeight + inputHeight(当前chatInputView的真实高度)
        let inputViewHeight = chatInputView.height
        let maxOffset = componentFrame.height - chatInputView.minHeight - tabBarAdditionHeight + inputViewHeight
        // 显示键盘时可见区域的高度
        let visiableHeight = screenHeight - componentFrame.height - inputViewHeight - statusBarAndNavigationBarHeight
        let contentHeight = tableView.contentSize.height
 
        var y: CGFloat = 0
        if contentHeight > visiableHeight {
            //FIXME: - Maybe can optimize this condition.
            if abs(maxOffset) == abs(tableView.y) { return }
            let offset = contentHeight - visiableHeight
            y = max(-offset, -maxOffset)
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                self.tableView.y = y
                self.chatInputView.y = self.inputAccessoryContentViewFrame.minY - self.chatInputView.height
            }
        } else {
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                self.chatInputView.y = self.inputAccessoryContentViewFrame.minY - self.chatInputView.height
            }
        }
        
    }
    
    /// When tableView contentSize over screen, scroll tableView content to bottom.
    private func scrollTableViewContentToBottomWhenInputViewComponentWillShow() {
        
        // check current already scroll on bottom
        let tableFooterViewFrame = tableView.tableFooterView?.frame ?? .zero
        if tableView.contentOffset.y + tableView.height == tableFooterViewFrame.maxY {
            return
        }
        
        if pingInputViewToBottom {
            // By execute `scrollRectToVisible` method twice can fix scroll to bottom bug.
            UIView.performWithoutAnimation {
                self.tableView.scrollRectToVisible(self.tableView.tableFooterView!.frame, animated: false)
            }
            tableView.setNeedsLayout()
            tableView.layoutIfNeeded()
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                self.tableView.scrollRectToVisible(self.tableView.tableFooterView!.frame, animated: false)
            }
        } else {
            self.tableView.scrollRectToVisible(self.tableView.tableFooterView!.frame, animated: true)
        }
    }
    
    /// This method will layout tableView once when enter controller.
    ///
    /// Call this method when first load data.(called in the `viewDidLayoutSubviews` method)
    public func reloadDataWhenDataFirstLoad() {
        defer { viewDidLayout = true }
        if viewDidLayout { return }
        tableView.reloadData()
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        // The default tableView.contentOffset.y value is -tableView.safeAreaInsets.top
        let cellHeight = calculateTableViewCellTotalHeight()
        var offset = cellHeight + tableFooterHeight - tableView.height
        if hasHistoryMessage() {
            offset += tableHeaderHeight
            tableView.tableHeaderView = tableHeaderView
            tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        } else {
            if  offset <= tableView.contentOffset.y { return }
            tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        }
    }
    
    //MARK: - InputView ContentView View Handler
    
    private func showInputAccessoryContentView(_ componentView: InputAssessoryContentViewProtocol) {
        if componentView.position == .coverInput {
            componentView.frame = chatInputView.textField.frame
            chatInputView.contentView.addSubview(componentView)
        } else {
            let viewHeight = componentView.sizeThatFits(.zero).height
            inputAccessoryContentViewFrame = CGRect(x: 0, y: view.height - viewHeight, width: self.view.width, height: viewHeight)
            componentView.frame = CGRect(x: 0, y: view.height, width: view.width, height: viewHeight)
            view.addSubview(componentView)
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                componentView.frame = self.inputAccessoryContentViewFrame
            }
        }
    }
    
    private func hiddenInputAccessoryContentView(_ componentView: InputAssessoryContentViewProtocol) {
        if componentView.position == .coverInput {
            componentView.removeFromSuperview()
        } else {
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                componentView.y = self.view.height
            } completion: { _ in
                componentView.removeFromSuperview()
            }
        }
    }

    //MARK: Implemented by subclasses
    /// Implemented by subclasses
    open func inputViewConfirmInput(_ text: String) {
    }

    
    /// Execute load history messages, implemented by subclasses
    open func loadingHistoryMessages(completion: (Bool) -> Void) {
    }
    
    /// Check has more history messages or not.
    ///
    ///  If there are history messages, can triger loading more messages event.
    open func hasHistoryMessage() -> Bool {
        false
    }
    
}



//MARK: - UITableViewDataSource initialize
extension ChatRoomViewController: UITableViewDataSource {
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}


//MARK: - UIScrollView Delegate Handler
extension ChatRoomViewController:  UITableViewDelegate {
    
    func hiddenInputView() {
        pingInputViewToBottom = true
        view.endEditing(true)
        if let selectAccessoryView = chatInputView.selectAccessoryView {
            hiddenAccessoryView(selectAccessoryView)
        }
        layoutTableView(with: inputAccessoryContentViewFrame)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        hiddenInputView()
        
        if refreshState == .loadingDataCompleted {
            scrollView.bounces = false
            // delay to refresh
            if delayImmediateUpdateUITimeInterval > 0 {
                usleep(delayImmediateUpdateUITimeInterval)
            }
    
            /**
             由于部分 iOS 版本通过 `scrollView.contentSize` 得到的值不正确，所以只能通过计算所有 cell 的高度来计算分页前后增加的高度
             let beforeContentSize = scrollView.contentSize
             
             let endContentSize = scrollView.contentSize
             
             scrollView.setContentOffset(CGPoint(x: 0, y: endContentSize.height - beforeContentSize.height + scrollView.contentOffset.y), animated: false)
             */
            
            let beforeCellsHeight = calculateTableViewCellTotalHeight()
            reloadDataImmidiate()
            let endCellsHeight = calculateTableViewCellTotalHeight()
            var headerHeight: CGFloat = 0
            if !self.hasHistoryMessage() {
                headerHeight = tableHeaderHeight
                self.tableView.tableHeaderView = nil
            }
            // 在插入新的 cell前添加了 tableHeaderView，插入完成后 tableHeaderView 被移除，所以要减去 tableHeaderView 的高度
            
            let offsetY = endCellsHeight - beforeCellsHeight - headerHeight + scrollView.contentOffset.y
            scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
            loadPageSuccessContentOffset = scrollView.contentOffset
            scrollView.bounces = true
        }
    }
    

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if !viewDidLayout { return }
        
        // keep contentOffset
        if loadPageSuccessContentOffset != .zero {
            scrollView.setContentOffset(loadPageSuccessContentOffset, animated: false)
            loadPageSuccessContentOffset = .zero
        }
        
        let contentOffsetY = scrollView.contentOffset.y
        if contentOffsetY < 0 && hasHistoryMessage()
            && !indicatorView.isAnimating
            && inputAccessoryContentViewFrame == .zero
            && refreshState == .normal {
            refreshState = .prepared
            indicatorView.startAnimating()
        }
    }
    
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        prepareLoadHistoryPage()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        prepareLoadHistoryPage()
    }
    
    private func prepareLoadHistoryPage() {
        if refreshState == .prepared  {
            refreshState = .loadingData
            loadingHistoryMessages { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.refreshState = .loadingDataCompleted
                } else {
                    self.cancelLoadingPage()
                }
            }
        }
    }
    
    /// cancel loading state
    private func cancelLoadingPage() {
        self.indicatorView.stopAnimating()
        self.tableView.scrollsToTop = true
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.refreshState = .normal
    }
    
    /// calculate all cell's total height
    private func calculateTableViewCellTotalHeight() -> CGFloat {
        let numberOfCount = tableView.numberOfRows(inSection: 0)
        guard numberOfCount > 0 else  { return 0 }
        
        var contentHeight: CGFloat = 0
        for index in 0..<numberOfCount {
            let cellHeight = tableView.delegate!.tableView!(tableView, heightForRowAt: IndexPath(row: index, section: 0))
            contentHeight += cellHeight
        }
        return contentHeight
    }

}

extension ChatRoomViewController: InputViewDelegate {

    func inputView(_ inputView: ChatInputView, show newAccessoryView: ChatInputView.SelectAccessoryView, dismiss oldAccessoryView: ChatInputView.SelectAccessoryView?) {
        
        if let oldAccessoryView = oldAccessoryView {
            hiddenAccessoryView(oldAccessoryView)
        }
        switch newAccessoryView {
        case .input: break // 显示由 keyboardWillShowNotification 通知处理
        case .selected:
            showAccessoryView(newAccessoryView)
        }
    }
    
    func hiddenAccessoryView(_ accessoryView: ChatInputView.SelectAccessoryView) {
        switch accessoryView {
        case .input: view.endEditing(true)
        case let .selected(accessoryView, _):
            accessoryView.titleView.isSelected = false
            hiddenInputAccessoryContentView(accessoryView.contentView)
        }
    }
    
    func showAccessoryView(_ accessoryView: ChatInputView.SelectAccessoryView) {
        if case let .selected(view, _) = accessoryView {
            view.endEditing(true)
            pingInputViewToBottom = view.contentView.position == .coverInput
            showInputAccessoryContentView(view.contentView)
            layoutTableView(with: inputAccessoryContentViewFrame)
            scrollTableViewContentToBottomWhenInputViewComponentWillShow()
        }
    }
}
