# Linux Job Control Guide (Background Processes)

When you press `Ctrl + Z`, you are **suspending** a running process and pushing it into the background in a "sleep" state. Here is how to manage these jobs using the terminal's built-in Job Control.

## 1. List Background Jobs
To see all suspended or background processes in your current terminal window:
```bash
jobs
```
*Example Output:*
```text
[1]  - suspended  agy
[2]  + suspended  top
```
- `[1]`, `[2]`: The Job ID. You use this number to control the process.
- `+`: The default job that will be affected if you use `fg` or `bg` without specifying an ID.
- `suspended`: The process is paused (via `Ctrl + Z`).
- `running`: The process is currently executing in the background.

## 2. Basic Controls

Once you know the Job ID (e.g., `1`), use the following commands:

### Bring to Foreground (Resume on screen)
```bash
fg %1
```
*(Resumes job `[1]` and brings it back to the main terminal so you can interact with it normally).*

### Run in Background (Resume silently)
```bash
bg %1
```
*(Resumes the suspended job, but keeps it running in the background, leaving your terminal free for other commands).*

### Terminate the Process
```bash
kill %1
```
*(Closes the job completely. If it refuses to close, force kill it using `kill -9 %1`).*

## 3. Start in Background Immediately
If you want to run a command in the background right from the start (without needing `Ctrl + Z`), just append `&` to the end of the command:
```bash
agy &
```
The process will immediately start as `running` in the background, instantly freeing your terminal for other tasks.
