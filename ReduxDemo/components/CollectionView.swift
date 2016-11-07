//
//  CollectionView.swift
//  ReduxDemo
//
//  Created by DianQK on 03/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxExtensions
import RxDataSources

class CollectionView: ReactiveCollectionView {

    private typealias IconSectionModel = AnimatableSectionModel<String, IconItem>

    private let _dataSource = RxCollectionViewSectionedAnimatedDataSource<IconSectionModel>()

    override func commonInit() {
        _dataSource.configureCell = { _, collectionView, indexPath, element in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.iconCell, for: indexPath)!
            cell.item.onNext(element)
            return cell
        }

        _dataSource.moveItem = { _, sourceIndexPath, destinationIndexPath in
            dispatch(Action.collection(.move(sourceIndex: sourceIndexPath.row, destinationIndex: destinationIndexPath.row)))
        }

        _dataSource.canMoveItemAtIndexPath = { _, indexPath in
            return indexPath.row < _state.collection.elements.value.count
        }

        Observable
            .combineLatest(_state.collection.elements.asObservable(), _state.collection.isEditing.asObservable()) { items, isEditing -> [IconItem] in
                switch isEditing {
                case true:
                    return items
                case false:
                    return items + [IconItem(id: 0, logo: R.image.btn_add()!, title: "Add")]
                }
            }
            .map { [IconSectionModel(model: "", items: $0)] }
            .bindTo(self.rx.items(dataSource: _dataSource))
            .addDisposableTo(disposeBag)

        let long = UILongPressGestureRecognizer()
        long.rx.event
            .subscribe(onNext: { [unowned self] gesture in
                switch gesture.state {
                case .began:
                    guard let selectedIndexPath = self.indexPathForItem(at: gesture.location(in: self)),
                        let canMoveItemAtIndexPath = self._dataSource.canMoveItemAtIndexPath,
                        canMoveItemAtIndexPath(self._dataSource, selectedIndexPath) else {
                        break
                    }
                    self.beginInteractiveMovementForItem(at: selectedIndexPath)
                    dispatch(Action.collection(.edit))
                case .changed:
                    self.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
                case .ended:
                    self.endInteractiveMovement()
                case .cancelled, .failed, .possible:
                    self.cancelInteractiveMovement()
                }
            })
            .addDisposableTo(disposeBag)
        self.addGestureRecognizer(long)

        self.rx.modelSelected(IconItem.self)
            .buffer(timeSpan: 0.4, count: 2, scheduler: MainScheduler.instance)
            .asObservable()
            .flatMap { items -> Observable<Action> in
                if items.count == 2 && items[0] == items[1] {
                    return Observable.just(Action.item(.modifyItem(items[0])))
                }
                if let item = items.first , items.count == 1 {
                    if item.id != 0 {
                        if !_state.collection.isEditing.value {
                            dispatch(Action.item(.checkDetail(item)))
                        }
                        return Observable.empty()
                    } else {
                        let nextID = (_state.collection.elements.value.max(by: { $0.id < $1.id })?.id ?? 0) + 1
                        let action = Action.collection(.add(item: IconItem(id: nextID, logo: R.image.dianQK()!, title: "\(nextID)")))
                        return Observable.just(action)
                    }
                }
                return Observable.empty()
            }
            .dispatch()
            .addDisposableTo(disposeBag)

    }

}
