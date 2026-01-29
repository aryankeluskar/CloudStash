//
//  SettingsView.swift
//  CloudStash
//
//  Created by Fayaz Ahmed Aralikatti on 12/01/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings = SettingsManager.shared

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            // Appearance Section
            Section("Appearance") {
                Picker("Theme", selection: $settings.appTheme) {
                    ForEach(SettingsManager.AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Account Section
            Section {
                if settings.isSignedIn {
                    // Signed in state
                    HStack(spacing: 12) {
                        // User avatar
                        AsyncImage(url: URL(string: settings.userPicture)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color(nsColor: .quaternaryLabelColor))
                                .overlay {
                                    Text(settings.userName.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.userName)
                                .font(.headline)
                            Text(settings.userEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to Google Drive")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button("Sign Out", role: .destructive) {
                        settings.signOut()
                    }
                } else {
                    // Signed out state
                    VStack(spacing: 16) {
                        Image(systemName: "cloud")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("Sign in to Google Drive")
                            .font(.headline)

                        Text(
                            "Your files will be uploaded to your Google Drive and shareable links will be created automatically."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                        Button {
                            signIn()
                        } label: {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "person.badge.key")
                                }
                                Text("Sign in with Google")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSigningIn)
                    }
                    .padding(.vertical, 8)
                }

                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Google Drive Account")
            }

            // About Section
            Section {
                VStack {
                    HStack {
                        AsyncImage(url: URL(string: "https://github.com/aryankeluskar.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color(nsColor: .quaternaryLabelColor))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aryan Keluskar")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Link("@soydotrun", destination: URL(string: "https://x.com/soydotrun")!)
                                .font(.caption)
                        }

                        Spacer()
                    }
                    HStack {
                        AsyncImage(url: URL(string: "https://github.com/fayazara.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color(nsColor: .quaternaryLabelColor))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fayaz Ahmed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Link("@fayazara", destination: URL(string: "https://x.com/fayazara")!)
                                .font(.caption)
                        }

                        Spacer()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 380)
    }

    private func signIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                try await GoogleDriveService.shared.startOAuthFlow()
                // The OAuth flow will complete via URL callback
                // We'll handle that in the app delegate
                await MainActor.run {
                    isSigningIn = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSigningIn = false
                }
            }
        }
    }
}

// MARK: - Inline Settings View (for popover)

struct InlineSettingsView: View {
    @Binding var showSettings: Bool
    @Bindable var settings = SettingsManager.shared

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    showSettings = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()

                // Invisible spacer to balance the back button
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline)
                .hidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("APPEARANCE")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            
                        GlassCard {
                            VStack {
                                Picker("Theme", selection: $settings.appTheme) {
                                    ForEach(SettingsManager.AppTheme.allCases) { theme in
                                        Text(theme.displayName).tag(theme)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(12)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Account section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GOOGLE DRIVE ACCOUNT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            if settings.isSignedIn {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: settings.userPicture)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color(nsColor: .quaternaryLabelColor))
                                            .overlay {
                                                Text(settings.userName.prefix(1).uppercased())
                                                    .font(.headline)
                                                    .foregroundStyle(.secondary)
                                            }
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(settings.userName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(settings.userEmail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                    Text("Connected to Google Drive")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Button("Sign Out", role: .destructive) {
                                    settings.signOut()
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "cloud")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.secondary)

                                    Text("Sign in to Google Drive")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Button {
                                        signIn()
                                    } label: {
                                        HStack {
                                            if isSigningIn {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Image(systemName: "person.badge.key")
                                            }
                                            Text("Sign in with Google")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isSigningIn)
                                }
                            }

                            if let error = errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                    }

                    // About section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ABOUT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 8) {
                            HStack {
                                AsyncImage(url: URL(string: "https://github.com/aryankeluskar.png")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color(nsColor: .quaternaryLabelColor))
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Aryan Keluskar")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Link("@soydotrun", destination: URL(string: "https://x.com/soydotrun")!)
                                        .font(.caption2)
                                }
                                Spacer()
                            }
                            HStack {
                                AsyncImage(url: URL(string: "https://github.com/fayazara.png")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color(nsColor: .quaternaryLabelColor))
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Fayaz Ahmed")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Link("@fayazara", destination: URL(string: "https://x.com/fayazara")!)
                                        .font(.caption2)
                                }
                                Spacer()
                            }
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .frame(width: 320, height: 520)
    }

    private func signIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                try await GoogleDriveService.shared.startOAuthFlow()
                await MainActor.run {
                    isSigningIn = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSigningIn = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

#Preview("Inline Settings") {
    InlineSettingsView(showSettings: .constant(true))
}
