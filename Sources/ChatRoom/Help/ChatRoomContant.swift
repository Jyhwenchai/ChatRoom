//
//  Constant.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import Foundation
import UIKit

public enum ChatRoomContant {
    
    public static var window: UIWindow!

    public static var statusBarHeight: CGFloat {
        if #available(iOS 13, *) {
            return window.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.size.height
        }
    }
    
    public static var navigationBarHeight: CGFloat {
        44.0
    }
    
    public static var statusBarAndNavigationBarHeight: CGFloat {
        statusBarHeight + navigationBarHeight
    }
    
    public static var tabBarHeight: CGFloat {
        return 49 + bottomSafeAreaHeight
    }
    
    public static var hasSafeArea: Bool {
        if #available(iOS 11, *), let keyWindow = window {
            return keyWindow.safeAreaInsets.bottom > 0.0
        }
        return false
    }
    
    public static var bottomSafeAreaHeight: CGFloat {
        return hasSafeArea ? (window?.safeAreaInsets.bottom ?? 0) : 0
    }
}
