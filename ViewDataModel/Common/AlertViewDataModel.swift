//
//  AlertViewDataModel.swift
//  ViewDataModel
//
//  Created by marty-suzuki on 2021/10/02.
//

import UIKit

public struct AlertViewDataModel {

    public let title: String?
    public let message: String?
    public let actions: [Action]

    public init(
        title: String?,
        message: String?,
        actions: [AlertViewDataModel.Action]
    ) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}

extension AlertViewDataModel {

    public struct Action {

        public let title: String
        public let style: UIAlertAction.Style
        public let handler: (() -> Void)?

        public init(
            title: String,
            style:  UIAlertAction.Style,
            handler: (() -> Void)?
        ) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }
}
