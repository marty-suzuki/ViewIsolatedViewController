//
//  AnyViewContainer.swift
//  ViewModelLike
//
//  Created by marty-suzuki on 2021/09/23.
//

import class UIKit.UIView

public struct AnyViewContainer<Input, Output>: ViewContainer {

    public let input: Input
    public let output: Output
    public let view: UIView

    public init<T: ViewContainer>(_ container: T) where T.Input == Input, T.Output == Output {
        self.input = container.input
        self.output = container.output
        self.view = container.view
    }
}
