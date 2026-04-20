# IcarusVirtualHub — Remote Work Quick Reference

**Scenario:** You've been working on the desktop and need to switch to the laptop (or vice versa).

---

## Step 1 — Push from the Desktop

Do this before you leave the desktop.

### Via GitHub Desktop
1. Open **GitHub Desktop** — confirm `IcarusVirtualHub` is the current repository.
2. Any uncommitted changes will appear in the **Changes** tab. Write a summary and click **Commit to main**.
3. Click **Push origin** in the toolbar (or **Repository → Push**).

### Via Xcode
1. Open the project in **Xcode**.
2. **Integrate → Commit…** — review staged files, write a commit message, click **Commit**.
3. **Integrate → Push…** — confirm `origin/main` is selected, click **Push**.

---

## Step 2 — Pull to the Laptop

Do this before you start working on the laptop.

### Via GitHub Desktop
1. Open **GitHub Desktop** on the laptop — confirm `IcarusVirtualHub` is the current repository.
2. Click **Fetch origin** in the toolbar, then **Pull origin** when it appears.

### Via Xcode
1. Open the project in **Xcode** on the laptop.
2. **Integrate → Pull…** — confirm `origin/main`, click **Pull**.

---

## Golden Rules

- **Always push before switching machines.**
- **Always pull before starting work on a new machine.**
- Never work on both machines at the same time without syncing first — diverging commits create merge conflicts.
