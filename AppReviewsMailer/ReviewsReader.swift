//
//  ReviewsReader.swift
//  AppReviewsMailer
//
//  Created by Stanislav Sidelnikov on 11/11/16.
//  Copyright © 2016 StanSidel. All rights reserved.
//

import Foundation

enum ReviewsFormat: String {
    case json = "json"
    case xml = "xml"
}

class ReviewsReader {
    var appId: String
    var langId: String
    var format = ReviewsFormat.xml
    
    init(appId: String, langId: String) {
        self.appId = appId
        self.langId = langId
    }
    
    func readReviews(after excludeReviewsEarlier: Date?, completion: @escaping ([Review]?, Error?)->Void) {
        let session = URLSession(configuration: .default)
        session.dataTask(with: url(for: .xml), completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, nil)
                return
            }
            let reviewsParser = ReviewsXMLParser()
            reviewsParser.excludeReviewsEarlier = excludeReviewsEarlier
            reviewsParser.parse(data, completion: completion)
        }).resume()
    }
    
    func readReviews(except excludeReviewsIds: [String]?, completion: @escaping ([Review]?, Error?)->Void) {
        let session = URLSession(configuration: .default)
        session.dataTask(with: url(for: .json), completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, nil)
                return
            }
            var jsonObject: Any!
            do {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            } catch let e {
                completion(nil, e)
                return
            }
            guard let entriesObject = ((jsonObject as? [String: Any])?["feed"] as? [String: Any])?["entry"] as? [[String: Any]] else {
                completion(nil, nil)
                return
            }
            var reviews = [Review]()
            for entryObject in entriesObject {
                guard let authorObject = entryObject["author"] as? [String: Any] else {
                    continue
                }
                guard let id = self.string(from: entryObject["id"]) else {
                    continue
                }
                guard excludeReviewsIds?.index(of: id) == nil else {
                    continue
                }
                let authorName = self.string(from: authorObject["name"])!
                let authorUri = self.string(from: authorObject["uri"])!
                let author = Author(name: authorName, link: authorUri)
                let review = Review(id: id)
                review.author = author
                review.content = self.string(from: entryObject["content"])
                review.title = self.string(from: entryObject["title"])
                review.rating = Int(self.string(from: entryObject["im:rating"]) ?? "-1")
                review.version = self.string(from: entryObject["im:version"])
                reviews.append(review)
            }
            completion(reviews, nil)
        }).resume()
    }
    
    // MARK: - Private
    
    fileprivate var rssUrlString: String { return "https://itunes.apple.com/\(langId)/rss/customerreviews/id=\(appId)/sortBy=mostRecent/" }
    fileprivate func url(for format: ReviewsFormat) -> URL {
        let string = rssUrlString + format.rawValue
        return URL(string: string)!
    }
    
    fileprivate func string(from: Any?) -> String? {
        return (from as? [String: Any])?["label"] as? String
    }
}
