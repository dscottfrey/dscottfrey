# GitHub Sync Plan

**Date:** 2026-04-20  
**Author:** Scott Frey  
**Goal:** Push the IcarusVirtualHub Xcode project from the desktop Mac to a new private GitHub repo, then clone it to a laptop for mobile development.  
**Tools used:** Xcode · GitHub Desktop · github.com  

---

## Overview

This document captures the one-time setup required to get `IcarusVirtualHub` under version control on GitHub and accessible from a second machine. After completing this plan the project lives at `github.com/dscottfrey/IcarusVirtualHub` (private) and is fully cloneable to any machine you own.

There are two ways to do Phase 2 — pushing from the desktop to GitHub. **Pick one path and follow it exclusively.** Do not mix steps from both paths.

---

## Phase 1 — Create the Private Repo on GitHub

> ⚠️ **Only do Phase 1 if you are following Path B in Phase 2.** If you plan to use Path A (GitHub Desktop only), skip Phase 1 entirely — GitHub Desktop will create the remote repo for you.

1. Open a browser and go to [https://github.com/new](https://github.com/new).
2. Fill in the form:
   - **Owner:** `dscottfrey`
   - **Repository name:** `IcarusVirtualHub`
   - **Visibility:** `Private` ✓
   - **Add a README:** leave **Off**
   - **Add .gitignore:** leave as **No .gitignore**
   - **Add license:** leave as **No license**

   > It is critical that all three initialization options remain off. Adding any of them creates a commit on the remote that will conflict with your local repo when you try to push.

3. Click **Create repository**.
4. Note the repo URL: `https://github.com/dscottfrey/IcarusVirtualHub`

---

## Phase 2 — Push from the Desktop

### Path A — GitHub Desktop only (simpler, no Phase 1 needed)

Use this path if you have not yet created the repo on github.com.

1. Open **GitHub Desktop**.
2. Choose **File → Add Local Repository…**
3. Navigate to and select the root folder of the `IcarusVirtualHub` Xcode project (the folder containing `IcarusVirtualHub.xcodeproj`).
4. GitHub Desktop will show a warning that no git repository exists here. Click **"create a repository"** in the dialog, accept the defaults, and click **Create Repository**. GitHub Desktop will initialize git and automatically make an initial commit — you do not need to stage files or write a commit message manually.
5. Click **Publish repository** in the toolbar (top right).
6. In the publish dialog:
   - Confirm the **Name** is `IcarusVirtualHub`.
   - Check **Keep this code private**.
   - Confirm the account is `dscottfrey`.
7. Click **Publish Repository**. GitHub Desktop creates the private remote repo and pushes in one step.

---

### Path B — github.com first, then Xcode (used if you already created the repo in Phase 1)

Use this path if you have already created the empty repo on github.com.

1. Open **GitHub Desktop**.
2. Choose **File → Add Local Repository…**
3. Navigate to and select the root folder of the `IcarusVirtualHub` Xcode project.
4. GitHub Desktop will show a warning that no git repository exists here. Click **"create a repository"**, accept the defaults, and click **Create Repository**. GitHub Desktop automatically makes an initial commit.
5. At this point, do **not** click Publish Repository — it will fail because a repo with this name already exists on your account. Instead, open the project in **Xcode**.
6. In Xcode, open the **Source Control Navigator** (the branching-lines icon in the left sidebar, or press ⌘2).
7. Under **Repositories**, expand `IcarusVirtualHub` → right-click **Remotes** → choose **Add Existing Remote…**
8. Paste `https://github.com/dscottfrey/IcarusVirtualHub` and click **Add**.
9. From the menu bar choose **Integrate → Push…**

   > Note: In current versions of Xcode, the old "Source Control" menu has been renamed to **Integrate**.

10. The push dialog will show `origin/main (Create)`. This is expected — it means the branch does not yet exist on the empty remote and will be created by the push. Click **Push**.

---

## Phase 3 — Clone to the Laptop

Do this on the **laptop** after Phase 2 is complete.

1. Open **GitHub Desktop** on the laptop.
2. Confirm you are signed in as `dscottfrey`. If not: **GitHub Desktop → Settings → Accounts → Sign In**.
3. Choose **File → Clone Repository…**
4. Click the **GitHub.com** tab. Find `IcarusVirtualHub` in your repo list.
5. Set the **Local Path** to the **parent folder** where you want the project to live — for example `~/Documents/Code`. GitHub Desktop will create the `IcarusVirtualHub` subfolder automatically. Do not create the folder yourself beforehand.
6. Click **Clone**.
7. Open the project in Xcode to confirm all files are present and the project builds cleanly.

---

## Phase 4 — Day-to-Day Workflow (Desktop ↔ Laptop)

| Action | How |
|--------|-----|
| **Before starting work** | GitHub Desktop → **Fetch origin** → **Pull** |
| **After finishing work** | GitHub Desktop → stage changes → **Commit** → **Push** |
| **Switching machines** | Always pull on the new machine before editing, and push before switching away |

> ⚠️ Never work on both machines simultaneously without pushing and pulling first. Diverging commits will create merge conflicts.

---

## .gitignore

Add a `.gitignore` immediately after the initial push to prevent Xcode build artifacts and macOS metadata from accumulating in the repo.

In GitHub Desktop: **Repository → Repository Settings… → Ignored Files**, paste the following, then Save, Commit, and Push:

```
# macOS
.DS_Store

# Xcode user-specific files
xcuserdata/
*.xcuserstate
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# Xcode build output
build/
DerivedData/
*.hmap
*.ipa
*.dSYM
*.dSYM.zip

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods (if ever used)
Pods/

# Carthage (if ever used)
Carthage/Build/
```

> `.DS_Store` files are created by macOS Finder (not Xcode) and store folder view preferences. Xcode does not use them and they should always be ignored.

---

## Verification Checklist

- [ ] Private repo visible at `github.com/dscottfrey/IcarusVirtualHub`
- [ ] All project files present in the repo (check the file tree on github.com)
- [ ] `.gitignore` committed and present in the repo
- [ ] Repo successfully cloned to laptop
- [ ] Project opens and builds on laptop without errors

---

*This document lives in the `dscottfrey` repo for reference. Last updated: 2026-04-20.*
