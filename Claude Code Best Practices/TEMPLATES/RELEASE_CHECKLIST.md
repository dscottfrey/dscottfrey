# Release Checklist — TestFlight and App Store

Every hand-off to testers, in order. Copy this into the project's `Docs/` as `TESTFLIGHT_CHECKLIST.md` at project setup and fill in the bracketed parts. Print it, or keep it open, every time.

Written 2026-09-04 after a Codex build was archived, uploaded, and never added to the tester group — so nobody got it. The steps had been scattered across four documents; a checklist that lives in one place is the fix. The other items here each cost one wasted upload, one lost morning, or one build that reached a tester's device in the wrong state.

**The owner archives and uploads by hand, deliberately.** Do not propose automating the upload. Codex's owner, offered CI: *"no, I archive and upload by hand."* Xcode Cloud is not connected and must not be.

---

## 0. Project Settings Audit — once, before the FIRST upload, and after any Xcode major version

Xcode fills a new project with *its* defaults, not the directive's. Nobody chooses them, so nobody checks them. On Codex the deployment target was `26.4` in all four build configurations — Xcode 26's default — while the directive said iOS 17 and the owner believed 18. Anyone on an older OS, including both intended testers, would have been told the build was incompatible **after** waiting out Beta App Review. Found by a readiness check the night before, not by a tester.

Open the target's Build Settings and compare each of these with the overall directive:

- [ ] **Deployment target** matches the directive, in every configuration (Debug, Release, and any tester configuration).
- [ ] **Marketing version** (`MARKETING_VERSION`) is what the release plan says.
- [ ] **Bundle identifier** matches the App Store Connect record.
- [ ] **Signing**: the team is the paid Developer Program team; automatic signing is on; the certificate is not a Personal Team one (see `02_DEVELOPMENT_PHILOSOPHY.md` "Development Signing Doesn't Expire").
- [ ] **`ITSAppUsesNonExemptEncryption = false`** in `Info.plist` (if the app uses only standard OS encryption), so the export-compliance question never appears on upload.
- [ ] **App icon**: the single 1024×1024 slot is filled. **Launch screen**: generated (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`) or provided.
- [ ] **Diagnostics compilation condition** (`DIAGNOSTICS` or the project's name for it) is set on the tester configuration and NOT on the public-release configuration. See `07_TESTING_AND_DIAGNOSTICS.md`.
- [ ] **No DEBUG-only symbol is referenced from a Release path.** A `Product → Archive` will find these, but a `grep` for every `#if DEBUG` and its call sites is faster and does not need Xcode.
- [ ] **A Release archive has actually been run at least once.** "Debug typechecks" is not "archives cleanly." Do the first `Product → Archive` EARLY, days before it matters, not the night before.

---

## A. Before Archiving

1. [ ] **The working copy is on `main`.** Xcode's title bar shows the branch name under the project name. Never archive from a branch.
2. [ ] **Unit tests green** (⌘U). Before every handed build, no exceptions.
3. [ ] **Build number bumped.** If build identification is automated per `TEMPLATES/BUILD_NUMBER_AUTOMATION.md`, this is done for you — verify it fired. If it is hand-maintained (Codex, date-based `YYYYMMDDNN`), bump it now; a second archive on the same day bumps the last two digits. **App Store Connect rejects a duplicate build number outright.** Codex had the number go stale twice, found minutes before an archive each time.
4. [ ] **The log stamp updated** so the first line of every tester's log names this build. If hand-maintained, this is the second thing that goes stale.
5. [ ] **No copyrighted resource under the app's source folder.** An Xcode *file-system synchronized group* ships every file inside it, and `#if DEBUG` governs code, not resources. Two copyrighted sample books reached a Codex TestFlight build this way, unusable by the shipped code and 5 MB heavier. Anything not yours lives outside every synchronized group, in a gitignored folder.
6. [ ] **CloudKit projects: deploy the schema to Production** in the CloudKit Dashboard BEFORE the upload. A tester's device talks to Production; a record type that exists only in Development fails their save. **And remember how Development learns a type:** only when a record of it is actually exported from a dev device. A type that has never had a record saved is not in Development and cannot be deployed — Codex found a merge-tombstone type missing from Production the evening after a deploy. A dev-build launch step that inserts and deletes one record of every synced type is the guard.
7. [ ] **Anything owed before this upload is done, or explicitly left out and written down** — the "What to Test" notes (step 13) carry the known-do-not-report list, so nothing is silently absent.

---

## B. Archive and Upload

8. [ ] **Product → Archive.**
9. [ ] **Check the archive for resources that should not be there** before uploading. On Codex:
   ```sh
   find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -newer Docs/TESTFLIGHT_CHECKLIST.md -exec find {} -iname "*.epub" \;
   ```
   Adjust the extension to whatever kind of file must not ship. Only the app's own bundled content may appear.
10. [ ] **Check the archive's build number** is the one from step 3:
    ```sh
    /usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "<archive>/Info.plist"
    ```
11. [ ] **Organizer → Distribute App → TestFlight & App Store → Upload.** If the export-compliance question appears, step 0 was missed.

---

## C. App Store Connect — the part that gets forgotten

12. [ ] **Wait for processing.** Usually 5 to 30 minutes; Apple emails when it is done.
13. [ ] **TestFlight tab → the build → ADD IT TO THE TESTER GROUP.** A processed build is invisible to testers until it is in a group. This is the step Codex forgot.
    - **Internal group** (App Store Connect team users, up to 100): available the moment it is added. No Beta App Review, no App Privacy questionnaire. Use it for the owner's own devices and a same-day check.
    - **External group** (email invitations or a public link): the FIRST build of a new app goes through Beta App Review — hours to a day. Later builds usually pass quickly, but the tester sees nothing until Apple approves it. App Privacy answers must be complete before external testing.
    - Record which group the testers are in, here: **[internal / external]**.
14. [ ] **Fill in "What to Test."** Written for the testers, in plain English, under 4,000 characters. Structure that worked on Codex: what the build is mostly about in one sentence; NEW / CHANGED / FIXED, each as short bullets a reader can try; a **KNOWN, DO NOT REPORT** list (the same discipline as the pre-test brief in `07_TESTING_AND_DIAGNOSTICS.md` — testers cannot see the seams either); and *what we most want to hear*, as three numbered questions. Ask them to keep diagnostics on if the log matters. Keep a copy in the repo (`Docs/testflight/WHAT_TO_TEST_<build>.md`).
15. [ ] **Confirm a tester can see it.** The TestFlight app on their device shows the new build number. If a tester says "no update," it is almost always step 13, then step 3.

---

## D. After the Hand-Off

16. [ ] **Freeze the tree.** One build in flight per device per round. No commits to the code path under test, no newer build, no revised instructions until the reports are in. See `07_TESTING_AND_DIAGNOSTICS.md` "The Test Round Protocol."
17. [ ] **The assistant checks the stamp** in each tester's log in the shared diagnostics folder, before interpreting anything, and never asks a tester to find it. That is the assistant's job.
18. [ ] **Record the build number, stamp, date and group in the project's resume/handoff file**, so the next session knows what testers are running.

---

## E. Public Release Only — additional items

19. [ ] **The diagnostics condition is OFF** on the release configuration, and the one instrument that must never ship (any that captures user content) is confirmed absent from the archive.
20. [ ] **App Privacy answers** match what the build actually does. A build that blocks all remote content and collects nothing says so.
21. [ ] **Marketing version bumped** by hand; the build number keeps counting.
22. [ ] **The manual, help, or first-run text** describes this build, not the last one.

---

## F. macOS Direct Distribution — the Developer ID / notarization variant *(Revised 2026-09-04, Icarus)*

For an app that never touches the App Store or TestFlight: signed with the Developer ID Application identity, notarized, stapled, and handed to the customer as a `.app` or DMG. Sections 0, A(1–2, 5), D and E above still apply. What replaces B and C is below, **in this order**. Written after Icarus notarized a 1.3.0's worth of work as 1.2.0 with no release notes (2026-08-06): every rule below was already documented, and every one was done *after* the build instead of before it, so the artefact that reached the lab described a different version from the one they were running.

**Trigger:** the owner says any of *"I'm shipping this"*, *"I'll build it"*, *"putting it on the lab"*, *"notarizing"*. At that moment steps 1–4 are owed **before** a build exists. Do them unprompted; do not do only the one that was mentioned.

**Before the build**

1. [ ] **Commit everything.** A dirty tree stamps the build `<sha>+` and it cannot be traced back to source. Never build from a dirty tree "just to test it on the lab" — that build always ends up staying.
2. [ ] **Bump `MARKETING_VERSION`** in every configuration, **once per shipped build**, by the largest increment the release earns (patch = fixes only; minor = anything the customer will notice or a data-file change that stays readable; major = the owner's call, never automatic). Two different binaries must never share a version — the customer keeps every build side by side and picks by name.
3. [ ] **Close the `Unreleased` section of the running release notes** (`TEMPLATES/RELEASE_NOTES.md`): stamp it with the version and date, open a fresh one above it.
4. [ ] **Write the customer-facing notes** for this build, in plain English, matching the tone of the previous ones. Two rules outrank completeness: **lead with whatever the customer will SEE that they did not ask for** (a change in visible behaviour is alarming unexplained and reassuring described), and **state plainly what has NOT been proven** — the bench lacks the hardware; say what *was* tested.

**The build**

5. [ ] **Build Release, then notarize** (`notarytool submit --wait`, then `stapler staple`, then `stapler validate`). Notarization is a scanning service, not publication — nothing reaches anyone until the app is installed, and a submission can be abandoned at no cost, so a wrong build is always cheaper to rebuild than to ship.
6. [ ] **Fill in the build number** in the notes — it can only be known once the build exists.

**Before it leaves the machine**

7. [ ] **Open the About panel and read it back.** The version from step 2, and a short git SHA with **no trailing `+`**. This one glance catches a dirty tree, a skipped bump and a stale build. If it disagrees with the notes sitting next to it, stop.
8. [ ] **Say what the customer has to do differently** — new settings, new files to keep, behaviour to expect — in the message that carries the build, not only in the notes.
9. [ ] **The customer keeps the previous build.** Rollback is then always available, which is what makes dropping a build into a live run a reversible move. Tell them which one to fall back to.

*(A self-built Developer ID build runs on another Mac without notarization — only the quarantine flag matters, `xattr -dr com.apple.quarantine`. Useful for a same-day check; not a substitute for the steps above.)*

---

## Why this is a checklist and not a memory

Every one of these was, at some point, "obviously remembered." The deployment target, the copyrighted samples, the stale build number, the un-deployed schema, and the empty tester group were each forgotten exactly once, by people who knew better, on a day when something else was on fire. A list that is followed top to bottom does not have days like that.

---

*Template status: generalised 2026-09-04 from `Docs/TESTFLIGHT_CHECKLIST.md` in the Codex iOS project; section F added 2026-09-04 from `Docs/Deployment/SHIP_CHECKLIST.md` in the Icarus macOS project. Fill in the bracketed values per project.*
