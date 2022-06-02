//
//  UIView+Frame.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import UIKit

extension UIView {
    var x: CGFloat {
        get { frame.minX }
        set { frame.origin.x = newValue }
    }
    
    var y: CGFloat {
        get { frame.minY }
        set { frame.origin.y = newValue }
    }
    
    var width: CGFloat {
        get { frame.width }
        set { frame.size.width = newValue }
    }
    
    var height: CGFloat {
        get { frame.height }
        set { frame.size.height = newValue }
    }
    
    var size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }
    
    var centerX: CGFloat {
        get { center.x }
        set { center.x = newValue }
    }
    
    var centerY: CGFloat {
        get { center.y }
        set { center.y = newValue }
    }
    
    var minX: CGFloat {
        get { x }
    }
    
    var minY: CGFloat {
        get { y }
    }

    var midX: CGFloat {
        get { frame.midX }
    }
    
    var midY: CGFloat {
        get { frame.midY }
    }
    
    
    var maxX: CGFloat {
        get { x + width }
    }
    
    var maxY: CGFloat {
        get { y + height }
    }
    
    
    
    
}
