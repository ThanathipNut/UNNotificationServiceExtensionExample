//
//  NotificationService.swift
//  NotificationService
//
//  Created by Krzysztof Deneka on 15/05/2020.
//  Copyright © 2020 biz.blastar. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        defer {
            contentHandler(bestAttemptContent ?? request.content)
        }
        let fcm_options = request.content.userInfo["fcm_options"] as? [String : Any]
        let imageUrl = fcm_options?["image"] as? String
        if let imgUrl = imageUrl {
            if let attachment = parseAttachment(imageUrl: imgUrl) {
                bestAttemptContent?.attachments = [attachment]
                return
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    func parseAttachment(imageUrl: String) -> UNNotificationAttachment? {
        if let imageData = try? Data(contentsOf: URL(string: imageUrl)!) {
            return try? UNNotificationAttachment(data: imageData, options: nil)
        }
        
        return nil
    }
}

extension UNNotificationAttachment {

    convenience init(data: Data, options: [NSObject: AnyObject]?) throws {
        let fileManager = FileManager.default
        let temporaryFolderName = ProcessInfo.processInfo.globallyUniqueString
        let temporaryFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(temporaryFolderName, isDirectory: true)

        try fileManager.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true, attributes: nil)
        let imageFileIdentifier = UUID().uuidString + ".jpg"
        let fileURL = temporaryFolderURL.appendingPathComponent(imageFileIdentifier)
        try data.write(to: fileURL)
        try self.init(identifier: imageFileIdentifier, url: fileURL, options: options)
    }
}
