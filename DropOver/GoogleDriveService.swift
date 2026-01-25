//
//  GoogleDriveService.swift
//  DropOver
//
//  Created for DropOver App
//

import Foundation
import AuthenticationServices
import AppKit

// MARK: - Google Drive Service

actor GoogleDriveService {
    static let shared = GoogleDriveService()
    
    // TODO: Replace with your Google Cloud OAuth credentials
    private let clientId = "446555451602-1r29ev9fccp7ghnlblajsjiji153r6p8.apps.googleusercontent.com.apps.googleusercontent.com"
    private let redirectUri = "com.dropover.app:/oauth2callback"
    
    private let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenURL = "https://oauth2.googleapis.com/token"
    private let driveAPIBase = "https://www.googleapis.com/drive/v3"
    private let uploadAPIBase = "https://www.googleapis.com/upload/drive/v3"
    
    private let scopes = [
        "https://www.googleapis.com/auth/drive.file",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile"
    ]
    
    private let settings = SettingsManager.shared
    
    struct DriveError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    
    struct UploadResult {
        let fileId: String
        let url: String
    }
    
    struct DriveFile: Identifiable {
        let id: String
        let name: String
        let size: Int64
        let createdTime: Date
        let webViewLink: String?
        let thumbnailLink: String?
        
        var filename: String { name }
    }
    
    struct UserInfo {
        let email: String
        let name: String
        let picture: String?
    }
    
    // MARK: - OAuth Authentication
    
    func startOAuthFlow() async throws {
        let state = UUID().uuidString
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        var components = URLComponents(string: authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        guard let authURL = components.url else {
            throw DriveError(message: "Failed to create auth URL")
        }
        
        // Store code verifier for token exchange
        await MainActor.run {
            settings.oauthCodeVerifier = codeVerifier
            settings.oauthState = state
        }
        
        // Open in browser
        await MainActor.run {
            NSWorkspace.shared.open(authURL)
        }
    }
    
    func handleOAuthCallback(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw DriveError(message: "Invalid callback URL")
        }
        
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        
        // Verify state
        let savedState = await MainActor.run { settings.oauthState }
        guard let state = params["state"], state == savedState else {
            throw DriveError(message: "OAuth state mismatch")
        }
        
        guard let code = params["code"] else {
            if let error = params["error"] {
                throw DriveError(message: "OAuth error: \(error)")
            }
            throw DriveError(message: "No authorization code received")
        }
        
        // Exchange code for tokens
        let codeVerifier = await MainActor.run { settings.oauthCodeVerifier }
        try await exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)
        
        // Fetch user info
        try await fetchUserInfo()
    }
    
    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "client_id": clientId,
            "code": code,
            "code_verifier": codeVerifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ]
        
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DriveError(message: "Token exchange failed: \(body)")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        await MainActor.run {
            settings.accessToken = tokenResponse.access_token
            settings.refreshToken = tokenResponse.refresh_token ?? settings.refreshToken
            settings.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        }
    }
    
    private func refreshAccessToken() async throws {
        let refreshToken = await MainActor.run { settings.refreshToken }
        guard !refreshToken.isEmpty else {
            throw DriveError(message: "No refresh token available. Please sign in again.")
        }
        
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Refresh token is invalid, user needs to sign in again
            await MainActor.run {
                settings.signOut()
            }
            throw DriveError(message: "Session expired. Please sign in again.")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        await MainActor.run {
            settings.accessToken = tokenResponse.access_token
            settings.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        }
    }
    
    private func getValidAccessToken() async throws -> String {
        let tokenExpiry = await MainActor.run { settings.tokenExpiry }
        let accessToken = await MainActor.run { settings.accessToken }
        
        // Refresh if token expires in less than 5 minutes
        if tokenExpiry.timeIntervalSinceNow < 300 {
            try await refreshAccessToken()
            return await MainActor.run { settings.accessToken }
        }
        
        return accessToken
    }
    
    private func fetchUserInfo() async throws {
        let token = try await getValidAccessToken()
        
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError(message: "Failed to fetch user info")
        }
        
        let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
        
        await MainActor.run {
            settings.userEmail = userInfo.email
            settings.userName = userInfo.name ?? userInfo.email
            settings.userPicture = userInfo.picture
        }
    }
    
    // MARK: - File Operations
    
    func upload(fileURL: URL, progress: ((Double) -> Void)? = nil) async throws -> UploadResult {
        let isSignedIn = await MainActor.run { settings.isSignedIn }
        guard isSignedIn else {
            throw DriveError(message: "Not signed in. Please sign in with Google.")
        }
        
        let token = try await getValidAccessToken()
        let data = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mimeType = self.mimeType(for: fileURL.pathExtension)
        
        // Use multipart upload for metadata + content
        let boundary = UUID().uuidString
        var body = Data()
        
        // Metadata part
        let metadata: [String: Any] = ["name": filename]
        let metadataJSON = try JSONSerialization.data(withJSONObject: metadata)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataJSON)
        body.append("\r\n".data(using: .utf8)!)
        
        // File content part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: URL(string: "\(uploadAPIBase)/files?uploadType=multipart&fields=id,name,webViewLink")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let progressDelegate = UploadProgressDelegate { sent, expected in
            guard expected > 0 else { return }
            progress?(min(1, Double(sent) / Double(expected)))
        }
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: body, delegate: progressDelegate)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: responseData, encoding: .utf8) ?? ""
            throw DriveError(message: "Upload failed: \(errorBody)")
        }
        
        let fileResponse = try JSONDecoder().decode(DriveFileResponse.self, from: responseData)
        
        // Make file publicly accessible
        try await setPublicPermission(fileId: fileResponse.id)
        
        progress?(1.0)
        
        // Create direct link
        let publicURL = "https://drive.google.com/uc?id=\(fileResponse.id)&export=download"
        
        return UploadResult(fileId: fileResponse.id, url: publicURL)
    }
    
    private func setPublicPermission(fileId: String) async throws {
        let token = try await getValidAccessToken()
        
        var request = URLRequest(url: URL(string: "\(driveAPIBase)/files/\(fileId)/permissions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let permission: [String: Any] = [
            "role": "reader",
            "type": "anyone"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: permission)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError(message: "Failed to set public permission")
        }
    }
    
    func listFiles() async throws -> [DriveFile] {
        let isSignedIn = await MainActor.run { settings.isSignedIn }
        guard isSignedIn else {
            throw DriveError(message: "Not signed in")
        }
        
        let token = try await getValidAccessToken()
        
        var components = URLComponents(string: "\(driveAPIBase)/files")!
        components.queryItems = [
            URLQueryItem(name: "pageSize", value: "50"),
            URLQueryItem(name: "orderBy", value: "createdTime desc"),
            URLQueryItem(name: "fields", value: "files(id,name,size,createdTime,webViewLink,thumbnailLink)"),
            URLQueryItem(name: "q", value: "'me' in owners and trashed = false")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DriveError(message: "List failed: \(body)")
        }
        
        let listResponse = try JSONDecoder().decode(DriveListResponse.self, from: data)
        
        return listResponse.files.map { file in
            DriveFile(
                id: file.id,
                name: file.name,
                size: Int64(file.size ?? "0") ?? 0,
                createdTime: parseDate(file.createdTime) ?? Date(),
                webViewLink: file.webViewLink,
                thumbnailLink: file.thumbnailLink
            )
        }
    }
    
    func download(fileId: String, to destination: URL, progress: ((Double) -> Void)? = nil) async throws -> URL {
        let isSignedIn = await MainActor.run { settings.isSignedIn }
        guard isSignedIn else {
            throw DriveError(message: "Not signed in")
        }
        
        let token = try await getValidAccessToken()
        
        var request = URLRequest(url: URL(string: "\(driveAPIBase)/files/\(fileId)?alt=media")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError(message: "Download failed")
        }
        
        let expectedLength = httpResponse.expectedContentLength
        var data = Data()
        if expectedLength > 0 {
            data.reserveCapacity(Int(expectedLength))
        }
        
        var receivedLength: Int64 = 0
        for try await byte in asyncBytes {
            data.append(byte)
            receivedLength += 1
            
            if expectedLength > 0 && receivedLength % 65536 == 0 {
                progress?(Double(receivedLength) / Double(expectedLength))
            }
        }
        
        progress?(1.0)
        
        // Write to destination
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try data.write(to: destination)
        
        return destination
    }
    
    func deleteFile(fileId: String) async throws {
        let isSignedIn = await MainActor.run { settings.isSignedIn }
        guard isSignedIn else {
            throw DriveError(message: "Not signed in")
        }
        
        let token = try await getValidAccessToken()
        
        var request = URLRequest(url: URL(string: "\(driveAPIBase)/files/\(fileId)")!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
            throw DriveError(message: "Delete failed")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func mimeType(for ext: String) -> String {
        let mimeTypes: [String: String] = [
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "webp": "image/webp",
            "svg": "image/svg+xml",
            "pdf": "application/pdf",
            "zip": "application/zip",
            "mp4": "video/mp4",
            "mov": "video/quicktime",
            "mp3": "audio/mpeg",
            "txt": "text/plain",
            "html": "text/html",
            "css": "text/css",
            "js": "application/javascript",
            "json": "application/json"
        ]
        return mimeTypes[ext.lowercased()] ?? "application/octet-stream"
    }
    
    private func parseDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

// MARK: - Response Models

private struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int
    let token_type: String
}

private struct UserInfoResponse: Decodable {
    let email: String
    let name: String?
    let picture: String?
}

private struct DriveFileResponse: Decodable {
    let id: String
    let name: String
    let webViewLink: String?
}

private struct DriveListResponse: Decodable {
    let files: [DriveFileItem]
}

private struct DriveFileItem: Decodable {
    let id: String
    let name: String
    let size: String?
    let createdTime: String?
    let webViewLink: String?
    let thumbnailLink: String?
}

// MARK: - CommonCrypto Import

import CommonCrypto
