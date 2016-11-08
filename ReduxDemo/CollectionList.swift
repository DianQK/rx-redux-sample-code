//
//  CollectionList.swift
//  ReduxDemo
//
//  Created by DianQK on 04/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxExtensions

typealias IconSectionModel = AnimatableSectionModel<String, IconItem>

class CollectionList: ReactiveViewController {

    private lazy var cleanBarButtonItem: ReactiveBarButtonItem = ReactiveBarButtonItem(
        title: Observable.just("Clean"),
        isEnabled: _state.collection.elements.asObservable().map { $0.isNotEmpty },
        tap: { $0.replace(with: Action.collection(.clean)).dispatch() })

    private lazy var collectionView: ReactiveCollectionView<IconSectionModel> = {
        let layout = AutomaticCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 86, height: 100)
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        let collectionView = ReactiveCollectionView(
            layout: layout,
            register: (IconCell.self, "IconCell"),
            configureCell: { _, collectionView, indexPath, element in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IconCell", for: indexPath) as! IconCell
                cell.item.onNext(element)
                return cell },
            modelSelected: {
                $0.buffer(timeSpan: 0.4, count: 2, scheduler: MainScheduler.instance).asObservable()
                    .flatMap { items -> Observable<Action> in
                        // 使用 enum 是更佳的方案
                        if items.count == 2 && items[0] == items[1], items[0].id != 0 {
                            return Observable.just(Action.item(.modifyItem(items[0])))
                        }
                        if let item = items.first , items.count == 1 {
                            if item.id != 0 {
                                if !_state.collection.isEditing.value {
                                    return Observable.just(Action.item(.checkDetail(item)))
                                }
                            } else {
                                let nextID = (_state.collection.elements.value.max(by: { $0.id < $1.id })?.id ?? 0) + 1
                                let action = Action.collection(.add(item: IconItem(id: nextID, logo: R.image.dianQK()!, title: "\(nextID)")))
                                return Observable.just(action)
                            }
                        }
                        return Observable.empty()
                    }
                    .dispatch() },
            data: Observable.combineLatest(_state.collection.elements.asObservable(), _state.collection.isEditing.asObservable()) { items, isEditing -> [IconItem] in
                    switch isEditing {
                    case true: return items
                    case false: return items + [IconItem(id: 0, logo: R.image.btn_add()!, title: "Add")]
                    }
                }
                .map { [IconSectionModel(model: "", items: $0)] }
            )
        collectionView.backgroundColor = .white

        collectionView._dataSource.canMoveItemAtIndexPath = { _, indexPath in
            return indexPath.row < _state.collection.elements.value.count
        }

        let long = UILongPressGestureRecognizer()
        long.rx.event
            .subscribe(onNext: { [unowned self] gesture in
                switch gesture.state {
                case .began:
                    guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)),
                        let canMoveItemAtIndexPath = collectionView._dataSource.canMoveItemAtIndexPath,
                        canMoveItemAtIndexPath(collectionView._dataSource, selectedIndexPath) else {
                            break
                    }
                    collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
                    dispatch(Action.collection(.edit))
                case .changed:
                    collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
                case .ended:
                    collectionView.endInteractiveMovement()
                case .cancelled, .failed, .possible:
                    collectionView.cancelInteractiveMovement()
                }
            })
            .addDisposableTo(collectionView.disposeBag)
        collectionView.addGestureRecognizer(long)

        _state.collection.elements.asObservable().filter { $0.isEmpty }
            .map { _ in Action.collection(.done) }
            .dispatch()
            .addDisposableTo(collectionView.disposeBag)

        return collectionView
    }()

    private lazy var collectionEditBarButtonItem: ReactiveBarButtonItem = ReactiveBarButtonItem(title: _state.collection.isEditing.asObservable()
                .map { $0 ? "Done" : "Edit" }, isEnabled: _state.collection.elements.asObservable()
                    .map { $0.isNotEmpty }, tap: { $0.replace(with: Action.collection(.change))
                        .dispatch() })

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = cleanBarButtonItem
        self.navigationItem.rightBarButtonItem = collectionEditBarButtonItem

        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

}
