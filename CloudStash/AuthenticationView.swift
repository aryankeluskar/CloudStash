//
//  AuthenticationView.swift
//  CloudStash
//
//  Created for CloudStash App by Aryan Keluskar
//

import SwiftUI

/// A dedicated view for Google Drive sign-in
/// This view is shown when the user is not authenticated
struct AuthenticationView: View {
    @State private var isSigningIn = false
    @State private var showOpeningBrowser = false
    @State private var errorMessage: String?
    @State private var isHovering = false
    @State private var signInTask: Task<Void, Never>?
    @State private var appeared = false

    // Timeout for OAuth flow (3 minutes)
    private let oauthTimeout: TimeInterval = 180

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main content
            VStack(spacing: 36) {
                    // App icon and branding
                    VStack(spacing: 16) {
                        // CloudStash icon
                        Image("CloudStashIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 20, y: 4)
                            .scaleEffect(appeared ? 1.0 : 0.8)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)

                        VStack(spacing: 6) {
                            Text("CloudStash")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Your files, instantly shareable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)
                    }

                    // Feature pills
                    VStack(spacing: 10) {
                        GlassCard {
                            FeatureRow(
                                icon: "arrow.up.circle.fill",
                                gradient: LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                text: "Drop files to upload instantly"
                            )
                        }
                        
                        GlassCard {
                            FeatureRow(
                                icon: "link.circle.fill",
                                gradient: LinearGradient(colors: [.green, Color(red: 0.2, green: 0.8, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                text: "Get shareable links automatically"
                            )
                        }
                        
                        GlassCard {
                            FeatureRow(
                                icon: "lock.shield.fill",
                                gradient: LinearGradient(colors: [.indigo, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                text: "Stored securely in your Google Drive"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                    // Sign in button
                    VStack(spacing: 14) {
                        Button {
                            signIn()
                        } label: {
                            HStack(spacing: 10) {
                                if showOpeningBrowser {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "person.badge.key.fill")
                                        .font(.system(size: 15))
                                }
                                Text(showOpeningBrowser ? "Opening browser..." : "Sign in with Google")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(showOpeningBrowser)
                        .scaleEffect(isHovering && !showOpeningBrowser ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isHovering)
                        .onHover { isHovering = $0 }

                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)
                }

                Spacer()

            // Footer
            Text("Your files never leave your control")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true
        }
    }

    private func signIn() {
        isSigningIn = true
        showOpeningBrowser = true
        errorMessage = nil

        // Cancel any previous sign-in task
        signInTask?.cancel()

        signInTask = Task {
            do {
                try await GoogleDriveService.shared.startOAuthFlow()

                // Show "Opening browser..." for 2 seconds, then revert to clickable button
                try await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    showOpeningBrowser = false
                }

                // Continue waiting for OAuth callback with timeout
                try await Task.sleep(for: .seconds(oauthTimeout - 2))

                // If we reach here, OAuth timed out (callback never came)
                await MainActor.run {
                    if isSigningIn {
                        errorMessage = "Sign-in timed out. Please try again."
                        isSigningIn = false
                    }
                }
            } catch is CancellationError {
                // Task was cancelled (user signed in successfully or started new sign-in)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSigningIn = false
                    showOpeningBrowser = false
                }
            }
        }
    }

    /// Called when OAuth completes successfully (from app delegate)
    func onSignInComplete() {
        signInTask?.cancel()
        isSigningIn = false
        showOpeningBrowser = false
        errorMessage = nil
    }
}

struct FeatureRow: View {
    let icon: String
    let gradient: LinearGradient
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(gradient)
                .frame(width: 24)

            Text(text)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.primary.opacity(0.85))

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }
}

#Preview("Sign In") {
    AuthenticationView()
        .frame(width: 320, height: 520)
}
