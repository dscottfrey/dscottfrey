# Build Number Automation — Reference Implementation

The procedure for setting up automated build identification in an Xcode project from day one. Every build embeds an unambiguous identifier in its About panel.

This is set up at the start of a new project, not retrofitted later — the kit treats build identification as a foundational practice, like git itself, that goes in before any feature work begins. The implementation is battle-tested: it was refined from a real-world setup, and the bugs found during that setup are captured in "Known Gotchas" below so future projects do not rediscover them.

---

## What You Are Setting Up

Every build embeds in the About panel:

- A timestamp `YYMMDDhhmm` (e.g. `2605041335`)
- The short git SHA of HEAD
- A `+` dirty marker when the working tree had uncommitted changes
- The active configuration

Example display: `Build 2605041335 · a7672bc+`

Release builds additionally get a monotonically-increasing `CFBundleVersion` (matching the timestamp) for App Store / TestFlight / Sparkle compatibility, *without* mutating any committed file.

The pieces:

1. Two tracked-in-git scripts (`Scripts/generate_build_info.sh` and `Scripts/bump_built_info_plist.sh`)
2. A tracked placeholder Swift file (`<target_source>/Generated/BuildInfo.swift`) that the script overwrites every build
3. Two Run Script build phases per app target (one before Compile Sources, one as the last phase)
4. A Build Setting change (User Script Sandboxing → No)
5. About-screen wiring that reads from the generated file

---

## Decisions Baked Into This Approach

For when future-you wonders why something was done this way.

### Mutate the BUILT Info.plist on Release, not the source

If the target uses `GENERATE_INFOPLIST_FILE = YES` (Xcode 16 default for new projects), there is no source `Info.plist` file to mutate. Solution: PlistBuddy on the *built* Info.plist (`$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH`) AFTER Xcode generates it but BEFORE Code Sign. Works for both generated and hand-maintained modes. Never touches a committed file. The source `CURRENT_PROJECT_VERSION` in `.pbxproj` stays at its baseline value.

### Two Run Script phases, not one

The two operations need different positions in the build phase order:

- **"Generate BuildInfo"** runs BEFORE Compile Sources — the Swift file must exist before the compiler reads it.
- **"Bump CFBundleVersion (Release only)"** runs AFTER Copy Bundle Resources (which is implicitly after Process Info.plist on a generated-Info.plist project) — the built plist must exist before we mutate it.

A single script cannot be in two places, so two phases, two scripts.

### Track the BuildInfo.swift placeholder; tolerate or suppress its noise

`BuildInfo.swift` is regenerated on every build. Three options for handling git-status noise:

1. **Tolerate the noise.** For a solo dev who stages by filename (not `git add -A`), the noise lives only in `git status` output and Xcode's "M" badges. Doesn't pollute commits. **Default for solo projects.**
2. **`git update-index --skip-worktree` per clone.** Eliminates noise but requires every contributor to remember the setup step. **Use for a multi-contributor public project.**
3. **Bundle redesign:** read from `Bundle.main.infoDictionary` instead of a generated Swift file. No source file is touched on every build. More invasive but eliminates the issue entirely. **Use when contributor onboarding matters more than implementation simplicity.**

Why not pure gitignore: `PBXFileSystemSynchronizedRootGroup` (Xcode 16+) determines target membership at build-graph construction time, before any Run Script runs. A pure-gitignore approach risks the first build on a fresh clone omitting `BuildInfo.swift` from the binary.

### About panel via `NSApp` + `.commands` (macOS SwiftUI)

Override the SwiftUI default "About <App>" menu item with `.commands { CommandGroup(replacing: .appInfo) { ... } }`. The button calls an AppKit helper that uses `NSApp.orderFrontStandardAboutPanel(options:)` with a `.credits` `NSAttributedString` containing the build line. The standard panel's icon, name, version, and copyright are preserved; only the Credits area gets a build line added. `.commands` attaches to the scene, so it is forward-compatible with a future `WindowGroup → DocumentGroup` migration.

For iOS or a SwiftUI custom About view, just put `Text("Build \(BuildInfo.displayString)")` somewhere visible.

---

## Phase 1 — Files to Create

### `Scripts/generate_build_info.sh`

Create at the repo root. Make it executable: `chmod +x Scripts/generate_build_info.sh`. Commit it.

```bash
#!/bin/bash
# Generate <output>/BuildInfo.swift with build timestamp, short git SHA, and dirty marker.
# Runs as a Run Script build phase BEFORE Compile Sources. Output path is the first argument.
# See Claude Code Best Practices / 02_DEVELOPMENT_PHILOSOPHY.md "Every Build Is Identifiable".

set -e

# --- Compute build identifier values ---

TIMESTAMP=$(date +%y%m%d%H%M)

# Build phases run with a minimal PATH; locate git via xcrun or fall back.
GIT=$(xcrun -find git 2>/dev/null || which git || echo "/usr/bin/git")

if [ -x "$GIT" ] && "$GIT" -C "$SRCROOT" rev-parse --git-dir > /dev/null 2>&1; then
    GIT_SHA=$("$GIT" -C "$SRCROOT" rev-parse --short HEAD 2>/dev/null || echo "nohead")
    if "$GIT" -C "$SRCROOT" diff --quiet 2>/dev/null && \
       "$GIT" -C "$SRCROOT" diff --cached --quiet 2>/dev/null; then
        IS_DIRTY="false"
    else
        IS_DIRTY="true"
    fi
else
    GIT_SHA="nogit"
    IS_DIRTY="false"
fi

# --- Write BuildInfo.swift ---

BUILD_INFO_PATH="$1"

if [ -z "$BUILD_INFO_PATH" ]; then
    echo "error: generate_build_info.sh requires the BuildInfo.swift output path as its first argument"
    exit 1
fi

mkdir -p "$(dirname "$BUILD_INFO_PATH")"

cat > "$BUILD_INFO_PATH" <<EOF
// BuildInfo.swift
// AUTO-REGENERATED at build time. Tracked in git as a placeholder; the contents are
// overwritten on every build. Do not edit by hand.
// See 02_DEVELOPMENT_PHILOSOPHY.md "Every Build Is Identifiable" for the why.

enum BuildInfo {
    static let timestamp: String = "$TIMESTAMP"
    static let gitSHA: String = "$GIT_SHA"
    static let isDirty: Bool = $IS_DIRTY
    static let configuration: String = "$CONFIGURATION"

    /// Display string suitable for an About screen, e.g. "2605041335 · a7672bc+"
    static var displayString: String {
        let dirtyMarker = isDirty ? "+" : ""
        return "\(timestamp) · \(gitSHA)\(dirtyMarker)"
    }
}
EOF

echo "BuildInfo: $TIMESTAMP $GIT_SHA dirty=$IS_DIRTY config=$CONFIGURATION"
```

### `Scripts/bump_built_info_plist.sh`

Create at the repo root. Make it executable. Commit it.

```bash
#!/bin/bash
# Bump CFBundleVersion in the BUILT Info.plist on Release builds only.
# Runs as the LAST build phase, after Process Info.plist and Copy Bundle Resources,
# but before Code Sign. Mutates the built copy of Info.plist, never any source file.
# Works for both hand-maintained Info.plist and GENERATE_INFOPLIST_FILE = YES projects.
# See Claude Code Best Practices / 02_DEVELOPMENT_PHILOSOPHY.md "Every Build Is Identifiable".

set -e

if [ "$CONFIGURATION" != "Release" ]; then
    echo "bump_built_info_plist: skipping (CONFIGURATION=$CONFIGURATION)"
    exit 0
fi

BUILT_PLIST="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

if [ ! -f "$BUILT_PLIST" ]; then
    echo "error: built Info.plist not found at $BUILT_PLIST"
    exit 1
fi

TIMESTAMP=$(date +%y%m%d%H%M)

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $TIMESTAMP" "$BUILT_PLIST"
echo "bump_built_info_plist: CFBundleVersion = $TIMESTAMP"
```

### `<target_source>/Generated/BuildInfo.swift` (tracked placeholder)

For each app target, create this file with sentinel placeholder content. The script will overwrite it on the first build, but the placeholder must exist *before* the first build so synchronized groups (Xcode 16+) include it as a target member.

```swift
// BuildInfo.swift
// AUTO-REGENERATED at build time. Tracked in git as a placeholder; the contents are
// overwritten on every build. Do not edit by hand.
// See 02_DEVELOPMENT_PHILOSOPHY.md "Every Build Is Identifiable" for the why.

enum BuildInfo {
    static let timestamp: String = "uninit"
    static let gitSHA: String = "uninit"
    static let isDirty: Bool = false
    static let configuration: String = "uninit"

    /// Display string suitable for an About screen, e.g. "2605041335 · a7672bc+"
    static var displayString: String {
        let dirtyMarker = isDirty ? "+" : ""
        return "\(timestamp) · \(gitSHA)\(dirtyMarker)"
    }
}
```

If `.gitignore` already matches `**/Generated/BuildInfo.swift` (per the next step), use `git add -f <path>` to force-track this placeholder.

### `.gitignore` addition

Append to `.gitignore` at the repo root:

```
# Auto-regenerated on every build. Tracked once as a placeholder; .gitignore here
# documents intent and catches any future Generated/ files. See Claude Code Best
# Practices / 02_DEVELOPMENT_PHILOSOPHY.md.
**/Generated/BuildInfo.swift
```

This is inert on the tracked placeholder file (gitignore does not untrack files), but documents intent and catches any future `Generated/` files.

### About panel wiring (macOS SwiftUI)

`<target_source>/Views/AboutPanel.swift`:

```swift
import AppKit

@MainActor
enum AboutPanel {
    static func show() {
        let credits = NSAttributedString(
            string: "Build \(BuildInfo.displayString)",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: credits
        ])
    }
}
```

In `<target>App.swift`, add to the scene:

```swift
.commands {
    CommandGroup(replacing: .appInfo) {
        Button("About <AppName>") { AboutPanel.show() }
    }
}
```

`.commands` attaches to the scene, so this survives a future `WindowGroup → DocumentGroup` migration.

### About view (iOS SwiftUI)

For iOS, no menu override is needed — wire an About view into Settings or wherever a tap reveals app info:

```swift
import SwiftUI

struct AboutView: View {
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App"
    }

    private var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(appName).font(.title2)
            Text("Version \(marketingVersion)").font(.subheadline)
            Text("Build \(BuildInfo.displayString)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding()
    }
}
```

---

## Phase 2 — Manual Xcode Steps for the Human

These three steps require Xcode's UI. **Do NOT edit `.pbxproj` programmatically** — risk to project integrity is not worth it.

### Step 1 — Add "Generate BuildInfo" Run Script phase

1. Project Navigator → top item → TARGETS → app target.
2. **Build Phases** tab → `+` → **New Run Script Phase**.
3. Rename to `Generate BuildInfo`.
4. **Drag it ABOVE Compile Sources** (also called "Sources").
5. **Uncheck "Based on dependency analysis"** — this script must run every build.
6. Paste this exact script body — **the surrounding `"` characters ARE part of the literal command, not markdown formatting**:

   ```
   "${SRCROOT}/Scripts/generate_build_info.sh" "${SRCROOT}/<target_source>/Generated/BuildInfo.swift"
   ```

   Verify exactly **four `"` characters** in the box. Replace `<target_source>` with the actual folder name.

### Step 2 — Add "Bump CFBundleVersion (Release only)" Run Script phase

1. Same Build Phases tab → `+` → **New Run Script Phase**.
2. Rename to `Bump CFBundleVersion (Release only)`.
3. Position it as the **LAST** phase (after Copy Bundle Resources).
4. **Uncheck "Based on dependency analysis"**.
5. Paste:

   ```
   "${SRCROOT}/Scripts/bump_built_info_plist.sh"
   ```

   Verify exactly **two `"` characters**.

### Step 3 — Disable User Script Sandboxing

1. Same target → **Build Settings** tab.
2. Filter buttons: **All** + **Combined**.
3. Search box: type `sandbox` (short queries match where longer ones sometimes miss).
4. Find **Build Options → User Script Sandboxing**. Click the value (`Yes`) → set to **No** (for both Debug and Release).

**Why this is safe:** This setting affects only build-time tooling. It does NOT affect the shipped binary's App Sandbox or Hardened Runtime, which remain enabled per the `.entitlements` file. It is not a runtime app capability.

**Why it is necessary:** Xcode 16 default sandboxes Run Scripts so they can only read inside the build directory. These scripts need to read `Scripts/*.sh` (in the source tree) and run `git` (reads `.git/`). Without disabling, builds fail with cryptic "No such file or directory" errors that do not name sandboxing as the cause.

---

## Phase 3 — Verification

1. **`Cmd-B` Debug build.** Should succeed. Build log shows:
   - `BuildInfo: <timestamp> <sha> dirty=<bool> config=Debug`
   - `bump_built_info_plist: skipping (CONFIGURATION=Debug)`
2. **`cat <target_source>/Generated/BuildInfo.swift`** — real values, not `"uninit"`.
3. **`Cmd-R` run + menu → `About <App>`.** Build line appears in the Credits area, looks like `Build 2605041335 · a7672bc+`.
4. **Archive once (Release).** Build log shows `bump_built_info_plist: CFBundleVersion = <timestamp>`. The archived `.app`'s Info.plist has the timestamped `CFBundleVersion`; source `CURRENT_PROJECT_VERSION` in `.pbxproj` is unchanged. `git status` is clean afterward (apart from `BuildInfo.swift` if you have not used `--skip-worktree`).

---

## Known Gotchas

These were discovered the hard way during the first real implementation. Captured here so future projects do not rediscover them.

### "No such file or directory" on first build

Almost always one of:

1. **Quote stripping during paste.** If you copied the script body from a markdown code block, the surrounding `"` characters may have been stripped. Re-check the script body in Xcode — it must include the literal `"` quotes around each path. Count them: four for the first script, two for the second.
2. **User Script Sandboxing = YES.** The sandbox blocks the script from reading `Scripts/` and from running `git`. Set the Build Setting to No (Phase 2 Step 3).

### About panel shows wrong-cased app name

The standard `NSApp` About panel uses `CFBundleName`, not `CFBundleDisplayName`. With `GENERATE_INFOPLIST_FILE = YES`, Xcode 16 hardcodes `CFBundleName` to track `PRODUCT_NAME`, which typically uses PascalCase. The dock and menu bar correctly show the lowercase display name from `CFBundleDisplayName`.

Three workarounds (all defer-able unless the casing actually matters):

- Run Script + PlistBuddy override of `CFBundleName` post-generation.
- Switch to a hand-maintained `Info.plist`.
- Live with it — the panel still functions.

### `BuildInfo.swift` perpetually shows in `git status`

Expected. The build regenerates it. Three options (already covered in "Decisions" above):

- **Tolerate.** Solo dev, stage by filename, never see it in commits.
- **`git update-index --skip-worktree`** per clone per developer.
- **Bundle redesign:** read from `Bundle.main.infoDictionary` instead.

### Synchronized-group projects: skip the "drag into Project Navigator" step

Xcode 16 projects using `PBXFileSystemSynchronizedRootGroup` auto-include any file written into the synchronized folder. The traditional manual drag is a no-op — the file will already be a target member. Verify by opening Build Phases → Compile Sources after the file is created; it should appear without manual addition.

### `.gitignore` and `git add` interact at staging time

If you run `git add <folder>/` and `.gitignore` matches a file inside, the file is silently skipped — no error. To force-track a file that matches `.gitignore`, use `git add -f <path>`.

This bites the placeholder commit if `.gitignore` is added in the same commit. Either commit the placeholder first and add `.gitignore` after, or use `git add -f` once.

---

## Things This Template Does NOT Do

- **Does not change `MARKETING_VERSION` (`CFBundleShortVersionString`).** That stays under human control.
- **Does not specify how the About surface integrates into the project's UI.** It provides the build-line content; where and how the About view is presented is a project-specific UX decision.
- **Does not modify CI configuration.** If the project uses Xcode Cloud, GitHub Actions, or Fastlane, the scripts work as-is on CI runners (they have `git`, `xcrun`, `PlistBuddy`); the only consideration is that CI clones will not have `--skip-worktree` set, so a CI build's working tree shows the `BuildInfo.swift` modification — harmless on CI.
- **Does not edit `.pbxproj` programmatically.** Run Script phases and Build Settings changes are deliberately left for the human in Xcode UI to avoid risk to project integrity.

---

*Template status: Battle-tested via real implementation; bugs found during initial setup folded back in.*
*Last updated: 2026-05-04.*
