//
//  SettingsManager.swift
//  DropOver
//
//  Created by Fayaz Ahmed Aralikatti on 12/01/26.
//

import Foundation
import Security

@Observable
final class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        // Google OAuth
        static let accessToken = "google_access_token"
        static let refreshToken = "google_refresh_token"
        static let tokenExpiry = "google_token_expiry"
        static let userEmail = "google_user_email"
        static let userName = "google_user_name"
        static let userPicture = "google_user_picture"
        
        // OAuth flow state (temporary)
        static let oauthCodeVerifier = "oauth_code_verifier"
        static let oauthState = "oauth_state"
    }
    
    // MARK: - Stored Properties for Observation
    
    private(set) var _accessToken: String = ""
    private(set) var _refreshToken: String = ""
    private(set) var _tokenExpiry: Date = .distantPast
    private(set) var _userEmail: String = ""
    private(set) var _userName: String = ""
    private(set) var _userPicture: String = ""
    private(set) var _oauthCodeVerifier: String = ""
    private(set) var _oauthState: String = ""
    
    // MARK: - Public Accessors
    
    var accessToken: String {
        get { _accessToken }
        set {
            _accessToken = newValue
            setKeychainItem(key: Keys.accessToken, value: newValue)
        }
    }
    
    var refreshToken: String {
        get { _refreshToken }
        set {
            _refreshToken = newValue
            setKeychainItem(key: Keys.refreshToken, value: newValue)
        }
    }
    
    var tokenExpiry: Date {
        get { _tokenExpiry }
        set {
            _tokenExpiry = newValue
            defaults.set(newValue.timeIntervalSince1970, forKey: Keys.tokenExpiry)
        }
    }
    
    var userEmail: String {
        get { _userEmail }
        set {
            _userEmail = newValue
            defaults.set(newValue, forKey: Keys.userEmail)
        }
    }
    
    var userName: String {
        get { _userName }
        set {
            _userName = newValue
            defaults.set(newValue, forKey: Keys.userName)
        }
    }
    
    var userPicture: String {
        get { _userPicture }
        set {
            _userPicture = newValue
            defaults.set(newValue, forKey: Keys.userPicture)
        }
    }
    
    // OAuth flow state (temporary, not persisted)
    var oauthCodeVerifier: String {
        get { _oauthCodeVerifier }
        set { _oauthCodeVerifier = newValue }
    }
    
    var oauthState: String {
        get { _oauthState }
        set { _oauthState = newValue }
    }
    
    // MARK: - Computed Properties
    
    var isSignedIn: Bool {
        !_accessToken.isEmpty && !_refreshToken.isEmpty
    }
    
    var isConfigured: Bool {
        isSignedIn
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load initial values from storage
        _accessToken = getKeychainItem(key: Keys.accessToken) ?? ""
        _refreshToken = getKeychainItem(key: Keys.refreshToken) ?? ""
        
        let expiryTimestamp = defaults.double(forKey: Keys.tokenExpiry)
        _tokenExpiry = expiryTimestamp > 0 ? Date(timeIntervalSince1970: expiryTimestamp) : .distantPast
        
        _userEmail = defaults.string(forKey: Keys.userEmail) ?? ""
        _userName = defaults.string(forKey: Keys.userName) ?? ""
        _userPicture = defaults.string(forKey: Keys.userPicture) ?? ""
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        accessToken = ""
        refreshToken = ""
        tokenExpiry = .distantPast
        userEmail = ""
        userName = ""
        userPicture = ""
        
        // Clear keychain items
        deleteKeychainItem(key: Keys.accessToken)
        deleteKeychainItem(key: Keys.refreshToken)
        
        // Clear defaults
        defaults.removeObject(forKey: Keys.tokenExpiry)
        defaults.removeObject(forKey: Keys.userEmail)
        defaults.removeObject(forKey: Keys.userName)
        defaults.removeObject(forKey: Keys.userPicture)
    }
    
    // MARK: - Keychain
    
    private func setKeychainItem(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.dropover.app"
        ]
        
        SecItemDelete(query as CFDictionary)
        
        if !value.isEmpty {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            SecItemAdd(newQuery as CFDictionary, nil)
        }
    }
    
    private func getKeychainItem(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.dropover.app",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteKeychainItem(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.dropover.app"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
