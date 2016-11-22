//
//  ReviewXMLParser.swift
//  AppReviewsMailer
//
//  Created by Stanislav Sidelnikov on 11/22/16.
//  Copyright © 2016 StanSidel. All rights reserved.
//

import Foundation

class ReviewsXMLParser: NSObject {
    var excludeReviewsIds: [String]?
    var excludeReviewsEarlier: Date?
    fileprivate(set) var data: Data?
    fileprivate(set) var reviews = [Review]()
    
    // MARK: Dependency Injection
    var xmlParserClass = XMLParser.self
    
    // MARK: Private vars
    fileprivate var xmlParser: XMLParser?
    fileprivate var completion: (([Review]?, Error?)->Void)?
    fileprivate var value = ""
    fileprivate var attribute = ""
    fileprivate var attributesDict = [String: String]()
    fileprivate var isInEntry = false
    fileprivate var isInAuthor = false
    fileprivate var authorDict = [String: String]()
    fileprivate var author: Author?
    fileprivate lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    // MARK: - Public interface
    func parse(_ data: Data, completion: @escaping ([Review]?, Error?)->Void) {
        self.data = data
        self.completion = completion
        xmlParser = xmlParserClass.init(data: data)
        xmlParser!.delegate = self
        xmlParser!.parse()
    }
}

extension ReviewsXMLParser: XMLParserDelegate {
    func parserDidStartDocument(_ parser: XMLParser) {
        reviews = [Review]()
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        completion?(reviews, nil)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parser error: \(parseError.localizedDescription).")
        completion?(nil, parseError)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "entry":
            isInEntry = true
            attributesDict = [String: String]()
            attribute = ""
            author = nil
        case "author":
            isInAuthor = true
            authorDict = [String: String]()
            attribute = ""
        case "content":
            guard attributeDict["type"] == "text" || attributesDict["content"] == nil else {
                attribute = ""
                break
            }
            attribute = elementName
        default:
            attribute = elementName
        }
        value = ""
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "entry":
            isInEntry = false
            guard author != nil else { break }
            guard let review = getReview(from: attributesDict, withAuthor: author) else { break }
            reviews.append(review)
        case "author":
            isInAuthor = false
            author = getAuthor(from: authorDict)
        default:
            guard isInEntry else { break }
            guard !attribute.isEmpty else { break }
            if isInAuthor {
                authorDict[attribute] = value
            } else {
                attributesDict[attribute] = value
            }
        }
        attribute = ""
        value = ""
    }
    
    fileprivate func getAuthor(from dict: [String: String]) -> Author? {
        guard let name = dict["name"], let uri = dict["uri"] else {
            return nil
        }
        return Author(name: name, link: uri)
    }
    
    fileprivate func getReview(from dict: [String: String], withAuthor author: Author?) -> Review? {
        guard let id = dict["id"] else {
            return nil
        }
        guard excludeReviewsIds?.index(of: id) == nil else {
            return nil
        }
        var updatedDate: Date? = nil
        if let dateString = dict["updated"] {
            updatedDate = formatter.date(from: dateString)
        }
        guard excludeReviewsEarlier == nil || updatedDate == nil || updatedDate! > excludeReviewsEarlier! else {
            return nil
        }
        
        let review = Review(id: id)
        review.author = author
        review.content = dict["content"]
        review.title = dict["title"]
        review.rating = Int(dict["im:rating"] ?? "-1")
        review.version = dict["im:version"]
        review.updated = updatedDate
        return review
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        value += string
    }
}
