//
//  Notification+Extension.swift
//  ChatRoom
//
//  Created by 蔡志文 on 2021/10/19.
//

import UIKit

extension Notification {
    var keyboardFrame: CGRect {
        let frameKey = UIViewController.keyboardFrameEndUserInfoKey
        let frame = userInfo?.first(where: { (key, value) -> Bool in
            key as! String == frameKey
        }).flatMap({ dict -> CGRect? in
            dict.value as? CGRect
        })
        return frame ?? .zero
    }
}
