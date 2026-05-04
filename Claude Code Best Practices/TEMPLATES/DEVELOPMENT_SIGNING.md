# Development Signing — Reference Implementation

The procedure for replacing Xcode's automatic Personal Team signing with a long-lived self-signed certificate, so local development builds stop breaking when Apple rotates Personal Team issuing infrastructure or the certificate's one-year window elapses.

This is set up immediately after creating a new Xcode project, before any meaningful work begins — Personal Team's expiry/revocation churn is a defense you want in place from day one. The implementation is battle-tested: it was refined from a real-world setup, and the bugs found during that setup are captured in "Known Gotchas" below.

---

## Status of This Reference

This template currently describes the **self-signed certificate** approach. When the project owner has a paid Apple Developer Program membership and a Developer ID Application certificate, the procedure here will be revised — the principle in `02_DEVELOPMENT_PHILOSOPHY.md` ("Development Signing Doesn't Expire") stays the same, but the implementation can use the Apple-issued cert directly. Until that point, self-signing is the right tool for development; it is *never* the right tool for distribution (which requires Developer ID + notarization regardless).

---

## What You Are Setting Up

A locally-issued, long-lived (10-year) self-signed code-signing certificate that becomes the manual signing identity for every target that loads into the host app's process — app target, test bundle, frameworks. Plus the Build Settings changes that pin Xcode to use it. Plus a separate Debug-only entitlements file that disables library validation so XCTest bundles and Xcode 16's debug-dylib feature still work.

The pieces:

1. A self-signed certificate created in Keychain Access (one-time, per-machine setup)
2. Per-target Build Settings: `CODE_SIGN_STYLE = Manual`, `CODE_SIGN_IDENTITY = "<CertName>"`, `DEVELOPMENT_TEAM = ""` — for both Debug and Release
3. A Debug-only entitlements file with `com.apple.security.cs.disable-library-validation` set to `true`
4. A release-checklist item in the project's overall directive: "switch signing back to Developer ID before archiving"

---

## Decisions Baked Into This Approach

For when future-you wonders why something was done this way.

### Why self-signed instead of waiting for the paid Developer Program

Two reasons. First, the Developer Program membership can take days or weeks to activate, and during that interim the developer is stuck on Personal Team's expiring/revoking churn. Second, even after the paid membership is active, conflating "the certificate that signs distribution builds" with "the certificate that signs local builds" is a category error — the distribution cert is precious (loss = re-issuance through Apple Connect) while the development cert is disposable (loss = recreate in 30 seconds). Keep them separate.

### Why a 10-year validity

By that point you will either have a Developer ID Application cert (irrelevant) or you can regenerate the dev cert trivially. The 10-year reach is deliberate — pick a number that is longer than you expect to care about so the cert is not on your maintenance radar.

### Why the same cert for app target AND test target AND frameworks

Hardened Runtime enables library validation, which enforces that all loaded code must be signed by the same team identifier as the host (or by Apple). When unit tests run, the test bundle is loaded into the host app's process; if the test bundle is signed with a different cert, library validation fails the load. So both targets get the same cert. Same applies to any framework target the app loads.

### Why Manual signing style

`CODE_SIGN_STYLE = Automatic` looks at `DEVELOPMENT_TEAM` and tries to provision a matching Apple-issued cert. With a self-signed cert (no team), Automatic mode either fails or silently falls back to Personal Team. Manual signing pins the identity explicitly: `CODE_SIGN_IDENTITY = "<CertName>"`, and Xcode uses exactly that.

### Why a separate Debug-only entitlements file

The library-validation exception (`com.apple.security.cs.disable-library-validation`) is required for XCTest to work and for Xcode 16's debug-dylib pattern to launch. But it is a security-sensitive Hardened Runtime relaxation that must NOT ship in Release builds. Splitting entitlements into Debug and Release files keeps the relaxation narrowly scoped to Debug — Release retains strict library validation. Document the Debug-only relaxation in the project's overall directive (or `SECURITY.md` if the project has one) so it is visible at code review and removable at the M-release where signing switches to Developer ID.

---

## Phase 0 — Survey Before Editing

Don't edit anything until you know:

1. **The certificate exists and is usable.** Run:

   ```
   security find-identity -v -p codesigning
   ```

   The cert should appear in the output. If it doesn't, follow "Creating the Certificate" below before continuing.

2. **The certificate has the right attributes.** Run:

   ```
   security find-certificate -c "<CertName>" -p | openssl x509 -noout -subject -issuer -dates -ext keyUsage,extendedKeyUsage,basicConstraints
   ```

   Verify:

   - `subject` and `issuer` are identical (i.e., self-signed)
   - `notAfter` is several years out
   - `Basic Constraints: CA:FALSE` (it is a leaf code-signing cert, not a CA)
   - `Key Usage: Digital Signature` (required for code signing)
   - `Extended Key Usage: Code Signing` (required — without this, `security find-identity -p codesigning` will not see the cert)

3. **Current signing config in `.pbxproj`.** Search for `CODE_SIGN_STYLE`, `CODE_SIGN_IDENTITY`, `DEVELOPMENT_TEAM`, `PROVISIONING_PROFILE`. Note current values for each target × configuration so the rollback is unambiguous if needed.

4. **Targets that need switching.** Every target whose product runs in the same process as the host app — test bundles, frameworks the host loads at runtime — must use the same signing identity due to library validation.

Summarize findings, propose changes, **wait for confirmation before editing.**

---

## Phase 1 — Creating the Certificate

Done once per machine via Keychain Access. Skip if `security find-identity -v -p codesigning` already shows your cert.

1. Open **Keychain Access** (in `/Applications/Utilities/`).
2. Menu: **Keychain Access → Certificate Assistant → Create a Certificate…**
3. **Name:** the cert name you will use in Xcode (e.g., `Lab Code Cert`). Pick something distinctive so it does not collide with Apple-issued certs in fuzzy searches.
4. **Identity Type:** Self Signed Root.
5. **Certificate Type:** Code Signing.
6. **Check "Let me override defaults"** — required to set the validity period.
7. **Continue.** Pick a high serial number; it does not matter much for self-signed.
8. **Validity Period:** `3650` days (10 years). The default is 365 days; that is the same one-year window you are trying to escape, so override it.
9. **Continue through the rest with defaults**: Email Address blank or your address; RSA 2048; Digital Signature (must be checked); Extended Key Usage including Code Signing.
10. **Save in the login keychain.**

Verify with `security find-identity -v -p codesigning` — the new cert should appear in the list.

---

## Phase 2 — Manual Xcode Steps for the Human

These steps require Xcode's UI. **Do NOT edit `.pbxproj` programmatically** — risk to project integrity is not worth it.

For **each target that loads into the host app's process** (the app target and any test/framework target):

### Step 1 — Switch Code Signing Style to Manual

1. Project Navigator → top item → TARGETS → target name.
2. **Build Settings** tab → filter buttons set to **All** + **Combined**.
3. Search box: `code signing style`.
4. Find **Code Signing Style** under **Signing**. Click the value (`Automatic`) → set to **Manual**. Set both Debug and Release.

### Step 2 — Set Code Signing Identity

1. Same target → search box: `code signing identity`.
2. Find **Code Signing Identity**. Click the value, type the certificate's exact name (e.g., `Lab Code Cert`) — Xcode will autocomplete from your keychain. Set both Debug and Release.

### Step 3 — Clear Development Team

1. Same target → search box: `development team`.
2. Click the value, choose **None** (or delete the existing team identifier). Set both Debug and Release.

### Step 4 — Repeat for each remaining target

The test target and any framework targets the host loads need the same three changes.

### Step 5 — Add the Debug-only entitlements file

1. Duplicate the production entitlements file. Name the copy `<App>.Debug.entitlements`.
2. Open the new file and add (or set, if it already exists) the key `com.apple.security.cs.disable-library-validation` to `true`.
3. In Xcode → app target → **Build Settings** → search `Code Signing Entitlements`.
4. **Expand the row** to per-configuration values (click the disclosure triangle on the left of the row).
5. Set **Debug** to point at `<App>.Debug.entitlements`.
6. Leave **Release** pointing at the original production entitlements file.

### Step 6 — Disable Xcode 16's debug-dylib feature

1. App target → **Build Settings** → search `Enable Debug Dylib Support`.
2. Set to **No** for the app target. (This produces a monolithic Debug build with no separate `.debug.dylib` for the wrapper to load. The library-validation exception in Step 5 covers XCTest bundles, but Xcode 16's debug-dylib pattern is a separate `dlopen` that this setting bypasses entirely — simpler than trying to make library validation accept it.)

---

## Phase 3 — Verification

1. **`Cmd-B` Debug build.** Should succeed with no signing errors.
2. **`codesign -dv --verbose=4` on the built `.app`** (path: `~/Library/Developer/Xcode/DerivedData/<project>-<hash>/Build/Products/Debug/<App>.app`):

   ```
   codesign -dv --verbose=4 ~/Library/Developer/Xcode/DerivedData/.../Debug/<App>.app
   ```

   Output should show `Authority=<CertName>`. No `Authority=Apple Development:` line.

3. **`Cmd-R` run.** App launches, no Gatekeeper warnings (locally-built apps have no quarantine attribute).

4. **`Cmd-U` test.** Tests pass — the test bundle loads into the host process without library-validation rejection.

---

## Known Gotchas

These were discovered the hard way during the first real implementation. Captured here so future projects do not rediscover.

### Library validation blocks loading dylibs that don't share a TeamIdentifier

This is the biggest gotcha and you will hit it without the Debug-only entitlements file from Phase 2 Step 5 and the debug-dylib disable from Phase 2 Step 6.

Library validation (a Hardened Runtime feature, on by default) requires every dynamic library loaded into the host process to have a matching `TeamIdentifier` in its code signature. **Self-signed certificates have `TeamIdentifier=not set`, and "not set" does not count as a positive match** — even when the host and the loaded library are signed with the exact same self-signed cert.

This breaks two distinct things:

1. **Xcode 16's debug-dylib feature.** Xcode 16's default Debug-build pattern splits the app into a thin executable + a separate `.debug.dylib`. The wrapper `dlopen`s the dylib at launch. Library validation rejects the load. The app crashes at launch with `EXC_CRASH (SIGABRT)`; the crash log says `Library not loaded: @rpath/<App>.debug.dylib ... code signature ... not valid for use in process: mapping process and mapped file (non-platform) have different Team IDs`. **Fix:** the `Enable Debug Dylib Support = No` setting (Phase 2 Step 6).

2. **XCTest test bundles.** When tests run, the host app `dlopen`s the `.xctest` bundle. Library validation rejects this exactly the same way. The crash report says `Failed to load the test bundle ... mapping process and mapped file (non-platform) have different Team IDs`. **Fix:** the Debug-only entitlements file with `com.apple.security.cs.disable-library-validation` (Phase 2 Step 5).

For embedded frameworks signed by someone else's team, the same library-validation rules apply. SPM dependencies build from source so they pose no problem; pre-built third-party frameworks need either their own re-signing or the same Debug-only exception (which carries the same security trade-off).

### "Code signing identity '<CertName>' not found" at build time

The cert is not in a keychain Xcode can see, or its key usage is wrong. Check:

- Is it in the **login** keychain (not just system or some other keychain)?
- Does it have `Code Signing` in the Extended Key Usage field? Without that, `security find-identity -p codesigning` will not see it.
- Is the keychain unlocked? Build phases sometimes fail when the login keychain is locked; use `security unlock-keychain` if needed.

### "errSecInternalComponent" or other code-signing errors

Almost always one of:

- Wrong cert chosen for one target but not another (check every Build Settings entry, all configurations).
- Test bundle still signed with the old Personal Team cert while host is signed with the new self-signed cert → library validation fails the test bundle load. Make sure ALL targets that load into the same process use the same cert.
- Keychain access permission prompts being denied. Allow `codesign` to access the cert's private key, ideally with "Always Allow" so future builds do not re-prompt.

### Signed app shows "from an unidentified developer" if downloaded from the internet

Expected — Gatekeeper checks against Apple-trusted issuers, and a self-signed cert is not one. Locally-built apps do not have the quarantine attribute, so no warning appears. If you copy the `.app` to another Mac via AirDrop / a download / etc., quarantine kicks in and Gatekeeper warns. This is the price of self-signed; it is why you switch to Developer ID for distribution.

### M-series Mac requires every binary to be signed (even ad-hoc)

True, but the self-signed cert satisfies this requirement just fine. No special handling needed.

### Don't forget to switch back before shipping

This is a development-time identity. Before archiving for distribution:

1. Restore Automatic signing (or set Manual + Developer ID Application).
2. Set `DEVELOPMENT_TEAM` back to the paid team identifier.
3. Remove the `disable-library-validation` Debug entitlement (or revert the Debug entitlements file pointer to the production one).
4. Re-enable `Enable Debug Dylib Support` if you want the Xcode 16 debug-dylib pattern back.
5. Verify with `codesign -dv --verbose=4` that `Authority=Developer ID Application: <name> (<TEAMID>)` appears.

In any project with milestone-based release tracking, make this an explicit step in the release milestone description so it does not get forgotten. The project's overall directive should call out the self-signed cert as a current development-time choice, with the switch-back as a known release prerequisite.

---

## What This Procedure Does NOT Do

- **Does not change entitlements (other than adding the Debug-only library-validation exception), Hardened Runtime configuration, or sandbox capabilities.** Those stay enabled and unchanged across signing-identity switches.
- **Does not enable distribution.** Self-signed builds work only on the developer's own machine; distribution requires a Developer ID Application certificate and notarization.
- **Does not address provisioning profiles for iOS.** macOS apps that do not use entitlements-requiring-provisioning (push notifications, App Groups across multiple apps, iCloud) do not need profiles. iOS apps generally do, and the procedure is more involved there — when a project targets iOS, this template needs an iOS-specific addendum.
- **Does not edit `.pbxproj` programmatically.** Build Settings changes are deliberately left for the human in Xcode UI to avoid risk to project integrity.
- **Does not commit the certificate.** The private key never leaves the developer's keychain; nothing about the cert lives in the repo.

---

*Template status: Battle-tested via real implementation; bugs found during initial setup folded back in.*
*Last updated: 2026-05-04.*
*Will be revised when the project owner has a paid Developer Program membership and a Developer ID Application certificate.*
