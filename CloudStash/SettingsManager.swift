//
//  SettingsManager.swift
//  CloudStash
//
//  Created by Fayaz Ahmed Aralikatti on 12/01/26.
//

import Foundation
import Security

// MARK: - App-wide Notification Names

extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}

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

        // OAuth flow state (persisted temporarily during auth flow)
        static let oauthCodeVerifier = "oauth_code_verifier"
        static let oauthState = "oauth_state"
        
        // App Settings
        static let appTheme = "app_theme"
    }
    
    // MARK: - App Theme
    
    enum AppTheme: String, CaseIterable, Identifiable {
        case light
        case dark
        case system
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
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
    private(set) var _appTheme: AppTheme = .light
    
    // MARK: - Public Accessors
    
    var appTheme: AppTheme {
        get { _appTheme }
        set {
            _appTheme = newValue
            defaults.set(newValue.rawValue, forKey: Keys.appTheme)
        }
    }
    
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
    
    // OAuth flow state (persisted temporarily during auth flow)
    // These MUST be persisted because the app may be relaunched by the OAuth redirect
    var oauthCodeVerifier: String {
        get { _oauthCodeVerifier }
        set {
            _oauthCodeVerifier = newValue
            if newValue.isEmpty {
                defaults.removeObject(forKey: Keys.oauthCodeVerifier)
            } else {
                defaults.set(newValue, forKey: Keys.oauthCodeVerifier)
            }
        }
    }

    var oauthState: String {
        get { _oauthState }
        set {
            _oauthState = newValue
            if newValue.isEmpty {
                defaults.removeObject(forKey: Keys.oauthState)
            } else {
                defaults.set(newValue, forKey: Keys.oauthState)
            }
        }
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

        // Load OAuth flow state (needed if app was relaunched by OAuth redirect)
        _oauthCodeVerifier = defaults.string(forKey: Keys.oauthCodeVerifier) ?? ""
        _oauthState = defaults.string(forKey: Keys.oauthState) ?? ""
        
        // Load App Theme (default to light per redesign)
        if let savedTheme = defaults.string(forKey: Keys.appTheme),
           let theme = AppTheme(rawValue: savedTheme) {
            _appTheme = theme
        } else {
            _appTheme = .light
        }
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

        // Notify UI of auth state change
        NotificationCenter.default.post(name: .authStateDidChange, object: nil)
    }

    /// Called after successful sign-in to notify UI
    func notifySignInComplete() {
        NotificationCenter.default.post(name: .authStateDidChange, object: nil)
    }
    
    // MARK: - Keychain
    
    private func setKeychainItem(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.CloudStash.app"
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
            kSecAttrService as String: "com.CloudStash.app",
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
            kSecAttrService as String: "com.CloudStash.app"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
