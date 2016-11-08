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
import SnapKit

let _displayItem = _state.item.displayItem.asObservable().filterNil()

class ItemDetail: ReactiveViewController {

    private lazy var editItemDetailBarButtonItem: ReactiveBarButtonItem = ReactiveBarButtonItem(
            title: .just("Edit"),
            isEnabled: .just(true),
            tap: { $0.withLatestFrom(_displayItem)
                .map { Action.item(.modifyItem($0)) }
                .dispatch() })

    private lazy var displayImageView: ReactiveImageView = ReactiveImageView(image: _displayItem.flatMap { $0.logo.asObservable() })

    private lazy var titleLabel: ReactiveLabel = ReactiveLabel(text: _displayItem.flatMap { $0.title.asObservable() })

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
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

        self.navigationItem.rightBarButtonItem = editItemDetailBarButtonItem

        self.view.addSubview(displayImageView)
        displayImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(120)
            make.leading.equalToSuperview().offset(60)
            make.trailing.equalToSuperview().offset(-60)
            make.width.equalTo(self.displayImageView.snp.height)
        }

        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.displayImageView.snp.centerX)
            make.top.equalTo(self.displayImageView.snp.bottom).offset(30)
        }

    }

    deinit {
        dispatch(Action.item(.popCheckDetail))
    }

}
