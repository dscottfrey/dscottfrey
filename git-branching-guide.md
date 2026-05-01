# Git Branching Guide

A practical reference for using branches with GitHub.com, GitHub Desktop, Xcode, and Claude Code.

## The Mental Model

Think of your `main` branch as the "known good" version of your app. A **branch** is a parallel timeline that splits off from `main` at a specific commit. You can make as many commits as you want on that branch without affecting `main` at all. If the experiment works, you **merge** the branch back into `main`. If it's a dead end, you just delete the branch and `main` is untouched — like it never happened.

A few key truths that trip people up:

- A branch is just a lightweight pointer to a commit, not a copy of your files. Switching branches changes what's in your working folder almost instantly.
- You can only be "on" one branch at a time. Whatever branch you're on is what receives your commits.
- Branches live both locally (on your Mac) and on GitHub (the remote). They're synced when you push/pull, but they're separate things until then.
- Your working directory reflects whichever branch is currently checked out. When you switch branches, the files in Finder/Xcode literally change to match that branch.

## The Typical Lifecycle

Here's the flow you'll follow:

1. Start on `main`, make sure it's clean (all changes committed) and up to date.
2. Create a new branch (call it something like `experiment-new-architecture` or `try-swiftdata`).
3. Switch to that branch — now you're working in the parallel timeline.
4. Code, commit, code, commit. Push to GitHub periodically as backup.
5. **Decision point**: did it work?
   - If yes → merge the branch back into `main`, then delete the branch.
   - If no → just delete the branch. `main` was never touched.

## Mechanics in GitHub Desktop

This is where you'll do almost everything. GitHub Desktop handles branches really cleanly.

### Before You Branch

Commit or discard any pending changes on `main`. Branches don't like to be created when you have uncommitted work (it'll either bring the changes with you or complain).

### Create the Branch

Click the "Current Branch" dropdown at the top of the window. Click "New Branch." Name it something descriptive — kebab-case is conventional, like `try-new-data-layer`. It'll ask what to base it on; pick `main`. Click "Create Branch." You're now on the new branch automatically.

### Publish It to GitHub

Click "Publish branch" (top right). This pushes the branch to GitHub.com so it exists as a backup. Do this early — if your laptop dies mid-experiment, you don't want to lose the work.

### Work Normally

Open Xcode, open Claude Code, do whatever you do. Every commit you make in GitHub Desktop now goes onto your experimental branch. Push periodically with the "Push origin" button.

### Switch Back to Main to Compare

Click the "Current Branch" dropdown, pick `main`. Your files in Finder/Xcode will revert to the `main` state. Switch back to your branch the same way. (Xcode sometimes needs a moment or a clean build when files change underneath it.)

## When the Experiment Succeeds — Merging Back

You have two options, and the second is recommended:

### Option A — Merge Locally in GitHub Desktop

Switch to `main`. Go to the menu: Branch → "Merge into current branch." Pick your experimental branch. Push.

### Option B — Pull Request on GitHub.com (Recommended)

With your experimental branch pushed, go to your repo on GitHub.com. It'll usually show a yellow banner offering to "Compare & pull request." Click it, write a quick description of what changed and why, and create the PR. Then you can review the diff one more time, and click "Merge pull request." This gives you a clean record on GitHub of what the experiment was and when it landed. After merging, click "Delete branch" on GitHub, then back in GitHub Desktop pull `main` and delete your local copy of the branch (Branch menu → Delete).

The PR approach is overkill for a solo project in a strict sense, but it builds a great paper trail and the diff view on GitHub is genuinely useful for a final sanity check before merging.

## When the Experiment Fails — Abandoning

This is the beautiful part. Switch to `main` in GitHub Desktop. Go to Branch menu → Delete. It'll ask if you also want to delete the remote copy on GitHub — say yes. Done. `main` is exactly as you left it, and the dead-end code is gone (or rather, archived in git history if you ever want to dig it up).

## Tips for This Toolchain

**Xcode** caches things and can get cranky when files change under it via branch switching. If something looks weird after switching branches, do Product → Clean Build Folder (⇧⌘K).

**Claude Code** operates on whatever files are currently in your working directory, so it'll automatically be working on whichever branch is checked out. No special configuration needed — but be aware that if you ask Claude Code to make changes, those changes land on your current branch. Make sure you're on the experimental branch before turning it loose on big changes.

## Terminal Equivalents

If you ever want to use the terminal:

| Action | Command |
|---|---|
| Create and switch to new branch | `git checkout -b try-new-thing` |
| Switch back to main | `git checkout main` |
| Merge branch into current branch | `git merge try-new-thing` |
| Delete a branch (after merge) | `git branch -d try-new-thing` |
| Force-delete an unmerged branch | `git branch -D try-new-thing` |
| Push a new branch to GitHub | `git push -u origin try-new-thing` |
| See current branch and status | `git status` |
| List all branches | `git branch -a` |
