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

## Committing Multiple Files with Different Messages (GitHub Desktop)

GitHub Desktop's commit message applies to **all checked files** at the time you click Commit — you cannot pre-assign different messages to different files. To commit files with separate messages, do it sequentially:

1. In the **Changes** tab, **uncheck** the file(s) you want to commit separately.
2. Write the message for the **checked** file(s) and click **Commit to main**.
3. The unchecked file(s) will still be there. **Check** them, write their message, and **Commit to main** again.
4. Push once when done, or after each commit — either works.

> Note: selecting a file in the list does not affect which files are included in the commit — only the **checkboxes** control that.

---

## Golden Rules

- **Always push before switching machines.**
- **Always pull before starting work on a new machine.**
- Never work on both machines at the same time without syncing first — diverging commits create merge conflicts.
