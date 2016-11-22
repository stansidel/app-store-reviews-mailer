//
//  ReviewsMailer.swift
//  AppReviewsMailer
//
//  Created by Stanislav Sidelnikov on 11/22/16.
//  Copyright © 2016 StanSidel. All rights reserved.
//

import Foundation

class ReviewsMailer {
    var recipients: [String]
    
    init(recipients: [String]) {
        self.recipients = recipients
    }
    
    func mail(reviews: [Review]) throws {
        var stringReviews = [String]()
        for review in reviews {
            stringReviews.append(reviewForMail(review))
        }
        let subject = "New AppStore Reviews"
        let mailCommand = "echo \"\(stringReviews.joined(separator: "\n"))\" | mail -s \"\(subject)\" \(recipients.joined(separator: ","))"
        _ = try executeCommand(path: "/bin/sh", withOptions: ["-c", mailCommand])
    }
    
    fileprivate lazy var updatedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm Z"
        return formatter
    }()
    
    fileprivate func reviewForMail(_ review: Review) -> String {
        var result = "New review:\n"
        let blackStar = "★"
        let whiteStar = "☆"
        var ratingString = ""
        if let rating = review.rating {
            ratingString = "\(rating) "
            for _ in 1...rating {
                ratingString.append(blackStar)
            }
            for _ in rating..<5 {
                ratingString.append(whiteStar)
            }
        }
        result += "\(review.title ?? "No title") (\(ratingString))\n"
        if let content = review.content {
            result += "\(content)\n"
        }
        if let version = review.version {
            result += "Version: \(version)\n"
        }
        if let author = review.author {
            result += "\(author.name) (\(author.link))\n"
        }
        if let updated = review.updated {
            result += "Updated on: \(updatedDateFormatter.string(from: updated))\n"
        }
        return result
    }
    
    fileprivate func executeCommand(path: String, withOptions options: [String]?) throws -> String? {
        var result: String?
        if FileManager.default.fileExists(atPath: path) {
            let pipe = Pipe()
            let file = pipe.fileHandleForReading
            let task = Process()
            // https://developer.apple.com/library/mac/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html
            task.launchPath = path
            task.arguments = options
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.launch()
            
            let data = file.readDataToEndOfFile()
            file.closeFile()
            
            let output = String(data: data, encoding: String.Encoding.utf8)
            result = output
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString(
                    String(format: "Unable to find command at path %@", path),
                    comment: "ReviewsMailer.executeCommand(_:withOptions:) file not found error"
                )
            ]
            let error = NSError(domain: "ReviewsMailer", code: 1001, userInfo: userInfo)
            throw error
        }
        return result
    }
}
