# Xcode to GitHub: The "Golden Path" Workflow

Follow these precise steps to ensure every new project on your Mac Studio or Mac Mini syncs perfectly without "Double URL" or permission errors.

## 1. Initial Project Creation
* In Xcode, go to **File > New > Project**.
* Select your template (App, Command Line Tool, etc.).
* **CRITICAL:** On the final "Save" dialog, ensure **"Create Git repository on my Mac"** is **Checked**.
* Click **Create**.

## 2. Linking to GitHub (The "No-Browser" Method)
Do not go to GitHub.com. Let Xcode’s API build the repository for you:
1. Open the **Source Control Navigator** (Press `Cmd + 2`).
2. Select the **Repositories** tab at the top of the left sidebar.
3. Find the **Remotes** folder for your project.
4. **Right-click** the **Remotes** folder and select **New "[ProjectName]" Remote...**
5. In the dropdown sheet, verify:
   * **Account:** `dscottfrey`
   * **Owner:** your name
   * **Visibility:** Public or Private
6. Click **Create**.

## 3. Daily Sync (Commit & Push)
To keep your local machine and GitHub in 1:1 sync with a single action:
1. Open the Commit sheet: `Cmd + Option + C` (or `Integrate > Commit...`).
2. Stage your changes and type a commit message.
3. **CRITICAL:** At the bottom of the window, check the box **"Push to remote: origin"**.
4. Click **Commit [X] Files and Push**.

---

## 🛠 Core Setup Checklist (If "New Remote" is missing)
If the menu options above are greyed out, verify these settings in **Xcode > Settings**:

* **Accounts:** `dscottfrey` must have a green status icon. 
* **Clone Using:** Must be set to **HTTPS** (not SSH).
* **Source Control > Git:** **Author Name** and **Email** must be filled in.
* **Source Control > General:** **"Include upstream changes in status bar"** must be **Checked**.
