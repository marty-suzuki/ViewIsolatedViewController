//
//  ViewContainer.swift
//  ViewModelLike
//
//  Created by marty-suzuki on 2021/09/23.
//

import class UIKit.UIView

public protocol ViewContainer {
    associatedtype Input
    associatedtype Output
    var input: Input { get }
    var output: Output { get }
    var view: UIView { get }
}

extension ViewContainer {
    public func eraseToAnyViewContainer() -> AnyViewContainer<Input, Output> {
        .init(self)
    }
}

extension ViewContainer where Self: UIView {
    public var view: UIView { self }
}
