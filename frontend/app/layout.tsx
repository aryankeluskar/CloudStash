import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import Link from "next/link";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "CloudStash — Stash Files in the Cloud, Effortlessly",
  description:
    "A macOS menubar app for uploading files to Google Drive with shareable links. Drag, drop, share — all from your menubar.",
  openGraph: {
    title: "CloudStash",
    description:
      "A macOS menubar app for uploading files to Google Drive with shareable links.",
    type: "website",
  },
};

function Footer() {
  return (
    <footer className="relative z-10 border-t border-[var(--surface-border)]">
      <div className="mx-auto max-w-5xl px-6 py-10">
        <div className="flex flex-col items-center gap-6 sm:flex-row sm:justify-between">
          <div className="flex items-center gap-2.5 text-[var(--muted)]">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z" />
              <path d="M12 10v6" />
              <path d="m9 13 3-3 3 3" />
            </svg>
            <span className="text-sm font-medium tracking-tight">
              CloudStash
            </span>
          </div>

          <nav className="flex flex-wrap justify-center gap-x-8 gap-y-2 text-sm text-[var(--muted)]">
            <Link
              href="/privacy"
              className="transition-colors hover:text-[var(--foreground)]"
            >
              Privacy Policy
            </Link>
            <Link
              href="/terms"
              className="transition-colors hover:text-[var(--foreground)]"
            >
              Terms of Service
            </Link>
            <a
              href="https://github.com/aryankeluskar/CloudStash"
              target="_blank"
              rel="noopener noreferrer"
              className="transition-colors hover:text-[var(--foreground)]"
            >
              GitHub
            </a>
          </nav>
        </div>

        <p className="mt-8 text-center text-xs text-[var(--muted-light)]">
          &copy; {new Date().getFullYear()} CloudStash. Open source under the
          MIT License.
        </p>
      </div>
    </footer>
  );
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
        <Footer />
      </body>
    </html>
  );
}
