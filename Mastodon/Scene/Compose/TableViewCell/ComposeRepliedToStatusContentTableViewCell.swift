//
//  ComposeRepliedToStatusContentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-28.
//

import UIKit
import Combine

final class ComposeRepliedToStatusContentTableViewCell: UITableViewCell {

    var disposeBag = Set<AnyCancellable>()

    let statusView = StatusView()

    let framePublisher = PassthroughSubject<CGRect, Never>()

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag.removeAll()
        statusView.prepareForReuse()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        framePublisher.send(bounds)
    }

}

extension ComposeRepliedToStatusContentTableViewCell {

    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear

        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).identifier("statusView.top to ComposeRepliedToStatusContentCollectionViewCell.contentView.top"),
            statusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10).identifier("ComposeRepliedToStatusContentCollectionViewCell.contentView.bottom to statusView.bottom"),
        ])
        statusView.setup(style: .composeStatusReplica)
    }

}

