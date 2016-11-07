//
//  EditItem.swift
//  ReduxDemo
//
//  Created by DianQK on 04/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxExtensions

class EditItem: UIViewController {

    @IBOutlet private weak var cancelBarButtonItem: ReactiveBarButtonItem! {
        didSet {
            cancelBarButtonItem.rx.tap
                .replace(with: Action.item(.cancelModify))
                .dispatch()
                .addDisposableTo(cancelBarButtonItem.disposeBag)
        }
    }

    @IBOutlet private weak var saveBarButtonItem: ReactiveBarButtonItem! {
        didSet {
            saveBarButtonItem.rx.tap.asObservable()
                .replace(with: Action.item(.saveModify))
                .dispatch()
                .addDisposableTo(saveBarButtonItem.disposeBag)
        }
    }

    @IBOutlet weak var deleteButton: UIButton! {
        didSet {
            deleteButton
                .rx.tap.asObservable()
                .withLatestFrom(_state.item.modifyItem.asObservable().filterNil())
                .subscribe(onNext: { item in
                    dispatch(Action.item(.cancelModify))
                    dispatch(Action.collection(.remove(item: item)))
                    if let displayItem = _state.item.displayItem.value, displayItem == item {
                        dispatch(Action.item(.popCheckDetail))
                    }
                })
                .addDisposableTo(rx.disposeBag)
        }
    }

    @IBOutlet private weak var editImageView: ReactiveImageView! {
        didSet {
            _state.item.modifyItem.asObservable()
                .filterNil()
                .flatMap { $0.logo.asObservable() }
                .take(1)
                .bindTo(editImageView.rx.image)
                .addDisposableTo(editImageView.disposeBag)

            let tap = UITapGestureRecognizer()
            let modifyImage = tap.rx.event.map { _ in }
                .flatMapLatest {
                    UIImagePickerController.rx.createWithParent(topViewController()!) { picker in
                        picker.sourceType = .photoLibrary
                        picker.allowsEditing = true
                        }
                        .flatMap { $0.rx.didFinishPickingMediaWithInfo }
                        .take(1) // catch error
                }
                .map { info in
                    return info[UIImagePickerControllerEditedImage] as! UIImage
                }
                .shareReplay(1)
            editImageView.isUserInteractionEnabled = true
            editImageView.addGestureRecognizer(tap)

            modifyImage
                .bindTo(editImageView.rx.image)
                .addDisposableTo(editImageView.disposeBag)

            modifyImage
                .map { Action.item(.modifyImage($0)) }
                .dispatch()
                .addDisposableTo(editImageView.disposeBag)
        }
    }

    @IBOutlet private weak var editTitleField: ReactiveTextField! {
        didSet {
            editTitleField.text = _state.item.modifyItem.value?.title.value
            editTitleField.rx.text
                .map { Action.item(.modifyTitle($0!)) }
                .dispatch()
                .addDisposableTo(editTitleField.disposeBag)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _state.item.modifyItem.asObservable()
            .takeWhile { $0 != nil }
            .subscribe(onCompleted: {
                self.view.endEditing(true)
                dismissViewController(self, animated: true)
            })
            .addDisposableTo(rx.disposeBag)
    }

}
