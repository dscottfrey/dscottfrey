# IcarusVirtualHub — GitHub Sync Plan

**Date:** 2026-04-20  
**Author:** Scott Frey  
**Goal:** Push the IcarusVirtualHub Xcode project from the desktop Mac to a new private GitHub repo, then clone it to a laptop for mobile development.  
**Tools used:** Xcode · GitHub Desktop · github.com  

---

## Overview

This document captures the one-time setup required to get `IcarusVirtualHub` under version control on GitHub and accessible from a second machine. After completing this plan the project will live at `github.com/dscottfrey/IcarusVirtualHub` (private) and be fully cloneable to any machine you own.

---

## Phase 1 — Create the Private Repo on GitHub

1. Open a browser and go to [https://github.com/new](https://github.com/new).
2. Fill in the form:
   - **Repository name:** `IcarusVirtualHub`
   - **Description:** *(optional — add a short description if desired)*
   - **Visibility:** `Private` ✓
   - **Initialize this repository with:** leave all boxes **unchecked** (no README, no .gitignore, no license). You will be pushing an existing project, so a pre-initialized repo will cause a conflict.
3. Click **Create repository**.
4. Copy the HTTPS remote URL shown on the next page — it will look like:
   ```
   https://github.com/dscottfrey/IcarusVirtualHub.git
   ```
   You will need this URL in Phase 2.

---

## Phase 2 — Initialize Git and Push from the Desktop

Use **either** Xcode's built-in source control **or** GitHub Desktop. Both paths end at the same place; pick whichever feels more comfortable.

### Option A — GitHub Desktop (recommended, most straightforward)

1. Open **GitHub Desktop**.
2. Choose **File → Add Local Repository…**
3. Navigate to and select the root folder of the `IcarusVirtualHub` Xcode project (the folder that contains `IcarusVirtualHub.xcodeproj` or `.xcworkspace`).
4. GitHub Desktop will either:
   - **Recognize an existing git repo** → skip to step 5.
   - **Show a warning that no git repo exists** → click **"create a repository"** in the dialog. Accept the defaults (the project folder is already selected). Click **Create Repository**.
5. You should now see the repository listed in GitHub Desktop with all project files staged as the initial commit. If the files are staged, write a commit summary (e.g., `Initial commit`) and click **Commit to main**.
6. Click **Publish repository** in the top-right toolbar.
7. In the publish dialog:
   - Confirm the **Name** is `IcarusVirtualHub`.
   - Check **Keep this code private**.
   - Make sure the correct GitHub account (`dscottfrey`) is selected.
8. Click **Publish Repository**.

GitHub Desktop will push all commits to the remote. You can verify by visiting `https://github.com/dscottfrey/IcarusVirtualHub` in your browser.

---

### Option B — Xcode Source Control

1. Open `IcarusVirtualHub` in **Xcode**.
2. From the menu bar choose **Source Control → New Git Repositories…**
3. Xcode shows a list of projects. Make sure `IcarusVirtualHub` is checked, then click **Create**.
4. Xcode initializes a local git repo. All existing files are staged automatically.
5. Choose **Source Control → Commit…**, type an initial commit message (e.g., `Initial commit`), and click **Commit**.
6. Now add the GitHub remote. Open **Source Control → Repositories** (⌘ + 2 in the Source Control Navigator).
7. Right-click the **Remotes** section under `IcarusVirtualHub` and choose **Add Existing Remote…**
8. Paste the HTTPS URL you copied in Phase 1:
   ```
   https://github.com/dscottfrey/IcarusVirtualHub.git
   ```
   Click **Add**.
9. Choose **Source Control → Push…**, select the `origin/main` remote branch, and click **Push**.

---

## Phase 3 — Clone to the Laptop

Do this on the **laptop** after Phase 2 is complete.

### Via GitHub Desktop (recommended)

1. Open **GitHub Desktop** on the laptop.
2. Make sure you are signed in to the same GitHub account (`dscottfrey`). If not: **GitHub Desktop → Preferences → Accounts → Sign In**.
3. Choose **File → Clone Repository…**
4. Click the **GitHub.com** tab. Your private repos will be listed — find `IcarusVirtualHub`.
5. Choose a **Local Path** where you want the project to live on the laptop.
6. Click **Clone**.
7. Once cloned, choose **Open in Xcode** from GitHub Desktop's prompt, or open the `.xcodeproj` / `.xcworkspace` file directly in Xcode.

### Via github.com (alternative)

1. On the laptop, visit `https://github.com/dscottfrey/IcarusVirtualHub`.
2. Click the green **Code** button and copy the HTTPS URL.
3. Open **GitHub Desktop → File → Clone Repository… → URL tab**, paste the URL, choose a local path, and click **Clone**.

---

## Phase 4 — Day-to-Day Workflow (Desktop ↔ Laptop)

Once the repo is set up, use the following routine to stay in sync across machines:

| Action | How |
|--------|-----|
| **Before starting work** | GitHub Desktop → **Fetch origin** → **Pull** (or Xcode → Source Control → Pull) |
| **After finishing work** | GitHub Desktop → stage changes → **Commit** → **Push** (or Xcode → Source Control → Commit… → Push) |
| **Switching machines** | Always pull on the new machine before editing, and push before switching away |

> ⚠️ **Important:** Never work on both machines simultaneously without pushing/pulling first. Diverging commits will create merge conflicts.

---

## Verification Checklist

- [ ] Private repo `IcarusVirtualHub` visible at `github.com/dscottfrey/IcarusVirtualHub`
- [ ] All project files present in the repo (check the file tree on github.com)
- [ ] A `.gitignore` appropriate for Xcode exists (GitHub Desktop can generate one; Xcode does not add one automatically — see note below)
- [ ] Repo successfully cloned to laptop
- [ ] Project opens and builds on laptop without errors

---

## Note — Xcode .gitignore

Xcode projects generate build artifacts and user-specific files that should not be committed. If you did not get a `.gitignore` automatically, add one:

1. In GitHub Desktop, go to **Repository → Repository Settings… → Ignored Files**.
2. Paste the standard Xcode `.gitignore` content (available at [https://github.com/github/gitignore/blob/main/Swift.gitignore](https://github.com/github/gitignore/blob/main/Swift.gitignore)).
3. Click **Save**, then commit the `.gitignore` file.

Alternatively, when creating the repo on github.com (Phase 1), you can choose the **Swift** template from the **Add .gitignore** dropdown — but only if you initialize the repo with a README. If you do this, you will need to pull before pushing in Phase 2 (`git pull --rebase origin main`) to reconcile the histories.

---

*This document lives in the `dscottfrey` repo for reference. Last updated: 2026-04-20.*
