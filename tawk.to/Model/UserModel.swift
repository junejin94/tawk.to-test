//
//  User.swift
//  tawk.to
//
//  Created by Phua June Jin on 29/12/2022.
//

import Foundation
import UIKit
import Combine

class User: ObservableObject {
    var id: Int64?
    var login: String?
    var seen: Bool = false
    var notes: String?
    var image: UIImage = UIImage()
    var inverted: UIImage?

    var detail: Detail?

    /**
     Maps data from CoreData object to User model.

     - Parameters:
        - model: CoreData object
        - update: whether to update the user's image as well
     */
    func map(model: Users, update: Bool) async throws {
        self.image = try await getImage(id: model.id, url: model.avatar_url, update: update)
        self.id = model.id
        self.login = model.login
        self.seen = model.seen
        self.notes = model.notes
    }

    /**
     Updates the value of object.

     - Parameters:
        - model: CoreData object
     */
    func update(model: User) async {
        self.id = model.id
        self.login = model.login
        self.seen = model.seen
        self.notes = model.notes
        self.image = model.image

        /// Update the inverted image if it exists
        if (self.inverted != nil) {
            self.inverted = model.image.invertColor()
        }
    }
}
