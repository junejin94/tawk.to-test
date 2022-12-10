//
//  CustomTableViewCells.swift
//  tawk.to
//
//  Created by Phua June Jin on 09/12/2022.
//

import Foundation
import UIKit
import Combine

// Custom base cell for UITableView
class CustomCellBase: UITableViewCell {
    var profileImageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false

        return img
    }()

    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    var detailLabel: UILabel = {
        let label = UILabel()
        label.font = label.font.withSize(12)
        label.textColor = .secondaryLabel
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true

        return view
    }()

    var noteView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "note.text"))
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        containerView.addSubview(nameLabel)
        containerView.addSubview(detailLabel)

        self.contentView.addSubview(profileImageView)
        self.contentView.addSubview(containerView)
        self.contentView.addSubview(noteView)

        profileImageView.centerYAnchor.constraint(equalTo:self.contentView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant:75).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant:75).isActive = true
        profileImageView.leadingAnchor.constraint(equalTo:self.contentView.leadingAnchor, constant:16).isActive = true

        containerView.centerYAnchor.constraint(equalTo:self.contentView.centerYAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo:self.profileImageView.trailingAnchor, constant:16).isActive = true
        containerView.heightAnchor.constraint(equalToConstant:40).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.noteView.leadingAnchor, constant:-8).isActive = true

        nameLabel.topAnchor.constraint(equalTo:self.containerView.topAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo:self.containerView.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo:self.containerView.trailingAnchor).isActive = true

        detailLabel.topAnchor.constraint(equalTo:self.nameLabel.bottomAnchor).isActive = true
        detailLabel.leadingAnchor.constraint(equalTo:self.containerView.leadingAnchor).isActive = true
        detailLabel.trailingAnchor.constraint(equalTo:self.containerView.trailingAnchor).isActive = true

        noteView.centerYAnchor.constraint(equalTo:self.contentView.centerYAnchor).isActive = true
        noteView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        noteView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        noteView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16).isActive = true

        noteView.isHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 16
        self.layer.borderColor = UIColor.secondaryLabel.cgColor
        
        self.profileImageView.cropCircle()
    }

    func showNote(status: Bool) {
        noteView.isHidden = !status
    }
}

class CustomCellNormal: CustomCellBase, Configurable {
    func configure(data: User) {
        if let img = data.image {
            self.profileImageView.image = UIImage(data: img)
        } else {
            self.profileImageView.image = UIImage()
        }

        self.nameLabel.text = data.login ?? ""

        if let detail = data.detail {
            self.detailLabel.text = detail.bio ?? ""
        } else {
            self.detailLabel.text = ""
        }

        self.showNote(status: false)
    }
}

class CustomCellNote: CustomCellNormal {
    override func configure(data: User) {
        super.configure(data: data)

        if let detail = data.detail, let note = detail.notes, !note.isEmpty {
            self.showNote(status: true)
        }
    }
}

class CustomCellInverted: CustomCellNormal {
    override func configure(data: User) {
        super.configure(data: data)

        if let detail = data.detail, let note = detail.notes, !note.isEmpty {
            self.showNote(status: true)
        }
    }
}

protocol ReusableCell: AnyObject {
    static var reuseIdentifier: String { get }
}

extension ReusableCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableCell {}

extension UITableView {
    func registerCell<T: UITableViewCell>(cellClass: T.Type) {
        self.register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func dequeue<T: UITableViewCell>(cellClass: T.Type, indexPath: IndexPath) -> T {
        return self.dequeue(withIdentifier: cellClass.reuseIdentifier, indexPath: indexPath)
    }

    private func dequeue<T: UITableViewCell>(withIdentifier id: String, indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: id, for: indexPath) as! T
    }
}

protocol Configurable {
    associatedtype T
    func configure(data: T)
}
