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

class EditItem: ReactiveViewController {

    private lazy var cancelBarButtonItem: ReactiveBarButtonItem = ReactiveBarButtonItem(title: .just("Cancel"), tap: { $0.replace(with: Action.item(.cancelModify))
        .dispatch() })

    private lazy var saveBarButtonItem: ReactiveBarButtonItem = ReactiveBarButtonItem(title: .just("Save"), tap: { $0.replace(with: Action.item(.saveModify)).dispatch() } )

    private lazy var deleteButton: ReactiveButton = ReactiveButton(
        images: (.normal, .just(R.image.btn_delete()!)), (.highlighted, .just(R.image.btn_delete_press()!)),
        tap: { $0.withLatestFrom(_state.item.modifyItem.asObservable().filterNil())
            .subscribe(onNext: { item in
                dispatch(Action.item(.cancelModify))
                dispatch(Action.collection(.remove(item: item)))
                if let displayItem = _state.item.displayItem.value, displayItem == item {
                    dispatch(Action.item(.popCheckDetail))
                }
            }) })

    private lazy var editImageView: ReactiveImageView = ReactiveImageView(image: Observable.from([
        _state.item.modifyItem.asObservable()
            .filterNil()
            .flatMap { $0.logo.asObservable() }
            .take(1),
        _state.item.modifyImage.asObservable().filterNil()
        ]).merge(), tap: {
            $0.flatMapLatest {
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
                .map { Action.item(.modifyImage($0)) }
                .dispatch()
    })

    private lazy var editTitleField: ReactiveTextField = ReactiveTextField(
        text: _state.item.modifyItem.asObservable().filterNil().flatMap { $0.title.asObservable().map(Optional.init) },
        textChanged: { $0.map { Action.item(.modifyTitle($0!)) }.dispatch() })

    override func viewDidLoad() {
        super.viewDidLoad()
        _state.item.modifyItem.asObservable()
            .takeWhile { $0 != nil }
            .subscribe(onCompleted: {
                self.view.endEditing(true)
                dismissViewController(self, animated: true)
            })
            .addDisposableTo(rx.disposeBag)

        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        self.navigationItem.rightBarButtonItem = saveBarButtonItem

        self.view.addSubview(editImageView)
        editImageView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).offset(120)
            make.height.equalTo(120)
            make.width.equalTo(120)
            make.centerX.equalToSuperview()
        }

        self.view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.equalTo(self.editImageView.snp.centerY)
        }

        self.view.addSubview(editTitleField)
        editTitleField.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.editImageView.snp.centerX)
            make.top.equalTo(self.editImageView.snp.bottom).offset(30)
            make.width.equalTo(self.editImageView.snp.width)
        }
        
    }

}
