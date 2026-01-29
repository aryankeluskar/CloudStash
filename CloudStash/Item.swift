//
//  UploadedFile.swift
//  CloudStash
//
//  Created by Fayaz Ahmed Aralikatti on 12/01/26.
//

import Foundation
import SwiftData

@Model
final class UploadedFile {
    var filename: String
    var key: String
    var url: String
    var size: Int64
    var uploadedAt: Date

    init(filename: String, key: String, url: String, size: Int64, uploadedAt: Date = Date()) {
        self.filename = filename
        self.key = key
        self.url = url
        self.size = size
        self.uploadedAt = uploadedAt
    }
}

@Model
final class StashedFile {
    var filename: String
    var localPath: String      // filename within the stash directory
    var size: Int64
    var stashedAt: Date

    init(filename: String, localPath: String, size: Int64, stashedAt: Date = Date()) {
        self.filename = filename
        self.localPath = localPath
        self.size = size
        self.stashedAt = stashedAt
    }
}
