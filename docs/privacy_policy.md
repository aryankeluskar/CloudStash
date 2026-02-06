# Privacy Policy

**CloudStash**
**Last Updated:** February 5, 2026

## Overview

CloudStash is a macOS menubar application that allows you to upload files to your Google Drive and generate shareable links. Your privacy is important to us, and this policy explains what data CloudStash accesses, how it is used, and how it is stored.

## Data We Access

### Google Account Information

When you sign in with Google, CloudStash requests access to:

- **Your email address and profile name** — used to display your account info within the app.
- **Google Drive file access (drive.file scope)** — limited to files created or opened by CloudStash. The app cannot access any other files in your Google Drive.

### Files You Upload

When you choose to upload a file, CloudStash:

- Copies the file to a local staging area on your Mac.
- Uploads the file to your Google Drive.
- Sets the uploaded file's sharing permission to "anyone with the link can view" so you get a shareable URL.

CloudStash does **not** read, scan, or analyze the contents of your files.

## Data Storage

All data is stored **locally on your Mac**:

- **OAuth tokens** (access and refresh tokens) are stored in the macOS Keychain.
- **User preferences** (theme setting) are stored in UserDefaults.
- **Upload history** (file names, Drive file IDs, URLs, timestamps) is stored in a local SwiftData database.
- **Staged files** are stored in `~/Library/Application Support/CloudStash/Stash/` until uploaded or removed.

CloudStash does **not** operate any servers. No data is sent anywhere other than directly to Google's APIs.

## Third-Party Services

CloudStash communicates only with:

- **Google OAuth 2.0** — for authentication.
- **Google Drive API** — for uploading, listing, and deleting files.
- **Google UserInfo API** — for retrieving your name and email.

No analytics, tracking, advertising, or crash reporting services are used.

## Data Sharing

CloudStash does **not** sell, share, or transfer your data to any third parties. The only external communication is between your Mac and Google's APIs, initiated by your actions.

## Data Retention

- Upload history and staged files remain on your Mac until you delete them within the app or uninstall it.
- OAuth tokens persist in your Keychain until you sign out of CloudStash or revoke access from your Google Account settings.
- Files uploaded to Google Drive remain in your Drive until you delete them.

## Your Control

You can at any time:

- **Sign out** from within CloudStash, which removes stored tokens.
- **Delete uploaded files** from within CloudStash or directly in Google Drive.
- **Revoke access** by visiting [Google Account Permissions](https://myaccount.google.com/permissions) and removing CloudStash.
- **Uninstall the app** to remove all locally stored data.

## Children's Privacy

CloudStash is not directed at children under 13 and does not knowingly collect data from children.

## Changes to This Policy

If this policy is updated, the changes will be reflected in this document with an updated date. Continued use of CloudStash after changes constitutes acceptance.

## Contact

If you have questions about this privacy policy, please open an issue on the [CloudStash GitHub repository](https://github.com/aryankeluskar/CloudStash/issues).
