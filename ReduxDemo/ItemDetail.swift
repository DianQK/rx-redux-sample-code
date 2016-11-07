//
//  ItemDetail.swift
//  ReduxDemo
//
//  Created by DianQK on 06/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxExtensions

class ItemDetail: UIViewController {

    @IBOutlet private weak var editItemDetailBarButtonItem: ReactiveBarButtonItem! {
        didSet {
            editItemDetailBarButtonItem
                .rx.tap
                .withLatestFrom(_state.item.displayItem.asObservable().filterNil())
                .map { Action.item(.modifyItem($0)) }
                .dispatch()
                .addDisposableTo(editItemDetailBarButtonItem.disposeBag)
        }
    }

    @IBOutlet private weak var displayImageView: UIImageView! {
        didSet {
            _state.item.displayItem.asObservable().filterNil()
                .flatMap { $0.logo.asObservable() }
                .bindTo(displayImageView.rx.image)
                .addDisposableTo(rx.disposeBag) // TODO
        }
    }

    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            _state.item.displayItem.asObservable().filterNil()
                .flatMap { $0.title.asObservable() }
                .bindTo(titleLabel.rx.text)
                .addDisposableTo(rx.disposeBag)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        _state.item.displayItem.asObservable().takeWhile { $0 != nil }
//            .subscribe(onCompleted: {
//                print("count")
//                self.navigationController?.async.popViewController(animated: false)
//            })
//            .addDisposableTo(rx.disposeBag)
        Observable.combineLatest(rx.sentMessage(#selector(ItemDetail.viewWillAppear(_:))).map { _ in },
                         _state.item.displayItem.asObservable().filter { $0 == nil }.map { _ in }) { _,_ in }
            .take(1)
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.async.popViewController(animated: false)
            })
            .addDisposableTo(rx.disposeBag)

    }

    deinit {
        dispatch(Action.item(.popCheckDetail))
    }

}
