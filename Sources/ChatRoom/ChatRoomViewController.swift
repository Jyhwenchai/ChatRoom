//
//  ChatRoomViewController.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/20.
//

import UIKit

private let tabBarAdditionHeight: CGFloat = ChatRoomContant.bottomSafeAreaHeight

open class ChatRoomViewController: UIViewController {

    /// Delay update UI when loading history messages completed.
    public var delayUpdateUITimeInterval: TimeInterval = 0.6
    
    /// Delay update UI immediately when loading history messages completed.
    public var delayImmediateUpdateUITimeInterval: UInt32 = 150_000
    
    public var globalAnimateTimeInterval: TimeInterval = 0.25
   
    /// Define pull up loading view height.
    public let tableHeaderHeight: CGFloat = 30.0
    
    /// TableView last cell spacing with input view.
    public let tableFooterHeight: CGFloat = 12.0
    
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
    public var chatInputBottomAccessoryView: InputBottomAccessoryViewProtocol? {
        didSet {
            chatInputView.bottomAccessoryView = chatInputBottomAccessoryView
            layoutViews()
        }
    }
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
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
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
            layoutViews()
            view.addSubview(tableView)
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
            
            chatInputView.textDidChangedClosure = { [weak self] in
                self?.inputViewTextDidChanged($0)
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
    
    func layoutViews() {
        let inputViewMinHeight = chatInputView.minHeight
        var frame = view.bounds
        frame.size.height = view.height - inputViewMinHeight - tabBarAdditionHeight
        tableView.frame = frame
        chatInputView.frame = CGRect(x: 0, y: frame.height, width: view.width, height: inputViewMinHeight)
        view.setNeedsLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(keyboardWillShowToken!)
    }

    //MARK: Main Method
    
    /// Reload data and update UI immediately when drag tableView and refreshState is `loadingDataCompleted`
    private func layoutImmidiate() {
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
    public func layoutIfLoadNewPageSuccess() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayUpdateUITimeInterval) {
 
            if self.refreshState != .loadingDataCompleted {
                return
            }
            
            self.refreshState = .updatingUI
            self.indicatorView.stopAnimating()
            
            let beforeContentHeight = self.tableView.contentSize.height
            self.tableView.reloadData()
            let currentContentHeight = self.tableView.contentSize.height
            
            if !self.hasHistoryMessage() {
                self.tableView.tableHeaderView = nil
            }
            
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
            // keep the original position of cells.
            let addContentHeight = currentContentHeight - beforeContentHeight
            var contentOffset = addContentHeight + self.tableView.contentOffset.y
            if !self.hasHistoryMessage() {
                contentOffset -= self.tableHeaderHeight
            }
            self.tableView.setContentOffset(CGPoint(x: 0, y: contentOffset), animated: false)
            self.refreshState = .normal
        }
       
    }
    
    /// Call this method when receive new message
    public func layoutIfReceiveMessage() {

        let numberOfSession = tableView.numberOfRows(inSection: 0)
        let indexPath = IndexPath(row: numberOfSession, section: 0)

        var contentOffsetY = tableView.contentSize.height
        // 1. only insert new cell
        tableView.performBatchUpdates { [weak self] in
            guard let self = self else { return }
            self.tableView.insertRows(at: [indexPath], with: .none)
        }

        // 2. update tableView position
        self.layoutTableView(with: inputAccessoryContentViewFrame)

        // 3. check contentSize whether over tableView.height and update contentOffset
        let safeAreaTop = tableView.safeAreaInsets.top
        if tableView.contentSize.height + safeAreaTop > tableView.height {
            let cellHeight = tableView(tableView, heightForRowAt: indexPath)
            contentOffsetY += cellHeight - tableView.height
            UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
                self.tableView.setContentOffset(CGPoint(x: 0, y: contentOffsetY), animated: false)
            }
        }
    }

    /// This method will layout tableView once when enter controller.
    public func layoutIfFirstLoadData() {
        defer { viewDidLayout = true }
        if viewDidLayout { return }

        // The default tableView.contentOffset.y value is -tableView.safeAreaInsets.top
        if hasHistoryMessage() {
            tableView.tableHeaderView = tableHeaderView
        }
        tableView.reloadData()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let safeAreaTop = tableView.safeAreaInsets.top
        if tableView.contentSize.height + safeAreaTop > tableView.height {
            let contentOffsetY = tableView.contentSize.height - tableView.height
            tableView.setContentOffset(CGPoint(x: 0, y: contentOffsetY), animated: false)
        }
    }
    
    /// Update tableView position when keyboard or inputView frame changed.
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
        
        UIView.animate(withDuration: globalAnimateTimeInterval, delay: 0, options: componentAnimateType) {
            self.tableView.scrollRectToVisible(self.tableView.tableFooterView!.frame, animated: false)
        }
    }
    
    //MARK: - InputView ContentView View Handler
    
    private func showInputAccessoryContentView(_ componentView: InputAssessoryContentViewProtocol) {
        if componentView.position == .coverInput {
            componentView.frame = chatInputView.textView.frame
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
    open func inputViewTextDidChanged(_ attributed: NSAttributedString?) {
    }
    
    /// Implemented by subclasses
    open func inputViewConfirmInput(_ attributedText: NSAttributedString) {
    }

    
    /// Execute load history messages, implemented by subclasses
    open func startLoadingHistoryMessages(completion: (Bool) -> Void) {
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
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        0
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
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
            layoutImmidiate()
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
            startLoadingHistoryMessages { [weak self] success in
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
            let cellHeight = tableView(tableView, heightForRowAt: IndexPath(row: index, section: 0))
            contentHeight += cellHeight
        }
        return contentHeight
    }

}

extension ChatRoomViewController: InputViewDelegate {

    func inputView(_ inputView: ChatInputView,
                   show newSelectAccessoryView: ChatInputView.SelectAccessoryView,
                   dismiss oldSelectAccessoryView: ChatInputView.SelectAccessoryView?) {
        
        if let oldSelectAccessoryView {
            hiddenAccessoryView(oldSelectAccessoryView)
        }
        switch newSelectAccessoryView {
        case .input:
            pingInputViewToBottom = false // 显示由 keyboardWillShowNotification 通知处理
        case .selected:
            showAccessoryView(newSelectAccessoryView)
        }
    }
    
    func hiddenAccessoryView(_ accessoryView: ChatInputView.SelectAccessoryView) {
        switch accessoryView {
        case .input: view.endEditing(true)
        case let .selected(accessoryView):
            guard let contentView = accessoryView.contentView else { return }
            hiddenInputAccessoryContentView(contentView)
        }
    }
    
    func showAccessoryView(_ accessoryView: ChatInputView.SelectAccessoryView) {
        if case let .selected(view) = accessoryView {
            view.endEditing(true)
            guard let contentView = view.contentView else { return }
            pingInputViewToBottom = contentView.position == .coverInput
            showInputAccessoryContentView(contentView)
            layoutTableView(with: inputAccessoryContentViewFrame)
            scrollTableViewContentToBottomWhenInputViewComponentWillShow()
        }
    }
}
