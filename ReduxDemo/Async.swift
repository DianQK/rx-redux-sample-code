//
//  Async.swift
//  ReduxDemo
//
//  Created by DianQK on 07/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit

struct Async<Base> {
    let base: Base

    init(_ base: Base) {
        self.base = base
    }
}

extension Async where Base: UINavigationController {
    func popViewController(animated: Bool) {
        DispatchQueue.main.async {
            self.base.popViewController(animated: animated)
        }
    }
}

extension NSObjectProtocol {
    var async: Async<Self> {
        return Async(self)
    }
}
