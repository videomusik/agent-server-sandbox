# The server: Windows with Docker Desktop (an outline)

⚠️ This page is an outline. It follows Docker's and Microsoft's documentation, but has not yet been
run end to end with this repository. An agent following it should check each step's result
before going on, and say where it differs.

Every step is done on the Windows machine, by a user with administrator rights. Then go back to
[setup.md](setup.md), step 2. Run its steps 3 and 4 in the **WSL Ubuntu** shell (section 1).

## 1. WSL 2 and Docker Desktop

1. In PowerShell **as administrator**: `wsl --install`, then restart. This installs WSL 2 and an
   Ubuntu shell; open **Ubuntu** from the Start menu once and choose a user name and password.
2. Install Docker Desktop for Windows from docker.com. Keep **Use WSL 2 instead of Hyper-V**.
3. In Docker Desktop's **Settings**:
   - **General:** **Start Docker Desktop when you sign in to your computer**.
   - **Resources > WSL integration:** switch it on for the Ubuntu distribution.
4. Docker Desktop's licence terms are the same as on a Mac ([host-mac.md](host-mac.md), section 2).

**Check**, in the Ubuntu shell: `docker run --rm hello-world` prints "Hello from Docker!".

Clone this repository **inside** the Ubuntu shell (its own home folder, not `/mnt/c/...`), and run
`bash host/run.sh` there. The repository's `.gitattributes` keeps the scripts' line endings as Linux
needs them; a copy edited with a Windows editor that adds CRLF breaks the container's start-up.

## 2. Never sleep, and after a restart

In PowerShell as administrator:

```powershell
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
# a laptop: do nothing when the lid closes, on mains power
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
```

Docker Desktop starts only when its user signs in. To come back after a restart without anyone at
the machine, sign in automatically with Microsoft's Sysinternals **Autologon**. Like automatic login
on a Mac, it trades away protection if the machine is taken; BitLocker plus a sign-in at the machine
after each restart is the other choice.

Windows Update restarts the machine for updates. Set **Settings > Windows Update > Advanced options
> Active hours**, and check after update days that the sandbox is back.

## 3. Login keys on Windows

If VS Code runs on this Windows machine itself, make the login key in PowerShell (Windows has an
OpenSSH client):

```powershell
ssh-keygen -t ed25519 -C agent-sandbox-login -f $env:USERPROFILE\.ssh\id_ed25519_agent_sandbox
```

and pass its public half from the Ubuntu shell:
`bash host/run.sh --key /mnt/c/Users/<you>/.ssh/id_ed25519_agent_sandbox`. The container's port is
then `127.0.0.1:2222` on Windows itself: in `~/.ssh/config` (`C:\Users\<you>\.ssh\config`), the
`agent-sandbox` entry from [connect.md](connect.md) without the `ProxyJump` line.

## 4. Reaching it from another computer

- **SSH (for the jump to the sandbox):** in PowerShell as administrator:

  ```powershell
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  Start-Service sshd
  Set-Service -Name sshd -StartupType 'Automatic'
  ```

  For a user who is an administrator, Windows' SSH server reads keys from
  `C:\ProgramData\ssh\administrators_authorized_keys`, not from the user's own `.ssh` folder. That
  file must be readable only by Administrators and SYSTEM:

  ```powershell
  icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
  ```

- **The desktop:** Remote Desktop (**Settings > System > Remote Desktop**) needs Windows Pro or
  higher. Clients: Microsoft's Windows App on a Mac, Remote Desktop Connection on Windows.
