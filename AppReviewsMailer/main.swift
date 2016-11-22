//
//  main.swift
//  AppReviewsMailer
//
//  Created by Stanislav Sidelnikov on 11/11/16.
//  Copyright © 2016 StanSidel. All rights reserved.
//

import Foundation

//let recipients = ["stansidel@yandex-team.ru"]
//let appId = "387272416"
//let langId = "ru"

let arguments = CommandLine.arguments
func argument(for option: String, in arguments: [String]) -> String? {
    guard let index = arguments.index(where: { $0 == "--\(option)"}) else { return nil }
    guard arguments.count > index + 1 else {
        print("Value for option \(option) not specified.")
        exit(100)
    }
    return arguments[index + 1]
}
func forceArgument(for option: String, in arguments: [String]) -> String {
    guard let value = argument(for: option, in: arguments) else {
        print("Option \(option) is not set. Set it via \"--\(option) <value>\".")
        exit(101)
    }
    return value
}

let appId = forceArgument(for: "app-id", in: arguments)
let langId = forceArgument(for: "lang-id", in: arguments)
let recipientsString = forceArgument(for: "recipients", in: arguments)
let recipients = recipientsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
guard recipients.count > 0 else {
    print("You should specify at least one recipient.")
    exit(201)
}

guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
    
        print("Unable to get documents dir.")
        exit(2)
}

//let file = ".processed_reviews"
//let path = dir.appendingPathComponent(file)
//
//var prevIds = [String]()
//var prevIdsText = ""
//
//if (try? path.checkResourceIsReachable()) ?? false {
//    do {
//        prevIdsText = try String(contentsOf: path, encoding: String.Encoding.utf8)
//        prevIds = prevIdsText.components(separatedBy: "\n")
//    } catch let e {
//        print("Unable to read from file \(file). Error: \(e.localizedDescription).")
//        exit(3)
//    }
//}

let dateFile = ".review_latest_date_\(appId)_\(langId)"
let datePath = dir.appendingPathComponent(dateFile)
let latestDateFormatter = DateFormatter()
latestDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
var latestDate: Date?
if (try? datePath.checkResourceIsReachable()) ?? false {
    do {
        let latestDateString = try String(contentsOf: datePath, encoding: String.Encoding.utf8)
        latestDate = latestDateFormatter.date(from: latestDateString)
    } catch let e {
        print("Unable to read from file \(dateFile). Error: \(e.localizedDescription).")
        exit(3)
    }
}

let reader = ReviewsReader(appId: appId, langId: langId)

var reviews: [Review]? = nil
var error: Error? = nil
var completed = false

reader.readReviews(after: latestDate) { (revs, err) in
    reviews = revs
    error = err
    completed = true
}

//reader.readReviews(except: prevIds) { (revs, err) in
//    reviews = revs
//    error = err
//    completed = true
//}

var i = 1
let max = 10
while (!completed) {
    var dots = ""
    for i in 1...i {
        dots += "."
    }
    //print("Reading reviews\(dots)\r")
    i = i < 10 ? i + 1 : 1
}

print("Reviews recieved: \(reviews?.count ?? 0)")

if let reviews = reviews, reviews.count > 0 {
    let mailer = ReviewsMailer(recipients: recipients)
    do {
        try mailer.mail(reviews: reviews)
    } catch let e {
        print("Unable to send the mail. Error: \(e.localizedDescription).")
        exit(5)
    }
    
    let referenceDate = Date.init(timeIntervalSinceReferenceDate: 0)
    let maxDate = reviews.map { $0.updated ?? referenceDate }.max()
    if let maxDate = maxDate {
        do {
            try (latestDateFormatter.string(from: maxDate)).write(to: datePath, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            print("Unable to write to file \(dateFile).")
            exit(2)
        }
    }
    
//    let ids = reviews.map { $0.id }.joined(separator: "\n")
//
//        //writing
//        do {
//            try (prevIdsText + "\n" + ids).write(to: path, atomically: false, encoding: String.Encoding.utf8)
//        }
//        catch {
//            print("Unable to write to file")
//            exit(2)
//        }
    
}

