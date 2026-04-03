# Xcode to GitHub: The "Sync" Cheatsheet

Use these steps to push your local changes from your Mac up to GitHub.

### 1. Open the Commit Sheet
* Press **`Cmd + Option + C`** * (Or go to the top menu: **Integrate > Commit...**)

### 2. Select Your Changes (Staging)
* In the left-hand list, ensure the checkboxes are **Checked** for the files you want to send to GitHub.
* *Note: If no files are checked, you are "staging" nothing, and the process won't move forward.*

### 3. Write Your Message (The "Grey Button" Fix)
* **CRITICAL:** You **MUST** type a message in the large text box at the bottom (e.g., "Updated UI" or "Fixed bug").
* **If the "Commit" button is greyed out:** It is almost always because this text box is empty. Git requires a comment for every single save.

### 4. The "One-Click" Push
* Look at the very bottom of the window for the **Push to remote:** checkbox.
* Ensure it is **Checked** and shows **origin/main** (or your current branch).
* This ensures your code goes to GitHub immediately, rather than just staying on your Mac.

### 5. Finalize
* Click the blue **Commit [X] Files and Push** button in the bottom right corner.

---

## 💡 Quick Reminders
* **Is the button still grey?** Check that at least one file is checked in the list AND you have typed at least one character in the comment box.
* **Pulling Changes:** If you've been working on your Mac Mini and come back to the Mac Studio, go to **Integrate > Pull...** first to bring your latest work down before you start coding.
* **Embarrassing Notes:** If a file contains notes you don't want on GitHub, **Uncheck** that specific file in Step 2. It will stay on your Mac but won't be uploaded.
