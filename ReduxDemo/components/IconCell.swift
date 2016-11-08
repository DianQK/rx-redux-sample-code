//
//  IconCell.swift
//  RxDataSourcesExample
//
//  Created by DianQK on 03/11/2016.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxExtensions

//required init(
//    image: Observable<UIImage>,
//    title: Observable<String>,
//    isEditing: Observable<Bool>,
//    delete: @escaping ((Observable<Void>) -> Disposable)) {
//    iconImageView = ReactiveImageView(image: image)
//    titleLabel = ReactiveLabel(text: title)
//    deleteButton = ReactiveButton.init(title: .just("Delete"), tap: delete)
//    super.init(frame: CGRect.zero)
//    iconImageView.layer.cornerRadius = 8.0
//    iconImageView.layer.masksToBounds = true
//
//    self.contentView.addSubview(iconImageView)
//    iconImageView.snp.makeConstraints { (make) in
//        make.top.equalToSuperview().offset(15)
//        make.centerX.equalToSuperview()
//        make.width.height.equalTo(60)
//    }
//}

//hasElements.filter { !$0 }
//    .map { _ in  Action.collection(.done) }
//    .dispatch()
//    .addDisposableTo(collectionEditBarButtonItem.disposeBag)

class IconCell: UICollectionViewCell {

    public let disposeBag = DisposeBag()

    private lazy var iconImageView: ReactiveImageView = ReactiveImageView(image: self.item.flatMapLatest { $0.logo.asObservable() })

    private lazy var titleLabel: ReactiveLabel = ReactiveLabel(text: self.item.flatMapLatest { $0.title.asObservable() })

    private lazy var deleteButton: ReactiveButton = ReactiveButton(
        images: (.normal, .just(R.image.btn_delete()!)), (.highlighted, .just(R.image.btn_delete_press()!)),
        tap: { $0.withLatestFrom(self.item.asObservable()).map { Action.collection(CollectionAction.remove(item: $0)) }.dispatch() }) // TODO: 移除这里的 dispatch

    required override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        iconImageView.layer.cornerRadius = 8.0
        iconImageView.layer.masksToBounds = true

        deleteButton.contentMode = .scaleAspectFit

        self.contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
        }

        self.contentView.addSubview(titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(10)
            make.centerX.equalTo(self.iconImageView.snp.centerX)
        }

        self.contentView.addSubview(deleteButton)
        self.deleteButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.iconImageView.snp.leading)
            make.centerY.equalTo(self.iconImageView.snp.top)
            make.height.width.equalTo(20)
        }

        Observable.combineLatest(item, _state.collection
            .isEditing.asObservable()) { $0.1 }
            .bindTo(self.rx.isEditing)
            .addDisposableTo(disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let item = ReplaySubject<IconItem>.create(bufferSize: 1)

    func startWiggling() {
        guard contentView.layer.animation(forKey: "wiggle") == nil else { return }
        guard contentView.layer.animation(forKey: "bounce") == nil else { return }

        let angle = 0.03

        let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        wiggle.values = [-angle, angle]

        wiggle.autoreverses = true
        wiggle.duration = random(interval: 0.1, variance: 0.025)
        wiggle.repeatCount = Float.infinity

        contentView.layer.add(wiggle, forKey: "wiggle")

        let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounce.values = [4.0, 0.0]

        bounce.autoreverses = true
        bounce.duration = random(interval: 0.12, variance: 0.025)
        bounce.repeatCount = Float.infinity

        contentView.layer.add(bounce, forKey: "bounce")
    }

    func stopWiggling() {
        contentView.layer.removeAllAnimations()
    }

    func random(interval: TimeInterval, variance: Double) -> TimeInterval {
        return interval + variance * Double((Double(arc4random_uniform(1000)) - 500.0) / 500.0)
    }

    var isEditing: Bool = false {
        didSet {
            // guard oldValue != isEditing else { return }
            switch isEditing {
            case true:
                startWiggling()
                deleteButton.isHidden = false
            case false:
                stopWiggling()
                deleteButton.isHidden = true
            }
        }
    }

}

extension Reactive where Base: IconCell {
    var isEditing: UIBindingObserver<IconCell, Bool> {
        return UIBindingObserver(UIElement: self.base, binding: { (iconCell, isEditing) in
            // if iconCell.isEditing != isEditing {
            iconCell.isEditing = isEditing
            //}
        })
    }
}
