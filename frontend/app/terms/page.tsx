import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms of Service — CloudStash",
  description: "Terms and conditions for using CloudStash.",
};

export default function TermsOfService() {
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
        <h1>Terms of Service</h1>
        <p className="!text-[var(--muted-light)]">Last updated: February 5, 2026</p>

        <h2>Acceptance of Terms</h2>
        <p>
          By downloading, installing, or using CloudStash, you agree to these
          Terms of Service. If you do not agree, do not use the application.
        </p>

        <h2>Description of Service</h2>
        <p>
          CloudStash is a free, open-source macOS menubar application that lets
          you upload files to your personal Google Drive account and generate
          shareable links. The app runs entirely on your Mac and communicates
          directly with Google&apos;s APIs.
        </p>

        <h2>Requirements</h2>
        <ul>
          <li>A Mac running macOS 14.0 (Sonoma) or later.</li>
          <li>A Google account.</li>
          <li>An internet connection.</li>
        </ul>

        <h2>Your Responsibilities</h2>
        <ul>
          <li>
            You are responsible for the files you upload and share through
            CloudStash.
          </li>
          <li>
            You must comply with{" "}
            <a
              href="https://policies.google.com/terms"
              target="_blank"
              rel="noopener noreferrer"
            >
              Google&apos;s Terms of Service
            </a>{" "}
            and{" "}
            <a
              href="https://www.google.com/drive/terms-of-service/"
              target="_blank"
              rel="noopener noreferrer"
            >
              Google Drive&apos;s Terms
            </a>{" "}
            when using CloudStash.
          </li>
          <li>
            You must not use CloudStash to upload, store, or share content that
            is illegal, harmful, or violates the rights of others.
          </li>
          <li>
            You are responsible for maintaining the security of your Google
            account.
          </li>
        </ul>

        <h2>Intellectual Property</h2>
        <p>
          CloudStash is open-source software released under the MIT License.
          Refer to the{" "}
          <a
            href="https://github.com/aryankeluskar/CloudStash/blob/main/LICENSE"
            target="_blank"
            rel="noopener noreferrer"
          >
            LICENSE
          </a>{" "}
          file in the project repository for details on usage, modification, and
          distribution rights.
        </p>

        <h2>Disclaimer of Warranties</h2>
        <p>
          CloudStash is provided <strong>&ldquo;as is&rdquo;</strong> and{" "}
          <strong>&ldquo;as available&rdquo;</strong> without warranties of any
          kind, either express or implied, including but not limited to:
        </p>
        <ul>
          <li>Merchantability or fitness for a particular purpose.</li>
          <li>Uninterrupted or error-free operation.</li>
          <li>
            Compatibility with future versions of macOS or Google&apos;s APIs.
          </li>
        </ul>

        <h2>Limitation of Liability</h2>
        <p>
          To the maximum extent permitted by law, the developers of CloudStash
          shall not be liable for any indirect, incidental, special,
          consequential, or punitive damages, including but not limited to:
        </p>
        <ul>
          <li>Loss of data or files.</li>
          <li>Unauthorized access to your Google account.</li>
          <li>Interruption of service due to changes in Google&apos;s APIs.</li>
          <li>
            Any damages arising from your use or inability to use the
            application.
          </li>
        </ul>

        <h2>Google API Services</h2>
        <p>
          CloudStash uses Google API Services. Your use of Google&apos;s
          services through CloudStash is also subject to{" "}
          <a
            href="https://developers.google.com/terms/api-services-user-data-policy"
            target="_blank"
            rel="noopener noreferrer"
          >
            Google&apos;s API Services User Data Policy
          </a>
          .
        </p>

        <h2>Modifications</h2>
        <p>
          These terms may be updated from time to time. Changes will be
          reflected on this page with an updated date. Continued use of
          CloudStash after changes constitutes acceptance.
        </p>

        <h2>Termination</h2>
        <p>
          You may stop using CloudStash at any time by uninstalling the
          application and revoking access from your{" "}
          <a
            href="https://myaccount.google.com/permissions"
            target="_blank"
            rel="noopener noreferrer"
          >
            Google Account Permissions
          </a>
          .
        </p>

        <h2>Contact</h2>
        <p>
          If you have questions about these terms, please{" "}
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
