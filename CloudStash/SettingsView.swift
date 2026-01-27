//
//  SettingsView.swift
//  CloudStash
//
//  Created by Fayaz Ahmed Aralikatti on 12/01/26.
//

import SwiftUI

struct SettingsView: View {
  var settings = SettingsManager.shared

  @State private var isSigningIn = false
  @State private var errorMessage: String?

  var body: some View {
    Form {
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

#Preview {
  SettingsView()
}
