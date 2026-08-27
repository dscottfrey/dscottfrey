# Claude Code — Universal Permissions Policy

**Scope:** Universal. Lives in `~/.claude/settings.json` so it applies to **every** project you launch Claude Code from, regardless of where the working directory is.

**Design goal:** Eliminate the approval prompts that are pure friction (the green/red Edit diffs, which you can't meaningfully review anyway) so that the prompts that *remain* — bash commands — are rare enough that you actually read them. Approval fatigue was causing missed review; lowering the noise floor to bash-only restores the prompt as real signal.

**Backstop:** Everything runs inside a git repo. Git is the real safety net, not the diff prompts. The one caveat: this policy is only as safe as "PWD is always a git repo." If you ever launch Claude Code in a non-repo scratch dir, you lose your undo — be aware of that the rare time it happens.

---

## What this policy does

| Category | Behavior | Why |
| --- | --- | --- |
| File edits/writes **in the working tree** | Auto-approved (no prompt) | You can't review Swift diffs meaningfully; git is the real backstop. This is the #1 fatigue source, removed. |
| Reads & searches | Already free by default | A read can't mutate anything. Claude Code treats `ls`, `cat`, `echo`, `pwd`, `head`, `tail`, `grep`, `find`, `wc`, `which`, `diff`, `stat`, `du`, `cd`, and read-only `git` forms as no-prompt in **every** mode. No config needed. |
| Benign filesystem commands | Auto-approved in `acceptEdits` | `mkdir`, `touch`, `mv`, `cp` etc. within the tree are handled by the mode. |
| Curated bash verbs (git writes, Xcode toolchain) | Auto-approved via allowlist | The high-frequency, opaque-but-trusted commands you'd blanket-approve anyway. |
| **Every other bash command** | **Prompts** | Novel commands, `rm`, scripts, network tools. Low volume now → you read them. |

---

## The settings block

Put this in `~/.claude/settings.json`. **Do not overwrite the whole file with `cat >`** if it already has content — merge these keys in by hand or via `/permissions`, so you don't wipe existing rules, hooks, or other settings.

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git *)",
      "Bash(xcodebuild *)",
      "Bash(swift *)",
      "Bash(xcrun *)",
      "Bash(plutil *)"
    ],
    "deny": []
  }
}
```

### Notes on each piece

- **`defaultMode: "acceptEdits"`** — auto-accepts file edits and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`, etc.) for paths in the working directory or any `--add-dir` additional directory. This is what kills the diff-approval reflex.
- **The `allow` list is deliberately short.** Start near-empty and let it grow (see "How to grow the allowlist" below). The five above are a reasonable Swift/Xcode seed — adjust to what you actually run.
- **`deny` is empty by default.** See "Optional out-of-tree backstop" for whether you want to add one. It is left out of the seed because it provides only partial protection (explained below) and prompts + git already cover the gap.

---

## Critical caveat: bash is NOT confined to PWD by permission rules

This is the one place the "only affect files within PWD" mental model has a gap, and it's worth understanding before you rely on it.

- The **Edit/Write/Read tools** are genuinely path-anchored. A rule like `Edit(/**)` (project-root-relative) cleanly means "within the tree."
- File-permission rules also catch *recognized* bash file commands (`cat`, `head`, `tail`, `sed`).
- **But** they do **not** catch a script that opens files on its own — e.g. a Python or Node script run via bash that reads/writes wherever it likes. Permission rules can't see inside an arbitrary subprocess.

**Consequence:** you cannot enforce "bash can only touch PWD" with permission rules alone. That's exactly why bash stays on prompts in this policy — your judgment is the control there, and you've said you can read bash. If you ever want *enforced* PWD confinement for bash (OS-level), that requires enabling **sandboxing** (see "If bash prompts still annoy you" below), which is a heavier setup left out of the default.

**Practical takeaway:** keep approving bash thoughtfully. The compound-command handling protects you here — an allow rule like `Bash(git *)` does **not** authorize `git status && rm -rf foo`; each subcommand must match independently, so anything chained on still prompts.

---

## How to grow the allowlist (the intended workflow)

You are **not** meant to enumerate every command up front. Start minimal and accrete:

1. When a bash command you trust prompts you, choose **"Yes, don't ask again."**
2. Claude Code writes the rule for you, in the correct space-separated form (e.g. `Bash(npm run build *)`), into the project's `.claude/settings.local.json`.
3. When you notice you've approved the same command across **multiple** projects, **promote** it: cut the rule from `.claude/settings.local.json` and paste it into the `allow` array in `~/.claude/settings.json`. Now it's universal.

Use `/permissions` inside Claude Code at any time to view every active rule and which settings file it came from.

### Pattern-writing quick reference

- `Bash(git *)` — any command starting with `git ` (the space enforces a word boundary).
- `Bash(git commit *)` — only `git commit ...`.
- The `:*` suffix is equivalent to a trailing ` *` **only at the end** of a pattern. `Bash(git:* push)` is broken — the colon is literal there. Write `Bash(git *)` instead.
- A single `*` spans multiple arguments including spaces.

### Vetted starting points

Anthropic publishes example settings at `anthropics/claude-code` → `examples/settings`. Treat them as **starting points to crib patterns from, not gospel** — Anthropic's own disclaimer is that they're community-maintained and may be incorrect, and you own the correctness of your config. Good source for battle-tested bash allow patterns for common toolchains.

---

## Optional out-of-tree backstop

If you want a *partial* guard against recognized file commands writing outside the tree, add to `deny`:

```json
"deny": [
  "Edit(//**)",
  "Write(//**)"
]
```

`//` is the **absolute-path** anchor (note: a single leading `/` means project-root-relative, NOT absolute — that's a common trap). This blocks the Edit/Write tools and recognized bash file-ops from touching anything outside the project.

**Why it's optional / why it's not in the seed:** it does **not** catch scripts that open files themselves (same subprocess gap as above). So it's a convenience guard for the common case, not a real boundary. Prompts + git already cover the gap. Add it if you like a visible "no" on out-of-tree writes; skip it to keep the policy minimal.

---

## If bash prompts still annoy you later

If, after living with this, the *bash* prompt volume is still too high and you'd rather trust an OS boundary than read them:

- Enable **sandboxing** (`sandbox` settings, Bash-tool only). With `autoAllowBashIfSandboxed: true` (the default), sandboxed bash runs without prompting because the OS boundary substitutes for the prompt — and this is the *only* mechanism that genuinely confines bash + its child processes to PWD.
- This is more setup and has macOS-specific behavior; verify against the current sandboxing docs before adopting.
- This is the deliberate "I never want a bash prompt and I'll trust the kernel" upgrade path. Don't reach for it until the lighter policy above proves insufficient.

**Avoid `bypassPermissions` as a daily driver.** It skips nearly all prompts including writes to `.git` and other dotfolders, and Anthropic explicitly scopes it to throwaway containers/VMs. On a project with fragile files (like an Xcode `project.pbxproj`) it removes the speed bump exactly where you'd want one.

---

## TL;DR

1. Drop the settings block into `~/.claude/settings.json` (merge, don't overwrite).
2. Diff prompts disappear; reads are already free; bash still prompts.
3. Hit "Yes, don't ask again" on trusted bash commands to grow the allowlist over time; promote the cross-project ones up to the universal file.
4. Commit often — git is the actual safety net.
