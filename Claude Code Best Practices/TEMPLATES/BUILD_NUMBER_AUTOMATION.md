# Build Number Automation — Reference Implementation

Concrete script and code snippets for the "Every Build Is Identifiable" rule in `02_DEVELOPMENT_PHILOSOPHY.md`. Copy these into a new project rather than re-deriving them.

This template implements **Option B**: every build generates a gitignored `BuildInfo.swift` containing the timestamp, git SHA, and dirty marker. Release builds additionally bump `CFBundleVersion` in `Info.plist` for App Store / TestFlight monotonic-version compliance. Debug builds leave `Info.plist` alone, so day-to-day development does not pollute `git status`.

The same setup works for iOS and macOS targets — the script is identical. Only the About-screen presentation differs.

---

## What You Are Setting Up

1. A tracked-in-git script (`Scripts/generate_build_info.sh`) that produces the build identifier
2. A generated Swift file (`BuildInfo.swift`) that is overwritten on every build and is *not* tracked in git
3. A `.gitignore` entry so the regeneration does not pollute commits
4. A Run Script build phase per target that invokes the script
5. About-screen code that reads from the generated file

The script also updates `CFBundleVersion` on Release builds so the project is App-Store-ready from day one.

---

## Step 1 — Create the build-info generator script

The script lives as a tracked-in-git source file rather than embedded inside the Xcode build phase. This keeps `.pbxproj` clean, makes the script editable as normal source, and lets multiple targets in the same project share one script (each Run Script phase just passes a different output path).

Create:

```
Scripts/generate_build_info.sh
```

at the project root. Make it executable (`chmod +x Scripts/generate_build_info.sh`). Contents:

```bash
#!/bin/bash
# Generate BuildInfo.swift with timestamp, git SHA, and dirty marker.
# On Release builds, also bump CFBundleVersion in Info.plist for App Store / TestFlight.
# Called from a Run Script build phase. The output path is passed as the first argument
# so the same script works for any target / any source folder layout.
# See Claude Code Best Practices / 02_DEVELOPMENT_PHILOSOPHY.md.

set -e

# --- Compute build identifier values ---

TIMESTAMP=$(date +%Y%m%d%H%M)

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
    # Not a git repo, or git unavailable. Fail soft so non-git builds still work.
    GIT_SHA="nogit"
    IS_DIRTY="false"
fi

# --- Write BuildInfo.swift ---

# Output path is passed in by the build phase invocation.
BUILD_INFO_PATH="$1"

if [ -z "$BUILD_INFO_PATH" ]; then
    echo "error: generate_build_info.sh requires the BuildInfo.swift output path as its first argument"
    exit 1
fi

mkdir -p "$(dirname "$BUILD_INFO_PATH")"

cat > "$BUILD_INFO_PATH" <<EOF
// BuildInfo.swift
// AUTO-GENERATED at build time. Do not edit by hand. Do not commit (gitignored).
// See 02_DEVELOPMENT_PHILOSOPHY.md "Every Build Is Identifiable" for the why.

enum BuildInfo {
    static let timestamp: String = "$TIMESTAMP"
    static let gitSHA: String = "$GIT_SHA"
    static let isDirty: Bool = $IS_DIRTY
    static let configuration: String = "$CONFIGURATION"

    /// Display string suitable for an About screen, e.g. "2604051847 · a3f9c1e+"
    static var displayString: String {
        let dirtyMarker = isDirty ? "+" : ""
        return "\(timestamp) · \(gitSHA)\(dirtyMarker)"
    }
}
EOF

# --- On Release, bump CFBundleVersion for App Store / TestFlight ---
# Release uploads require monotonically increasing CFBundleVersion per marketing version.
# A timestamp satisfies this trivially. Debug builds skip this so git status stays clean.

if [ "$CONFIGURATION" = "Release" ]; then
    if [ -n "$INFOPLIST_FILE" ] && [ -f "${SRCROOT}/${INFOPLIST_FILE}" ]; then
        # Hand-maintained Info.plist file.
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $TIMESTAMP" "${SRCROOT}/${INFOPLIST_FILE}"
        echo "Release build: CFBundleVersion set to $TIMESTAMP in ${INFOPLIST_FILE}"
    else
        # Modern Xcode (15+) generates Info.plist from build settings — no file to update here.
        # In that case, set CURRENT_PROJECT_VERSION via xcconfig or use a scheme pre-action.
        # See "Modern Xcode (no Info.plist file)" later in this document.
        echo "warning: No Info.plist file at \$SRCROOT/\$INFOPLIST_FILE — see template doc for modern Xcode workaround"
    fi
fi

echo "BuildInfo: $TIMESTAMP $GIT_SHA dirty=$IS_DIRTY config=$CONFIGURATION"
```

Commit `Scripts/generate_build_info.sh` to the repository — it is normal source code and is versioned alongside the rest of the project.

---

## Step 2 — Create the placeholder `BuildInfo.swift`

For each target that needs a build identifier, create a placeholder Swift file at:

```
<YourTargetName>/Generated/BuildInfo.swift
```

The placeholder must exist so Xcode adds the file to the target's "Compile Sources" — the script will overwrite its contents on the next build, but Xcode needs to know the file is part of the target before that first build runs.

Initial contents:

```swift
// BuildInfo.swift
// AUTO-GENERATED at build time. Do not edit by hand. Do not commit (gitignored).
// See 02_DEVELOPMENT_PHILOSOPHY.md "Every Build Is Identifiable" for the why.

enum BuildInfo {
    static let timestamp: String = "000000000000"
    static let gitSHA: String = "uninit"
    static let isDirty: Bool = false
    static let configuration: String = "Unknown"

    /// Display string suitable for an About screen, e.g. "2604051847 · a3f9c1e+"
    static var displayString: String {
        let dirtyMarker = isDirty ? "+" : ""
        return "\(timestamp) · \(gitSHA)\(dirtyMarker)"
    }
}
```

In Xcode, drag this file into the target so it is compiled. Confirm it shows up under "Compile Sources" in the target's Build Phases.

---

## Step 3 — Add the `.gitignore` entry

Append to `.gitignore` at the project root:

```
# Auto-regenerated on every build by the BuildInfo Run Script phase.
# See Claude Code Best Practices / 02_DEVELOPMENT_PHILOSOPHY.md.
**/Generated/BuildInfo.swift
```

The script itself (`Scripts/generate_build_info.sh`) is intentionally *not* gitignored — it is committed as normal source.

After committing the placeholder once, run:

```
git rm --cached <YourTargetName>/Generated/BuildInfo.swift
git commit -m "Stop tracking generated BuildInfo.swift"
```

The file stays on disk; git just stops watching it.

---

## Step 4 — Add the Run Script build phase

In Xcode: select the target → Build Phases → `+` → New Run Script Phase.

**Drag the new phase to run *before* "Compile Sources"** so `BuildInfo.swift` is up to date when the compiler reads it.

Name the phase: `Generate BuildInfo`.

Uncheck "Based on dependency analysis" — this script must run every build, not only when input files change.

Paste this one-liner into the script body:

```bash
"${SRCROOT}/Scripts/generate_build_info.sh" "${SRCROOT}/<YourTargetName>/Generated/BuildInfo.swift"
```

Replace `<YourTargetName>` with the actual source folder for this target. If multiple targets need build identifiers, each one gets its own Run Script phase with its own output path argument — they all call the same `Scripts/generate_build_info.sh`.

Build the project once. `BuildInfo.swift` should now contain real values.

---

## Step 5 — Display in the About Screen

### iOS (SwiftUI)

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
            Text(appName)
                .font(.title2)
            Text("Version \(marketingVersion)")
                .font(.subheadline)
            // The full build identifier — uniquely identifies which build this is.
            // Mention this string when reporting issues or comparing screenshots.
            Text("Build \(BuildInfo.displayString)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding()
    }
}
```

### macOS — Using the Standard About Panel

The simplest macOS option is to inject the build identifier into the system About panel:

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

Wire `AboutPanel.show()` to the application's About menu item. For SwiftUI macOS apps using the `App` / `Scene` lifecycle, replace the default About menu item via:

```swift
.commands {
    CommandGroup(replacing: .appInfo) {
        Button("About \(appName)") { AboutPanel.show() }
    }
}
```

For AppKit-based apps, override the action of the existing About menu item in the storyboard or `MainMenu.xib`.

The standard panel automatically shows the app name, marketing version, and `CFBundleVersion` — your timestamp will appear there too on Release builds, and the `BuildInfo.displayString` in the credits area gives you the SHA and dirty marker on every build.

### macOS — Custom SwiftUI About Window

If you want a fully custom About view, the iOS SwiftUI code above works on macOS too. Present it in a `Window` scene or via `NSWindowController`.

---

## Modern Xcode (No `Info.plist` File)

Xcode 15+ projects often have no `Info.plist` file — Info.plist is generated from build settings. In that case the script's `PlistBuddy` step will hit the warning branch.

The workaround:

1. Add an `xcconfig` file to your project (e.g. `Config/Version.xcconfig`)
2. Set `CURRENT_PROJECT_VERSION = 1` as a starting value
3. Add a *pre-action* on the Release scheme (Edit Scheme → Build → Pre-actions) that overwrites the `xcconfig`'s `CURRENT_PROJECT_VERSION` line with the current timestamp before the build begins
4. Reference the xcconfig in the project's Configurations

Document the exact pre-action script in the project's build `CLAUDE.md` once you have it working — it's project-specific because it depends on the xcconfig's path.

---

## Verifying It Works

After setup, run a Debug build and a Release build (Product → Archive) and check:

- `git status` after a Debug build shows only the changes you actually made — no `Info.plist` modification
- `git status` after a Release build/archive shows `Info.plist` modified with the new `CFBundleVersion` (commit this when releasing)
- `BuildInfo.swift` does not appear in `git status` at all
- The About screen displays the marketing version, build timestamp, and SHA
- The displayed SHA gains a `+` if you have any uncommitted change

---

## Things This Template Does NOT Do

- Does not pin a specific timestamp format. `YYYYMMDDHHMM` is the default; a Unix epoch integer or any other monotonic format is equally valid. Pick one and document it in the project's overall directive.
- Does not handle CI-specific build identification. If a CI system (Xcode Cloud, GitHub Actions, Fastlane) builds the app, the CI environment's build number can replace or supplement the timestamp. Document the CI-specific behaviour in the project's build `CLAUDE.md`.
- Does not modify the marketing version (`CFBundleShortVersionString`). That stays under human control.
- Does not add a "copy build identifier to clipboard" affordance to the About screen. Consider adding one — it makes bug reports easier — but it is project-specific UX, not part of this template.

---

*Template status: Updated to standalone-script pattern (matches retrofit prompt).*
*Last updated: 2026-05-04.*
