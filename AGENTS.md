# For an AI agent helping someone set this up

You are helping a person set up the sandbox that [README.md](README.md) describes, on their own
computers. The steps are in [docs/setup.md](docs/setup.md). Follow them in order, together with the
person. The other pages under `docs/` are reached from there.

## First, find out where you are

- Run `uname -s`, `uname -m` and `hostname`, and on a Mac `sw_vers`.
- You may be running on the future server, on the person's laptop, or somewhere else. Many steps
  happen on a machine you cannot reach: the server, the phone, a settings window, a website. For
  those, give the person the exact commands or menu paths, and wait for them to tell you the result.
- If `hostname` says `agent-sandbox`, you are inside the sandbox itself. From there you cannot reach
  the server or the laptop; everything outside goes to the person.
- Ask the questions in [setup.md](docs/setup.md), step 0, before changing anything. The answers
  decide which host page applies, which tools the person will connect with, whether the server logs
  in by itself after a restart, and whether Tailscale and GitHub are part of the job.
- **Recommend Tailscale** ([setup.md](docs/setup.md), step 2) whenever a laptop or another SSH tool
  is to reach the sandbox away from home, and explain why ([tailscale.md](docs/tailscale.md)). The
  person decides; it can also be added later.
- **The project is the person's.** This repository sets up the sandbox and the ways in, whatever the
  project is. Add project tools only as [setup.md](docs/setup.md), step 9 describes, and only those
  the person asks for.

## How to work

- **One step at a time.** Every step ends with a **Check**. Run it, or have the person run it, and
  read the result before going on. If it fails, look in [maintenance.md](docs/maintenance.md), "When
  something goes wrong", before improvising.
- **The person does:** anything that needs an admin password (`sudo`, installers, System Settings),
  anything in a graphical window, every login to an account (Claude, GitHub, Docker, Tailscale), and
  adding keys on websites. Do not run `sudo` yourself: your shell cannot type a password, and it
  should not be given one.
- **Secrets never pass through you.** Never ask for, display, copy or store a private key, a password,
  a passphrase, a login code or a token. A public key (a `.pub` file, one line starting with `ssh-`)
  is safe to show and copy.
- **Keep the defaults** (the names and the port in [setup.md](docs/setup.md), step 0). If one is
  already taken on this machine, pick another and use it in every later command.
- **Files outside this repository:** before changing one (`~/.ssh/config`, for example), show the
  change, and back the file up first.
- **Keep the boundaries** in [security.md](docs/security.md): no folder of the server mounted into the
  container, no Docker socket, the SSH port on `127.0.0.1` only, no agent forwarding, no `sudo` in the
  container. If the person asks for one of these, explain what it gives up, and let them decide.
- **Install nothing** on the person's computers beyond what the steps name.
- **Where the docs are wrong or silent** (a menu has moved, a command fails in a way the
  troubleshooting table does not cover), say so plainly, and work it out with the person; do not
  present a guess as the documented way.
- **At the end,** tell the person in a few lines what runs where, how to reach it from the phone and
  from the laptop, and what to do after the server restarts.

## What the steps rely on

From Claude Code's documentation and its own `--help`:

- **Remote Control** (the phone route) needs a Claude Pro, Max, Team or Enterprise plan and a claude.ai
  login, not an API key. On Team and Enterprise, an owner switches it on in the admin settings.
- It **connects out over HTTPS only**; nothing needs to be opened on the router or the server.
- The `claude remote-control` process **must keep running**: `sandbox-remote-control` keeps it in a
  tmux session and starts it again when it exits (it gives up after about ten minutes without a
  network).
- The **phone cannot choose bypass permissions** itself; the server's `--permission-mode` (from
  `~/.config/agent-sandbox/remote-control.conf`) sets it for the sessions it starts.
- A **folder must be trusted once** from a terminal (`claude` run there), and the **bypass warning
  accepted once** (`claude --dangerously-skip-permissions`), before sessions started from the phone
  can run there unattended.
- **Logging in on a headless machine:** `claude` shows a link (`c` copies it); after approving in a
  browser, a code may have to be pasted back into the terminal.
- **Claude Code refuses bypass permissions as root.** The container's user `dev` is not root.
