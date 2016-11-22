//
//  Review.swift
//  AppReviewsMailer
//
//  Created by Stanislav Sidelnikov on 11/11/16.
//  Copyright © 2016 StanSidel. All rights reserved.
//

import Foundation

class Review {
    var id: String
    var title: String?
    var content: String?
    var rating: Int?
    var version: String?
    var author: Author?
    var updated: Date?
    
    init(id: String) {
        self.id = id
    }
}

struct Author {
    var name: String
    var link: String
}
