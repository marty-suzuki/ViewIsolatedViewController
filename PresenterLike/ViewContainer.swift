//
//  ViewContainer.swift
//  PresenterLike
//
//  Created by marty-suzuki on 2021/09/23.
//

import class UIKit.UIView

public protocol ViewContainer: AnyObject {
    var view: UIView { get }
}

extension ViewContainer where Self: UIView {
    public var view: UIView { self }
}
