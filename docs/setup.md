# Setting it up

The steps, in order. Each step ends with a **Check**: do not go on until it passes. Steps marked
**(you)** need the person at the keyboard: an admin password, a click in a settings window, or a login.

The way in with the fewest steps, the Claude app through Remote Control, comes first (steps 1–7).
VS Code with Claude Code on a laptop follows in step 8; other tools that work over SSH use the same
set-up.

## 0. Before you start

Settle these first; the answers decide which pages and options apply.

1. **The server.** Which computer runs the sandbox, and what does it run?
   - On a Mac: `sw_vers` (the macOS version) and `uname -m` (`arm64` is Apple silicon, `x86_64` is
     Intel).
   - Free disk space: at least 20 GB is a comfortable start.
   - It has to stay on, on mains power, and connected to the network.
2. **The Claude plan.** Remote Control, the route from the Claude app, needs a Claude **Pro, Max,
   Team or Enterprise** plan. Claude Code must be logged in with that claude.ai account; an API key
   does not work for it. On Team and Enterprise, an owner has to switch Remote Control on in the
   organisation's Claude Code admin settings first.
3. **The tools to connect with**, and from where:
   - **VS Code with the Claude Code extension**, on a laptop: described in detail ([connect.md](connect.md)).
   - **The Claude app** on a phone, or **claude.ai/code** in a browser: steps 6–7.
   - **A terminal** with `ssh`, or **another editor or app that works over SSH**: the same SSH set-up
     as VS Code.
4. **Tailscale.** Is it in use already? If not, step 2 sets it up. It is recommended whenever a
   laptop is to reach the sandbox away from home; without it, that works on the home network only.
5. **After an unexpected restart** (a power cut, an update), should everything come back by itself?
   On a Mac that needs automatic login, which needs FileVault off: [host-mac.md](host-mac.md),
   section 4.
6. **The project.** What will agents build in the sandbox, and what does that need installed? (Step
   9.) Will they clone private repositories or push, and with which GitHub account? (Step 10.)

The names used throughout. Keep them unless one is already taken; if you change one, use the new
value in every later command.

| What | Name |
|---|---|
| the container, and its hostname | `agent-sandbox` |
| its volumes | `agent-sandbox-home`, `agent-sandbox-hostkeys` |
| its SSH port, on the server's loopback only | `127.0.0.1:2222` |
| the login key, on the computer you connect from | `~/.ssh/id_ed25519_agent_sandbox` |
| the SSH name of the server (in `~/.ssh/config`) | `sandbox-server` |
| the SSH name of the container (in `~/.ssh/config`) | `agent-sandbox` |

## 1. Prepare the server (you)

Follow the page for its system, then come back here:

- **Mac:** [host-mac.md](host-mac.md) (Docker Desktop)
- **Ubuntu:** [host-ubuntu.md](host-ubuntu.md) (Docker Engine)
- **Windows:** [host-windows.md](host-windows.md) (Docker Desktop with WSL 2; an outline)

**Check**, in a terminal on the server: `docker run --rm hello-world` prints "Hello from Docker!".

## 2. Tailscale (recommended) (you)

[tailscale.md](tailscale.md): an account, Tailscale on the server and on the laptop, and the server's
name on it. It takes a few minutes, and from then on every SSH tool on the laptop reaches the sandbox
from anywhere, and the server's desktop too.

Skipping it is fine for the Claude app, and for a laptop used only at home. It can be added at any
time later.

**Check:** [tailscale.md](tailscale.md), section 4.

## 3. Put this repository on the server

In a terminal on the server:

```sh
git clone https://github.com/videomusik/agent-server-sandbox.git
cd agent-server-sandbox
```

On a Mac without developer tools, the first `git` opens a dialog offering the Command Line Tools:
install them, then run the command again. Or download the repository as a ZIP from its GitHub page
(**Code > Download ZIP**) and unpack it.

**Check:** `ls host/run.sh container/Dockerfile` lists both files.

## 4. Build and start the container

In the repository folder, on the server:

```sh
bash host/run.sh
```

- The first build downloads Debian and Claude Code and takes a few minutes.
- Without a login key it says so and starts anyway; that is fine for now. A laptop's key comes in
  step 8. If the key from [connect.md](connect.md) already exists on this machine, pass it:
  `bash host/run.sh --key ~/.ssh/id_ed25519_agent_sandbox`.
- The container restarts by itself whenever Docker starts (`--restart unless-stopped`).

**Check:** `docker ps --filter name=agent-sandbox` shows it with a status of `Up`.

## 5. Log Claude Code in, inside the container (you)

Open a shell in the container, on the server:

```sh
docker exec -it -u dev agent-sandbox bash -l
```

The prompt becomes `dev@agent-sandbox:~$`. Then:

```sh
cd ~/work
claude
```

1. Choose to log in with your **Claude account** (the subscription), not an API key.
2. It shows a link (press `c` to copy it). Open it in a browser on any device, sign in and approve.
3. If the browser then shows a code, paste it into the terminal where `claude` asks for it.
4. When asked whether you trust the folder `/home/dev/work`, say yes.
5. Leave with `/exit`.

Then accept the "bypass permissions" warning once, so that sessions started from the Claude app can
run without asking before each action:

```sh
claude --dangerously-skip-permissions
```

Read the warning, accept it, and leave with `/exit`. What this mode does and does not protect:
[security.md](security.md).

This one login serves every way in: the Claude app's sessions, VS Code's Claude Code extension, and
`claude` in any terminal in the sandbox.

**For an agent helping:** the login link may be shared, but the code is a secret. The user pastes it
into the container's terminal, never into a chat.

**Check:** `claude` started again in `~/work` goes straight to its prompt without asking to log in
or about trust. Leave it with `/exit`.

## 6. Start Remote Control

Still in the container's shell:

```sh
sandbox-remote-control enable
sandbox-remote-control attach
```

- `enable` starts Claude Code's Remote Control server in a tmux session, and from now on it starts
  with the container. If it stops (for example after a long network outage), it starts again after a
  minute.
- `attach` shows its screen. Answer any question it asks the first time. Press the space bar for a QR
  code that a phone can scan. Detach with **Ctrl-b**, then **d**: the server keeps running.
- `sandbox-remote-control status` shows whether it runs, and the last lines of its screen.

Its sessions start in `~/work` with permission mode `bypassPermissions`. Change either in
`~/.config/agent-sandbox/remote-control.conf`, then `sandbox-remote-control restart`.

## 7. The Claude app, and claude.ai in a browser (you)

1. Install the **Claude** app on the phone and sign in with the **same** claude.ai account as in
   step 5.
2. Open the **Code** tab. The server appears under the name `agent-sandbox`, with a green dot while
   it is online. Open a session there (or scan the QR code from step 6).
3. Ask it something that only the sandbox can answer, for example "what is the hostname of this
   machine, and what is in ~/work?".

In a browser, the same sessions are at claude.ai/code.

**Check:** the answer names `agent-sandbox`.

Then test the restarts:

- `docker restart agent-sandbox` on the server. Within about a minute the app shows the server
  online again.
- Restart the server itself. If it logs in by itself (step 0, question 5), the app shows the server
  online again a few minutes after it is back. If it does not, that is expected: after a login on the
  server, Docker starts and so does everything else.

## 8. A laptop: VS Code with Claude Code, or another tool

[connect.md](connect.md): a login key on the laptop, the SSH settings, then VS Code with Remote-SSH
and the Claude Code extension, in detail. A terminal and other SSH tools use the same settings
(its section 6).

## 9. What your project needs

The image holds only what the sandbox itself needs (SSH, git, curl, tmux, Claude Code). Whatever the
project needs on top goes in one of two places:

- **System packages** (Debian package names): list them in `container/packages.txt` on the server,
  one per line, then rebuild the image ([maintenance.md](maintenance.md), "Updates"). There is no
  `sudo` inside, so agents cannot install these themselves; they can say which ones they need.
- **Tools that install into the home folder** (language runtimes and version managers often can, as
  can other agents' command-line tools): install them inside, as `dev`. An agent in the sandbox can
  do this itself. They live in the home volume and survive every rebuild.

**Check:** the project's own build or start command runs inside.

## 10. GitHub from inside the sandbox (optional)

The sandbox gets its own git identity and its own GitHub key; nothing comes from your own computer.
In the container's shell:

```sh
sandbox-git-setup
```

It asks for the GitHub username the commits are made as, writes `~/.gitconfig`, makes a key, and
prints its public half. Add that on GitHub in one of two ways:

- **One repository only (the narrower choice):** that repository's **Settings > Deploy keys > Add
  deploy key**, with **Allow write access** ticked if agents are to push. A key can be a deploy key
  of one repository only.
- **The whole account:** **Settings > SSH and GPG keys > New SSH key**. Everything that account can
  reach, the sandbox can then reach too. A separate GitHub account for the sandbox keeps that small.

The key has no passphrase, so that agents can use it unattended. Anyone who controls the sandbox can
push with it; [security.md](security.md).

**Check:** `ssh -o StrictHostKeyChecking=accept-new -T git@github.com` answers "Hi …! You've
successfully authenticated".

## 11. Getting files in and out

Nothing is shared with the server's folders. Files are copied:

- **From a laptop with SSH set up (step 8):** `scp agent-sandbox:work/<file> .` copies out,
  `scp <file> agent-sandbox:work/` copies in. In VS Code, drag files into its Explorer to copy them
  in, and right-click > **Download…** to copy them out.
- **On the server:** `docker cp <file> agent-sandbox:/home/dev/work/` copies in, but the copy belongs
  to root. Follow it with `docker exec -u root agent-sandbox chown dev:dev /home/dev/work/<file>`.
  `docker cp agent-sandbox:/home/dev/work/<file> .` copies out.
- **With git:** clone and push from inside (step 10).

Day-to-day commands, updates, backups and troubleshooting: [maintenance.md](maintenance.md).
