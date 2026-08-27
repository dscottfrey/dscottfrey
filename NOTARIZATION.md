# Notarizing IcarusVirtualHub

How to build, notarize, and distribute IcarusVirtualHub so it launches without
Gatekeeper warnings on any Mac. This is for **Developer ID distribution**
(outside the Mac App Store).

> The project is already configured for this. You should only need the one-time
> credential setup (Step 1), then run `./notarize.sh` whenever you ship a build.

---

## What "notarization" is

Apple requires apps distributed outside the App Store to be:

1. **Signed** with a *Developer ID Application* certificate.
2. Built with the **Hardened Runtime** enabled.
3. **Notarized** — uploaded to Apple's notary service, which scans for malware
   and issues a "ticket."
4. **Stapled** — the ticket is attached to the app so it validates even offline.

Without notarization, users see *"IcarusVirtualHub can't be opened because Apple
cannot check it for malicious software"* and have to right-click → Open or dig
through System Settings. With it, the app just opens.

---

## Already configured (no action needed)

These are baked into the Xcode project (`Release` configuration):

| Setting | Value |
|---|---|
| Signing certificate | `Developer ID Application: D. Scott Frey (B96HF9533R)` |
| Team ID | `B96HF9533R` |
| Hardened Runtime | Enabled |
| App Sandbox | Off (app writes to a user-chosen folder) |
| Entitlements | `com.apple.security.network.client` only |

> **Do not** set a Development Team on the **Debug** configuration. Debug signs
> with the local "Lab Code Cert," which is not part of team B96HF9533R, and
> setting the team there breaks the local build. Only `Release` carries the team.

---

## Step 1 — One-time credential setup

The notary service needs to authenticate you. Easiest method is an
**app-specific password**.

1. Go to <https://account.apple.com> → **Sign-In and Security** →
   **App-Specific Passwords** → **+** (Generate).
   - Label it e.g. `notarytool`.
   - Copy the generated password (format `xxxx-xxxx-xxxx-xxxx`).
   - *(If account.apple.com is down, try again later — it's an Apple-side
     outage, nothing local. The rest of this guide doesn't change.)*

2. Store it in your login keychain under the profile name `IcarusNotary`
   (this is the name `notarize.sh` expects):

   ```bash
   xcrun notarytool store-credentials "IcarusNotary" \
       --apple-id "scottfrey@mac.com" \
       --team-id "B96HF9533R" \
       --password "xxxx-xxxx-xxxx-xxxx"
   ```

   You only do this once per machine. The password is saved securely in the
   keychain; you never type it again.

### Alternative — App Store Connect API key (more robust for automation)

If you prefer an API key over an app-specific password:

1. <https://appstoreconnect.apple.com> → **Users and Access** → **Integrations**
   → **App Store Connect API** → generate a key with the *Developer* role.
2. Download the `AuthKey_XXXXXXXXXX.p8` (you can only download it once) and note
   the **Key ID** and **Issuer ID**.
3. Store it:

   ```bash
   xcrun notarytool store-credentials "IcarusNotary" \
       --key "/path/to/AuthKey_XXXXXXXXXX.p8" \
       --key-id "XXXXXXXXXX" \
       --issuer "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
   ```

Either way the profile is named `IcarusNotary`, so `notarize.sh` works unchanged.

---

## Step 2 — Build and notarize

From the project root:

```bash
./notarize.sh
```

This runs the whole pipeline and prints `✅ Done` with the path to the finished
app. It takes a few minutes (most of it waiting on Apple's notary service).

What the script does, in order:

1. **Archive** the `Release` configuration → `build/IcarusVirtualHub.xcarchive`
2. **Export** a Developer ID-signed app → `build/export/IcarusVirtualHub.app`
   (this strips the debug `get-task-allow` entitlement and adds a secure timestamp)
3. **Zip** it for upload (`ditto -c -k --keepParent`)
4. **Submit** to Apple with `xcrun notarytool submit --wait`
5. **Staple** the ticket onto the app
6. **Verify** with `stapler validate`, `spctl`, and `codesign`

The distributable app is `build/export/IcarusVirtualHub.app`.

---

## Step 3 — Verify (the script does this, but to check by hand)

```bash
APP="build/export/IcarusVirtualHub.app"

# Gatekeeper should say: accepted, source=Notarized Developer ID
spctl -a -vvv --type execute "$APP"

# Stapled ticket present
xcrun stapler validate "$APP"

# Signature details: Developer ID authority, runtime flag, secure timestamp
codesign -dvvv "$APP" 2>&1 | grep -iE "Authority=|flags=|Timestamp=|TeamIdentifier"
```

A correctly notarized app shows:
- `Authority=Developer ID Application: D. Scott Frey (B96HF9533R)`
- `flags=0x10000(runtime)`
- a real `Timestamp=` (not absent)
- `spctl` → `source=Notarized Developer ID`

---

## Step 4 — Distribute

Notarize the **app**, then wrap it for delivery. Two common options:

### Zip (simplest)
```bash
ditto -c -k --keepParent build/export/IcarusVirtualHub.app IcarusVirtualHub.zip
```
The stapled ticket travels inside the `.app`, so the zip is ready to send.

### DMG (nicer for end users)
```bash
hdiutil create -volname "IcarusVirtualHub" \
    -srcfolder build/export/IcarusVirtualHub.app \
    -ov -format UDZO IcarusVirtualHub.dmg
# Notarize and staple the DMG itself too:
xcrun notarytool submit IcarusVirtualHub.dmg --keychain-profile "IcarusNotary" --wait
xcrun stapler staple IcarusVirtualHub.dmg
```

---

## Re-notarizing after code changes

Every time you change the app you must re-sign and re-notarize:

```bash
./notarize.sh
```

That's it — same command. The notary ticket is tied to that exact binary, so a
new build needs a new ticket.

---

## Checking a submission's status / log

```bash
# Recent submissions
xcrun notarytool history --keychain-profile "IcarusNotary"

# Why a specific submission was rejected (use the id from history/submit)
xcrun notarytool log <submission-id> --keychain-profile "IcarusNotary"
```

---

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `No certificate for team 'B96HF9533R' matching 'Lab Code Cert'` | A Development Team got set on the **Debug** config. Clear it — only Release should have the team. |
| Notary rejects with `The signature does not include a secure timestamp` | You signed with `--timestamp=none` (a plain `xcodebuild build`). Use `notarize.sh` / the archive+export flow, which timestamps automatically. |
| Notary rejects with `The executable requests the com.apple.security.get-task-allow entitlement` | Same cause — you submitted a development build. The export step strips it; use the script. |
| `Error: Must provide credentials` | Step 1 not done, or the profile name passed to `notarytool` doesn't match `IcarusNotary`. |
| App still warns after notarizing | You didn't **staple** (or you stapled the app but distribute a DMG that isn't stapled). Staple whatever you actually ship. |
| Notary service slow / `In Progress` for a long time | Normal under load; `--wait` blocks until done. Usually 1–5 min, occasionally longer. |
| `account.apple.com` won't load | Apple-side outage. Retry later; nothing to fix locally. Credentials, once stored, keep working through outages. |

---

## Quick reference

```bash
# One-time
xcrun notarytool store-credentials "IcarusNotary" \
    --apple-id "scottfrey@mac.com" --team-id "B96HF9533R" \
    --password "xxxx-xxxx-xxxx-xxxx"

# Every release
./notarize.sh

# Verify
spctl -a -vvv --type execute build/export/IcarusVirtualHub.app
```

- **Team ID:** `B96HF9533R`
- **Signing cert:** `Developer ID Application: D. Scott Frey (B96HF9533R)`
- **Keychain profile:** `IcarusNotary`
- **Script:** `notarize.sh` (repo root)
- **Output:** `build/export/IcarusVirtualHub.app`
