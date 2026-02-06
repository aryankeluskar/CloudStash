export default function Home() {
  return (
    <>
      {/* ======= BACKGROUND ORBS ======= */}
      <div
        aria-hidden
        className="pointer-events-none fixed inset-0 -z-10 overflow-hidden"
      >
        {/* Pink */}
        <div
          className="absolute -left-32 -top-24 h-[480px] w-[480px] rounded-full opacity-30 blur-[100px] dark:opacity-15"
          style={{
            background: "var(--orb-pink)",
            animation: "float-1 18s ease-in-out infinite",
          }}
        />
        {/* Purple */}
        <div
          className="absolute right-[-10%] top-[20%] h-[420px] w-[420px] rounded-full opacity-25 blur-[100px] dark:opacity-10"
          style={{
            background: "var(--orb-purple)",
            animation: "float-2 22s ease-in-out infinite",
          }}
        />
        {/* Blue */}
        <div
          className="absolute bottom-[30%] left-[15%] h-[380px] w-[380px] rounded-full opacity-25 blur-[90px] dark:opacity-10"
          style={{
            background: "var(--orb-blue)",
            animation: "float-3 20s ease-in-out infinite",
          }}
        />
        {/* Mint */}
        <div
          className="absolute bottom-[-5%] right-[20%] h-[350px] w-[350px] rounded-full opacity-20 blur-[100px] dark:opacity-10"
          style={{
            background: "var(--orb-mint)",
            animation: "float-4 24s ease-in-out infinite",
          }}
        />
      </div>

      {/* ======= HERO ======= */}
      <section className="relative flex min-h-[92vh] flex-col items-center justify-center px-6 pt-20 pb-24 text-center">
        {/* Badge */}
        <div className="animate-fade-in-up mb-6 inline-flex items-center gap-2 rounded-full glass px-4 py-1.5 text-xs font-medium tracking-wide text-[var(--muted)]">
          <span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-400" />
          Free &amp; Open Source for macOS
        </div>

        {/* Headline */}
        <h1 className="animate-fade-in-up delay-100 max-w-2xl text-5xl font-bold leading-[1.1] tracking-[-0.035em] sm:text-6xl md:text-7xl">
          Stash Files in the Cloud,{" "}
          <span className="bg-gradient-to-r from-blue-500 via-blue-400 to-sky-400 bg-clip-text text-transparent">
            Effortlessly
          </span>
        </h1>

        {/* Subheadline */}
        <p className="animate-fade-in-up delay-200 mx-auto mt-6 max-w-lg text-lg leading-relaxed text-[var(--muted)] sm:text-xl">
          A tiny macOS menubar app that uploads files to Google Drive and copies
          shareable links to your clipboard. Drag, drop, done.
        </p>

        {/* CTAs */}
        <div className="animate-fade-in-up delay-300 mt-10 flex flex-wrap justify-center gap-4">
          <a
            href="https://github.com/aryankeluskar/CloudStash/releases"
            target="_blank"
            rel="noopener noreferrer"
            className="group relative inline-flex items-center gap-2.5 rounded-full bg-[var(--accent)] px-7 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/20 transition-all hover:bg-[var(--accent-hover)] hover:shadow-blue-500/30 hover:-translate-y-0.5 active:translate-y-0"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" x2="12" y1="15" y2="3" />
            </svg>
            Download for macOS
          </a>
          <a
            href="https://github.com/aryankeluskar/CloudStash"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2.5 rounded-full glass px-7 py-3 text-sm font-semibold text-[var(--foreground)] transition-all hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="currentColor"
            >
              <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12Z" />
            </svg>
            View on GitHub
          </a>
        </div>

        {/* macOS requirement */}
        <p className="animate-fade-in delay-400 mt-6 text-xs text-[var(--muted-light)]">
          Requires macOS 14.0 Sonoma or later
        </p>
      </section>

      {/* ======= FEATURES ======= */}
      <section className="relative px-6 py-24">
        <div className="mx-auto max-w-5xl">
          <div className="mb-16 text-center">
            <h2 className="animate-fade-in-up text-3xl font-bold tracking-[-0.03em] sm:text-4xl">
              Everything you need,
              <br />
              nothing you don&apos;t
            </h2>
            <p className="animate-fade-in-up delay-100 mx-auto mt-4 max-w-md text-[var(--muted)]">
              CloudStash lives in your menubar and stays out of the way until
              you need it.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {[
              {
                icon: (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.75"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" />
                    <path d="M14 2v4a2 2 0 0 0 2 2h4" />
                    <path d="M12 12v6" />
                    <path d="m15 15-3-3-3 3" />
                  </svg>
                ),
                title: "Drag & Drop",
                desc: "Drop files onto the menubar popover or the floating shelf. No file pickers needed.",
              },
              {
                icon: (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.75"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M12 16v5" />
                    <path d="M16 14v7" />
                    <path d="M20 10v11" />
                    <path d="M4 20V10a8 8 0 0 1 16 0" />
                    <circle cx="12" cy="12" r="2" />
                  </svg>
                ),
                title: "Google Drive",
                desc: "Files go straight to your personal Drive. Sign in once, upload forever.",
              },
              {
                icon: (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.75"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <rect width="14" height="8" x="5" y="2" rx="2" />
                    <rect width="20" height="8" x="2" y="14" rx="2" />
                    <path d="M6 18h.01" />
                    <path d="M10 18h.01" />
                  </svg>
                ),
                title: "Floating Shelf",
                desc: "A mini window appears when dragging files anywhere on macOS. Stage files before uploading.",
              },
              {
                icon: (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.75"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <rect width="8" height="4" x="8" y="2" rx="1" ry="1" />
                    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
                    <path d="m9 14 2 2 4-4" />
                  </svg>
                ),
                title: "Auto-Copy Links",
                desc: "Shareable URLs are copied to your clipboard the instant an upload finishes.",
              },
              {
                icon: (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.75"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                ),
                title: "Quick Look",
                desc: "Double-click any file to preview it with macOS Quick Look. No need to open apps.",
              },
              {
                icon: (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.75"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                    <polyline points="7 10 12 15 17 10" />
                    <line x1="12" x2="12" y1="15" y2="3" />
                  </svg>
                ),
                title: "Download Anytime",
                desc: "Grab files back from Drive directly within CloudStash. One click, saved to your Mac.",
              },
            ].map((f, i) => (
              <div
                key={f.title}
                className="glass rounded-2xl p-6 transition-all hover:-translate-y-0.5 hover:shadow-lg"
                style={{
                  animationDelay: `${i * 80}ms`,
                }}
              >
                <div className="mb-4 inline-flex rounded-xl bg-[var(--accent)]/10 p-2.5 text-[var(--accent)]">
                  {f.icon}
                </div>
                <h3 className="mb-1.5 text-[0.95rem] font-semibold tracking-tight">
                  {f.title}
                </h3>
                <p className="text-sm leading-relaxed text-[var(--muted)]">
                  {f.desc}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ======= HOW IT WORKS ======= */}
      <section className="relative px-6 py-24">
        <div className="mx-auto max-w-3xl">
          <div className="mb-16 text-center">
            <h2 className="text-3xl font-bold tracking-[-0.03em] sm:text-4xl">
              Three steps. That&apos;s it.
            </h2>
          </div>

          <div className="flex flex-col gap-6">
            {[
              {
                step: "01",
                title: "Sign in with Google",
                desc: "Authorize CloudStash once. Your tokens are stored securely in the macOS Keychain — never on a server.",
              },
              {
                step: "02",
                title: "Drop your files",
                desc: "Drag files onto the menubar popover or the floating shelf. Stage them or upload immediately.",
              },
              {
                step: "03",
                title: "Share the link",
                desc: "Each upload generates a public Google Drive link, copied straight to your clipboard. Paste and go.",
              },
            ].map((s) => (
              <div
                key={s.step}
                className="glass-subtle flex items-start gap-6 rounded-2xl p-6 transition-all hover:-translate-y-0.5"
              >
                <span className="shrink-0 bg-gradient-to-br from-blue-500 to-sky-400 bg-clip-text text-3xl font-extrabold tracking-tighter text-transparent">
                  {s.step}
                </span>
                <div>
                  <h3 className="mb-1 text-[0.95rem] font-semibold tracking-tight">
                    {s.title}
                  </h3>
                  <p className="text-sm leading-relaxed text-[var(--muted)]">
                    {s.desc}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ======= CTA BANNER ======= */}
      <section className="relative px-6 py-24">
        <div className="mx-auto max-w-3xl overflow-hidden rounded-3xl glass p-12 text-center sm:p-16">
          <h2 className="text-3xl font-bold tracking-[-0.03em] sm:text-4xl">
            Ready to simplify file sharing?
          </h2>
          <p className="mx-auto mt-4 max-w-md text-[var(--muted)]">
            Download CloudStash and start sharing files from your menubar in
            under a minute.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-4">
            <a
              href="https://github.com/aryankeluskar/CloudStash/releases"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2.5 rounded-full bg-[var(--accent)] px-7 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/20 transition-all hover:bg-[var(--accent-hover)] hover:shadow-blue-500/30 hover:-translate-y-0.5 active:translate-y-0"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" x2="12" y1="15" y2="3" />
              </svg>
              Download for macOS
            </a>
          </div>
          <p className="mt-4 text-xs text-[var(--muted-light)]">
            macOS 14.0+ &middot; Free &amp; open source
          </p>
        </div>
      </section>
    </>
  );
}
