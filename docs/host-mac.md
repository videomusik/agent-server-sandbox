# The server: a Mac with Docker Desktop

A spare Mac, a laptop in particular, made into an always-on server for the sandbox. Every step here
is done on that Mac, by someone with its admin password. Then go back to
[setup.md](setup.md), step 2.

## 1. Check the Mac

```sh
sw_vers
uname -m
df -h /
```

- **Docker Desktop supports the current major macOS release and the two before it.** Compare
  `sw_vers` with the system requirements on Docker's "Install Docker Desktop on Mac" page. If this
  Mac's macOS is older and cannot be updated, see section 7.
- `uname -m` says which Docker Desktop to download: `arm64` is Apple silicon, `x86_64` is Intel.
- Keep at least 20 GB free.

## 2. Docker Desktop

1. Download Docker Desktop for Mac from docker.com, the build for this Mac's chip, open the `.dmg`
   and drag Docker to Applications.
2. Start Docker from Applications. Accept the terms, choose **Use recommended settings** (it asks
   for the admin password), and skip the Docker account sign-in: it is not needed.
3. In Docker Desktop's **Settings**:
   - **General:** tick **Start Docker Desktop when you sign in to your computer**.
   - **Resources > Advanced:** the CPU, memory and disk the containers may use. On a Mac that does
     nothing else, about half of its memory and CPUs is a good start.
4. Docker Desktop is free for personal use, education, non-commercial open source and small
   businesses (Docker's terms give the limits). Otherwise it needs a paid subscription; OrbStack and
   Colima (section 7) are alternatives.

**Check**, in Terminal: `docker run --rm hello-world` prints "Hello from Docker!".

Docker Desktop updates itself when asked. An update restarts its engine, and the sandbox container
starts again with it.

## 3. Keep it awake

A Mac that sleeps drops the phone's connection and stops the agents.

- **System Settings > Battery > Options…** (on a desktop Mac: **Energy**): turn on **Prevent
  automatic sleeping on power adapter when the display is off**, and set **Wake for network access**
  to **Only on Power Adapter** or **Always**.
- Or in Terminal, for when it runs on the charger (`-c`):

  ```sh
  sudo pmset -c sleep 0 disksleep 0 displaysleep 10
  ```

  `pmset -g` then shows `sleep 0`. The display may still turn off; that is fine.
- **The lid.** A MacBook sleeps when its lid is closed, unless an external display is attached.
  Leaving the lid open (with the brightness turned down) is the simplest. To run it closed:

  ```sh
  sudo pmset -a disablesleep 1
  ```

  This also stops it sleeping on battery, so keep it on the charger, and give it room to lose heat.
  `sudo pmset -a disablesleep 0` undoes it.
- **The battery.** A laptop on the charger all the time ages its battery. Keep macOS's battery
  health management (**Battery > Battery Health**, ⓘ) switched on, and check now and then that the
  battery is not swelling.

## 4. After a restart: automatic login, or FileVault

Docker Desktop is an app: it starts only when its user is logged in. After a restart (a power cut
that emptied the battery, an update), nothing runs until someone logs in.

Choose one:

- **Comes back by itself:** **System Settings > Users & Groups > Automatically log in as** this
  user. macOS offers this only with **FileVault off** (**Privacy & Security > FileVault**). The
  trade-off: whoever takes the Mac can read its disk, including the sandbox's volume with its Claude
  login. Still require a password to unlock the screen (**Lock Screen** settings).
- **FileVault stays on:** after an unplanned restart, someone logs in at the Mac. For a planned
  restart, `sudo fdesetup authrestart` restarts it without asking for the FileVault password once.

Either way, stop macOS from restarting itself for updates: **System Settings > General > Software
Update > Automatic updates** (ⓘ): turn off **Install macOS updates**, keep **Install Security
Responses and system files** on, and install macOS updates by hand when someone is around.

## 5. Remote Login and Screen Sharing

So that the Mac can be looked after from another computer, and so that a laptop can reach the
sandbox through it ([connect.md](connect.md)).

1. **System Settings > General > Sharing:**
   - **Remote Login** on. Under ⓘ, allow only this user. This is SSH.
   - **Screen Sharing** on, if you want its desktop from another Mac.
   - The **Local hostname** at the bottom of that page (for example `Old-MacBook-Pro.local`): the
     name other computers at home use for it. `scutil --get LocalHostName` prints it without the
     `.local`.
2. **The desktop from another Mac:** in Finder, **Go > Connect to Server…**, enter
   `vnc://<local hostname>`, and log in as the server's user. (Microsoft's Windows App is for Windows
   and Linux desktops; between two Macs this is the built-in way.)
3. **From away:** both work over Tailscale too ([tailscale.md](tailscale.md)); use the Mac's
   Tailscale name in place of the local hostname.

**Check**, from another computer at home: `ssh <server user>@<local hostname>` asks for the
password (or uses a key) and logs in.

## 6. Mac gotchas

- **Docker must be running.** Every `docker` command fails with "Cannot connect to the Docker daemon"
  or "failed to connect to the docker API" while Docker Desktop is not running. `open -a Docker`
  starts it, also from an SSH login, as long as the user is logged in at the Mac.
- **`docker` over SSH.** In an interactive SSH login (`ssh sandbox-server`, then the command),
  `docker` is found. A one-shot command (`ssh sandbox-server docker ps`) gets a shorter PATH and says
  "command not found"; give the full path there (usually `/usr/local/bin/docker`; `which docker` in
  Terminal at the Mac shows it).
- **"error getting credentials … User interaction is not allowed"** when building over SSH: Docker
  asks the login keychain, which is locked in an SSH session. Run
  `security unlock-keychain ~/Library/Keychains/login.keychain-db` in that session first, or build in
  Terminal at the Mac (or over Screen Sharing).

## 7. If Docker Desktop does not fit

`host/run.sh` works with any engine whose `docker` command works.

- **OrbStack:** a lighter Docker engine for Mac, free for personal use. Check its macOS
  requirement. It must be running, like Docker Desktop (`open -a OrbStack`); set it to start at
  login.
- **Colima:** free and open source, through Homebrew. It runs on older macOS releases too:

  ```sh
  brew install colima docker
  colima start --cpu 2 --memory 4
  brew services start colima
  ```

  The last line starts it again at every login.
- **Ubuntu instead of macOS,** on an Intel Mac that macOS no longer updates: install Ubuntu on it and
  follow [host-ubuntu.md](host-ubuntu.md). Docker then starts at boot, with no login needed.
