# OpenUtau + Logic Pro (Apple Silicon)

This archive contains the unmodified official OpenUtau `0.1.570.9-alpha` app, the
OpenUtau Bridge Audio Unit, and a native relay used by Logic Pro's AU host. It does
not contain singers, projects, or user settings.

## Install

On an Apple Silicon Mac, extract the ZIP and run in Terminal:

```sh
cd /path/to/OpenUtau-Logic-AU-0.1.570.9-alpha-macos-arm64
sh install.sh
```

The installer checks SHA-256 hashes before changing files. It installs into the
current user's `~/Applications` and `~/Library`, backs up any files it replaces in
`~/Applications/OpenUtau Bridge Backups`, sets OpenUtau's update channel to Alpha,
and starts the relay at login. Run the installer while logged into the account that
will use Logic Pro. Logic Pro must already be installed.

If an older `/Applications/OpenUtau.app` also exists, launch the newly installed
`~/Applications/OpenUtau.app` explicitly. Do not run both copies at once.

In Logic, add **OpenUtau Bridge** as a stereo AU instrument. Open a saved USTX in
OpenUtau, then choose **Tools → DAW Integration → Refresh → OpenUtau Bridge Relay →
Connect**. Set matching tempos in Logic and OpenUtau. Reconnect after reopening a
Logic project. See `LOGIC_SETUP.md` in the source repository for details.

## Signing and trust

The AU and relay have ad hoc signatures. This archive is **not Developer ID signed
or notarized** because no Developer ID signing identity is available. The installer
removes the `com.apple.quarantine` attribute only from the three verified files it
installs, as required for these unsigned components to run on another Mac. It does
not change the Mac's global Gatekeeper settings. Review the package and its
`SHA256SUMS` before running the installer. If your Mac is managed by an organization,
its policy may still prevent the AU from loading.

The AU and relay were tested on the build Mac with Logic Pro. The archive's installer
was tested in an isolated home directory. A second Mac test is still required to
confirm your specific macOS and Logic configuration.

## Sources and licenses

- OpenUtau: <https://github.com/openutau/OpenUtau/releases/tag/0.1.570.9-alpha>
  (MIT; `OPENUTAU_LICENSE.txt`).
- OpenUtau Bridge and this distribution: source repository linked from the GitHub
  release (MPL-2.0; `BRIDGE_LICENSE.txt`).

The bundled OpenUtau executable matches the official arm64 DMG whose SHA-256 is
`27a5d07a889a9b29a12c5ec657ba3cb607dc67975a47e04d5c1c87b0b81683f9`.
