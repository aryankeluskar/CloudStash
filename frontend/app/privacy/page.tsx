import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy — CloudStash",
  description: "How CloudStash handles your data.",
};

export default function PrivacyPolicy() {
  return (
    <main className="relative mx-auto max-w-2xl px-6 pt-20 pb-24">
      <Link
        href="/"
        className="mb-10 inline-flex items-center gap-1.5 text-sm text-[var(--muted)] transition-colors hover:text-[var(--foreground)]"
      >
        <svg
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m15 18-6-6 6-6" />
        </svg>
        Back to home
      </Link>

      <div className="prose-legal">
        <h1>Privacy Policy</h1>
        <p className="!text-[var(--muted-light)]">Last updated: February 5, 2026</p>

        <h2>Overview</h2>
        <p>
          CloudStash is a macOS menubar application that uploads files to your
          Google Drive and generates shareable links. This policy explains what
          data CloudStash accesses, how it is used, and how it is stored.
        </p>

        <h2>Data We Access</h2>
        <p>When you sign in with Google, CloudStash requests access to:</p>
        <ul>
          <li>
            <strong>Your email address and profile name</strong> — displayed
            within the app to identify your account.
          </li>
          <li>
            <strong>Google Drive file access</strong> (
            <code>drive.file</code> scope) — limited to files created or opened
            by CloudStash. The app cannot access any other files in your Google
            Drive.
          </li>
        </ul>

        <h2>Files You Upload</h2>
        <p>When you upload a file, CloudStash:</p>
        <ul>
          <li>Copies the file to a local staging area on your Mac.</li>
          <li>Uploads the file to your Google Drive.</li>
          <li>
            Sets the sharing permission to &ldquo;anyone with the link can
            view&rdquo; so you receive a shareable URL.
          </li>
        </ul>
        <p>
          CloudStash does <strong>not</strong> read, scan, or analyze the
          contents of your files.
        </p>

        <h2>Data Storage</h2>
        <p>
          All data is stored <strong>locally on your Mac</strong>:
        </p>
        <ul>
          <li>
            <strong>OAuth tokens</strong> (access and refresh) are stored in the
            macOS Keychain.
          </li>
          <li>
            <strong>User preferences</strong> (e.g. theme) are stored in
            UserDefaults.
          </li>
          <li>
            <strong>Upload history</strong> (file names, Drive IDs, URLs,
            timestamps) is stored in a local SwiftData database.
          </li>
          <li>
            <strong>Staged files</strong> are stored in{" "}
            <code>~/Library/Application Support/CloudStash/Stash/</code> until
            uploaded or removed.
          </li>
        </ul>
        <p>
          CloudStash does <strong>not</strong> operate any servers. No data is
          sent anywhere other than directly to Google&apos;s APIs.
        </p>

        <h2>Third-Party Services</h2>
        <p>CloudStash communicates only with:</p>
        <ul>
          <li>
            <strong>Google OAuth 2.0</strong> — for authentication.
          </li>
          <li>
            <strong>Google Drive API</strong> — for uploading, listing, and
            deleting files.
          </li>
          <li>
            <strong>Google UserInfo API</strong> — for retrieving your name and
            email.
          </li>
        </ul>
        <p>
          No analytics, tracking, advertising, or crash reporting services are
          used.
        </p>

        <h2>Data Sharing</h2>
        <p>
          CloudStash does <strong>not</strong> sell, share, or transfer your data
          to any third parties. The only external communication is between your
          Mac and Google&apos;s APIs, initiated by your actions.
        </p>

        <h2>Data Retention</h2>
        <ul>
          <li>
            Upload history and staged files remain on your Mac until you delete
            them within the app or uninstall it.
          </li>
          <li>
            OAuth tokens persist in your Keychain until you sign out or revoke
            access from your Google Account settings.
          </li>
          <li>
            Files uploaded to Google Drive remain there until you delete them.
          </li>
        </ul>

        <h2>Your Control</h2>
        <p>You can at any time:</p>
        <ul>
          <li>
            <strong>Sign out</strong> from within CloudStash, which removes
            stored tokens.
          </li>
          <li>
            <strong>Delete uploaded files</strong> from within CloudStash or
            directly in Google Drive.
          </li>
          <li>
            <strong>Revoke access</strong> by visiting{" "}
            <a
              href="https://myaccount.google.com/permissions"
              target="_blank"
              rel="noopener noreferrer"
            >
              Google Account Permissions
            </a>{" "}
            and removing CloudStash.
          </li>
          <li>
            <strong>Uninstall the app</strong> to remove all locally stored
            data.
          </li>
        </ul>

        <h2>Children&apos;s Privacy</h2>
        <p>
          CloudStash is not directed at children under 13 and does not knowingly
          collect data from children.
        </p>

        <h2>Changes to This Policy</h2>
        <p>
          If this policy is updated, the changes will be reflected on this page
          with an updated date. Continued use of CloudStash after changes
          constitutes acceptance.
        </p>

        <h2>Contact</h2>
        <p>
          If you have questions about this privacy policy, please{" "}
          <a
            href="https://github.com/aryankeluskar/CloudStash/issues"
            target="_blank"
            rel="noopener noreferrer"
          >
            open an issue
          </a>{" "}
          on the CloudStash GitHub repository.
        </p>
      </div>
    </main>
  );
}
