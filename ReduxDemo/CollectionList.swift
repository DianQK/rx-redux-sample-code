//
//  CollectionList.swift
//  ReduxDemo
//
//  Created by DianQK on 04/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxExtensions

class CollectionList: UIViewController {

    @IBOutlet private weak var cleanBarButtonItem: ReactiveBarButtonItem! {
        didSet {
            cleanBarButtonItem
                .rx.tap
                .replace(with: Action.collection(.clean))
                .dispatch()
                .addDisposableTo(cleanBarButtonItem.disposeBag)

            _state.collection.elements.asObservable()
                .map { $0.isNotEmpty }
                .bindTo(cleanBarButtonItem.rx.isEnabled)
                .addDisposableTo(cleanBarButtonItem.disposeBag)
        }
    }

    @IBOutlet private weak var collectionView: CollectionView!

    @IBOutlet private weak var collectionEditBarButtonItem: ReactiveBarButtonItem! {
        didSet {
            _state.collection
                .isEditing.asObservable()
                .map { $0 ? "Done" : "Edit" }
                .bindTo(collectionEditBarButtonItem.rx.title)
                .addDisposableTo(collectionEditBarButtonItem.disposeBag)

            let hasElements = _state.collection.elements.asObservable()
                .map { $0.isNotEmpty }
                .shareReplay(1)

            hasElements
                .bindTo(collectionEditBarButtonItem.rx.isEnabled)
                .addDisposableTo(collectionEditBarButtonItem.disposeBag)

            hasElements.filter { !$0 }
                .map { _ in  Action.collection(.done) }
                .dispatch()
                .addDisposableTo(collectionEditBarButtonItem.disposeBag)

            collectionEditBarButtonItem.rx.tap.asObservable()
                .replace(with: Action.collection(.change))
                .dispatch()
                .addDisposableTo(collectionEditBarButtonItem.disposeBag)
        }
    }

}
