# 06 — Swift / SwiftUI Idioms

The platform layer of the kit. This file captures the "do this, not that" rules that keep AI-generated Swift and SwiftUI code modern, idiomatic, and free of the common traps that AI coding assistants fall into when they reach for older API patterns from their training data.

Files 01–05 are platform-agnostic — they work for any project. This file is specifically for Swift / SwiftUI projects targeting iOS 26+ (or current macOS equivalents). Older targets need adjustments — see "Older Target Adjustments" at the end.

---

## Source and Freshness

This file is adapted from Paul Hudson's [SwiftAgents repository](https://github.com/twostraws/SwiftAgents), which is itself based on his article ["What to fix in AI-generated Swift code"](https://www.hackingwithswift.com/articles/281). Paul (HackingWithSwift / @twostraws) is one of the most-followed Swift educators; his rules reflect community consensus on modern Swift/SwiftUI idioms.

**Sync date:** 2026-05-04 (initial incorporation).

**Local divergences:** This file omits, modifies, or extends the upstream in several places. See "Local Divergences From Source" at the bottom for the full list, with rationale for each.

### Freshness Discipline

Paul's repo evolves as Swift and SwiftUI evolve. **Before relying on this file for a new Swift/SwiftUI project, do a freshness check:**

1. Visit https://github.com/twostraws/SwiftAgents and read the current `AGENTS.md`.
2. Compare against this file. Note any rules that are new, changed, or removed upstream.
3. For each delta, decide: adopt, reject (with rationale recorded in the divergences section), or defer.
4. Update this file's sync date to today and record any new divergences.

This pattern — **incorporated external sources must have a sync date and a deliberate refresh step before each use** — applies to anything in the kit that mirrors a third-party authoritative source. See HANDOFF for the broader meta-pattern.

---

## When This File Applies

This file applies if **all** of the following are true for the project:

- The project is built with Swift and SwiftUI as the primary UI framework.
- The minimum deployment target is iOS 26.0 (or roughly equivalent for macOS — whatever ships with Swift 6.2 / the modern Observation framework / the modern SwiftData APIs).
- The project does not require UIKit as a primary UI framework (using UIKit for narrow integrations is fine; building the app's UI in UIKit is out of scope here).

If your project targets older iOS or uses UIKit primarily, see "Older Target Adjustments" — many rules still apply, some don't.

---

## Core Targeting

- **iOS 26.0 or later.** This is the deliberate baseline. Newer APIs (the Tab API, modern ScrollView positioning, certain `@Observable` features) require it. Targeting older iOS is allowed but pulls a chunk of the rules below out of scope.
- **Swift 6.2 or later, with strict concurrency.** Modern Swift concurrency rules apply. Always choose `async/await` APIs over closure-based variants whenever both exist.
- **SwiftUI as the UI framework, backed by `@Observable` classes for shared data.**
- **No third-party frameworks without explicit owner approval** — see also `03_DEPENDENCY_FRAMEWORK.md` for the full dependency policy. Zero dependencies is the goal state.
- **No UIKit unless explicitly requested.** SwiftUI handles essentially all UI needs at iOS 26+. Reach for UIKit only when a specific, named need requires it (and surface that case before writing the code).

---

## Modern API Discipline

The meta-rule: **when there is a newer Apple API and an older one that does the same thing, use the newer one.** This is not stylistic — older APIs accumulate deprecation warnings, miss new features (gradient support in `foregroundStyle`, configurable shapes in `clipShape`, etc.), and increasingly diverge from how Apple's own apps look and behave.

Specific applications:

- **`foregroundStyle()` not `foregroundColor()`.** `foregroundStyle` accepts colors, gradients, materials, and hierarchical styles; `foregroundColor` is color-only and being phased out.
- **`clipShape(.rect(cornerRadius:))` not `cornerRadius()`.** `clipShape` is composable with any shape; `cornerRadius` is rectangle-only and locks you into one shape.
- **`Tab` API not `tabItem()`.** The new Tab API is Apple's current pattern for tab bars; `tabItem()` is the older modifier-on-View approach.
- **`NavigationStack` not `NavigationView`.** `NavigationView` is deprecated. Always use `NavigationStack` with `navigationDestination(for:)` for navigation.
- **Modern Foundation: `URL.documentsDirectory` not `FileManager.default.urls(for:in:).first`.** Use `appending(path:)` to add path components. The new URL API is shorter and harder to misuse.
- **`FormatStyle` not legacy `Formatter` subclasses.** Replace `DateFormatter`, `NumberFormatter`, `MeasurementFormatter` with `myDate.formatted(date: .abbreviated, time: .shortened)`, `myNumber.formatted(.number)`, etc. Parse with `Date(input, strategy: .iso8601)`. Never use `String(format: "%.2f", x)` for number formatting; use `Text(x, format: .number.precision(.fractionLength(2)))`.
- **Swift-native string APIs not Foundation bridges.** Prefer `replacing("a", with: "b")` over `replacingOccurrences(of: "a", with: "b")`.

---

## Concurrency

- **Always `async/await`, never closures, when both exist.** Closure-based APIs are the older variant; the kit's `02` rule "Document the journey, not the destination" still applies — if a closure-based API has to be used for a real reason, comment why.
- **Never use Grand Central Dispatch (`DispatchQueue.main.async`, etc.).** If you need that behaviour, use modern Swift concurrency (`Task { @MainActor in ... }`, `MainActor.run { ... }`).
- **Never `Task.sleep(nanoseconds:)`. Always `Task.sleep(for:)`.** The unit-typed variant is harder to misuse.
- **Assume strict concurrency rules.** Data-race-safe by default. Sendable conformance matters. If Claude Code is unsure whether a type should be Sendable, surface the question rather than guess.

---

## Observation and Shared State

- **`@Observable` classes, not `ObservableObject` + `@Published`.** `@Observable` (the macro) generates more granular observation; views only re-render when properties they actually read change.
- **`@Observable` classes must be marked `@MainActor`** unless the project has Main Actor default actor isolation. Flag any `@Observable` class missing this annotation.
- **Use `@State` for ownership, `@Bindable` and `@Environment` for passing.** Owning views hold state with `@State var model = MyModel()`. Child views that need to mutate that model use `@Bindable`. Cross-cutting state (auth, theme, settings) goes via `@Environment`.
- **Never use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`** unless they are unavoidable (legacy code, third-party integration where changing the architecture would be disruptive). Flag legacy uses for eventual migration.

---

## SwiftUI Specifics

- **Static member lookup over struct instances.** `.circle` not `Circle()`. `.borderedProminent` not `BorderedProminentButtonStyle()`. The static lookup form reads better and lets the compiler do more.
- **Buttons, not `onTapGesture`.** Use `Button` for any tappable thing. `onTapGesture` is only for cases where you need the tap location or the count of taps. Buttons get correct accessibility behaviour, hit testing, and focus management for free; `onTapGesture` does not.
- **Image-with-text on buttons:** `Button("Tap me", systemImage: "plus", action: myAction)` not a separate `Label` inside the button. Apple's preferred pattern.
- **`onChange` two-arg or no-arg variants only.** The single-parameter `onChange` was deprecated and replaced; use `onChange(of:initial:_:)` (two-arg) or the no-arg form depending on whether you need the new value.
- **`scrollIndicators(.hidden)` not `showsIndicators: false` in the ScrollView initializer.** The modifier form composes; the init parameter does not.
- **Modern ScrollView APIs.** Use `ScrollPosition` and `defaultScrollAnchor` for positioning and item-scroll. Avoid `ScrollViewReader`, which is the older pattern.
- **`ForEach(x.enumerated(), id: \.element.id)` not `ForEach(Array(x.enumerated()), id: \.element.id)`.** No need to materialise to an Array; the modern ForEach handles enumerated sequences directly.
- **`bold()` not `fontWeight(.bold)`** unless you specifically need a non-bold weight. The semantic modifier is shorter and clearer.
- **`ImageRenderer` not `UIGraphicsImageRenderer`** when rendering SwiftUI views to images.
- **Don't apply `fontWeight()` unless you have a specific reason.** Default fonts already have appropriate weights; overriding is usually noise.
- **Don't force specific font sizes; use Dynamic Type.** Hardcoding font sizes breaks accessibility (users who increase text size can't override the app's font). Use semantic font styles (`.title`, `.body`, etc.) which scale automatically.
- **Don't use `GeometryReader` if a newer alternative works.** `containerRelativeFrame()` and `visualEffect()` cover most cases that previously required `GeometryReader`. `GeometryReader` is large and changes layout participation in ways that are easy to misuse.
- **Never `UIScreen.main.bounds`** to read available space. Use the SwiftUI-native APIs (geometry from a parent, `containerRelativeFrame`, etc.).
- **Avoid `AnyView` unless absolutely required.** `AnyView` erases type information that SwiftUI uses for view identity and animation; performance and animation correctness suffer. Use `@ViewBuilder` and conditional content (`if`/`switch` inside a view's body) instead.
- **Avoid hardcoded padding and stack spacing values** unless explicitly requested. SwiftUI's defaults are tuned for Apple's design system; custom values usually look slightly off and don't adapt to platform differences.
- **No UIKit colors in SwiftUI.** Use `Color` not `UIColor`. SwiftUI's `Color` integrates with `foregroundStyle`, supports the modern color system, and is multi-platform.

---

## View Composition

- **Break views into separate `View` structs, not computed properties.** A `var headerView: some View { ... }` inside a parent view is a common pattern but is widely considered an anti-pattern: it does not get its own identity in SwiftUI's diffing, can't be previewed independently, and re-runs the parent's body whenever any of *its* state changes (cascading re-renders). Separate `struct HeaderView: View { ... }` files give you independent previewable, testable, and properly-identified views.

  *Trade-off note:* For trivially small subviews used in only one place, computed properties are sometimes argued to be cleaner. Default to separate structs and depart from this only with a deliberate decision.

- **Place view logic into a separate testable type when the logic is complex enough to warrant unit tests.** This is the spirit of "MVVM in SwiftUI" without dogmatically requiring a view-model for every view. For pure presentation views with no logic, the View struct is enough. For views with non-trivial logic (multi-step state machines, derived computations, transformations of incoming data), extract the logic into a separate `@Observable` class or a struct of pure functions, so it can be tested without instantiating the view.

  *Trade-off note:* The SwiftUI community is split on whether view models are needed; modern SwiftUI's `@State` + `@Observable` covers many cases that older guidance assumed needed a separate VM. The kit's position: extract when extraction enables tests; don't extract reflexively.

---

## Safety and Robustness

- **Avoid force unwraps (`!`) and force try (`try!`) unless the failure is unrecoverable.** Recoverable failures (network errors, file-not-found, missing optional values) deserve proper error handling. Force-unwrap only when the failure represents a programmer error so severe that crashing is the right behaviour, and comment why.
- **Filter user-input text with `localizedStandardContains()` not `contains()`.** `localizedStandardContains` does case-insensitive, diacritic-insensitive matching that respects the user's locale — what users actually expect from a "search" or "filter" affordance. `contains()` is byte-by-byte exact-match and produces the wrong behaviour.

---

## Localisation

- **If the project uses `Localizable.xcstrings`,** prefer symbol-key strings (e.g., `helloWorld` rather than `"Hello, world!"`) with `extractionState` set to `manual`. Access via the generated symbols (`Text(.helloWorld)`). When a new key is added, offer to translate it into all languages the project supports.
- **No bare string literals in user-facing UI** if the project is localised. Every visible string flows through the catalog.

---

## Project Structure

- **Folder layout follows app features**, not technical layers. Don't make a top-level `Views` / `Models` / `Controllers` split. Group by feature: `Onboarding/`, `Reading/`, `Settings/`. Inside each, the views, models, and supporting types live together. (This is the SwiftUI-community-standard pattern.)
- **One type per Swift file.** Don't put multiple structs/classes/enums in one file unless they are tightly related (e.g., a struct and its inner types). Cross-references with `02`'s "One File, One Job" — they say the same thing.
- **Strict naming conventions for types, properties, methods, and SwiftData models.** PascalCase for types, camelCase for properties/methods, descriptive names. Apple's API Design Guidelines apply.
- **Comments and documentation comments as needed.** This intersects `02`'s "Comments Are Part of the Deliverable" — that section is the source of truth; this is a reminder.
- **Write unit tests for core application logic.** UI tests only when unit tests are not possible. Tests of pure logic types (extracted per "View Composition" above) are cheap and reliable; tests that drive the view layer are expensive and flaky.
- **Never commit secrets** — API keys, tokens, credentials. The kit's HANDOFF has a deferred topic on broader secrets-handling discipline; for now: secrets live outside the repo, period.

---

## SwiftData Conditional Rules

**Apply only if the project uses SwiftData with CloudKit sync.** SwiftData without CloudKit does not have these constraints. If your app does not use SwiftData at all, skip this section.

CloudKit imposes constraints on SwiftData that the SwiftData API does not enforce at compile time but will surface as runtime crashes or sync failures:

- **Never use `@Attribute(.unique)`.** CloudKit does not support unique constraints; the model will not sync.
- **Model properties must have default values or be marked optional.** CloudKit deserialization can hand the app a partially-populated record; properties without defaults that are not optional will crash on decode.
- **All relationships must be marked optional.** Same reason.

---

## Xcode MCP (Conditional)

**Apply only if the Xcode MCP server is installed and configured for the project.**

The Xcode MCP gives Claude Code structured access to Xcode itself: documentation lookup, builds, build logs, SwiftUI previews, snippet execution. When available, prefer its tools over generic alternatives:

- `DocumentationSearch` — verify API availability and correct usage before writing code (the single biggest source of AI-generated Swift bugs is calling APIs that don't exist; use this proactively)
- `BuildProject` — build the project after making changes to confirm compilation succeeds
- `GetBuildLog` — inspect build errors and warnings
- `RenderPreview` — visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues` — check for issues visible in the Xcode Issue Navigator
- `ExecuteSnippet` — test a code snippet in the context of a source file
- `XcodeRead`, `XcodeWrite`, `XcodeUpdate` — prefer these over generic file tools when working with Xcode project files

If the Xcode MCP is not installed and the project would benefit (i.e., this is a Swift/SwiftUI project), surface that to the owner — installing it is a one-time setup that meaningfully reduces AI-generated-code errors.

---

## Older Target Adjustments

If the project targets older iOS than this file assumes (iOS 26+), some rules still apply and some don't. Quick guide:

| Rule | Required iOS |
|---|---|
| `@Observable` macro | iOS 17+ |
| `NavigationStack` | iOS 16+ |
| `Tab` API (new) | iOS 26+ |
| Modern ScrollView APIs (`ScrollPosition`, `defaultScrollAnchor`) | iOS 17+ |
| `FormatStyle` | iOS 15+ |
| `URL.documentsDirectory` | iOS 16+ |
| `foregroundStyle` | iOS 15+ |
| Modern `clipShape(.rect(cornerRadius:))` | iOS 17+ |
| `containerRelativeFrame` | iOS 17+ |

For projects targeting iOS 16 or earlier, drop the rules that require newer iOS and substitute the older equivalents — but the *spirit* of the rules (prefer the newer API, prefer typed APIs over stringly-typed ones, prefer SwiftUI-native over UIKit bridges) still applies.

---

## Local Divergences From Source

The following choices differ from the upstream `SwiftAgents/AGENTS.md` and are deliberate:

- **Omitted: "Role: Senior iOS Engineer" framing.** The kit's existing `CLAUDE.md` templates and `02_DEVELOPMENT_PHILOSOPHY.md` already establish Claude's role and communication style (including "explain in plain English to a non-developer owner"). The "Senior Engineer" persona conflicts with that audience-awareness — kept the substantive technical rules, dropped the persona.
- **Omitted: SwiftLint section.** The owner does not currently use SwiftLint. Most of what SwiftLint would catch is covered by the rules in this file. HANDOFF tracks SwiftLint adoption as a deferred decision; if adopted, this section gets added back.
- **Modified: View composition rules.** Upstream states "do not break views up using computed properties; place them into new View structs instead" and "place view logic into view models or similar, so it can be tested" as flat rules. This file states the same as the default but flags the trade-offs (computed properties OK for trivial one-use subviews; view-models only when extraction enables testing rather than reflexively). Reflects ongoing community debate.
- **Added: Older Target Adjustments section.** Upstream assumes iOS 26+ unconditionally; the kit recognises that some projects may target older iOS and surfaces which rules still apply.
- **Added: Source and Freshness section.** Upstream evolves; this file pins the sync date and prescribes a refresh discipline before each new project's use.
- **Added: Rationale to most rules.** Upstream often states the rule without explaining why. The kit's `04_DIRECTIVE_WRITING.md` requires every decision to carry its rationale; this file follows that pattern even where the upstream is bare.

---

*File status: First incorporation from SwiftAgents 2026-05-04. Adapted for kit conventions.*
*Last updated: 2026-05-04.*
