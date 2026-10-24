# What the sandbox protects, and what it does not

Agents in the sandbox run with **bypass permissions**: they act without asking first. The sandbox is
there so that a mistake, or an agent led astray by something it read, stays inside one container
and cannot touch the server's own files or reach the keys on your laptop.

## The boundaries

| Between | What is open |
|---|---|
| the sandbox and the server's files | nothing: no folder of the server is mounted into the container |
| the sandbox and Docker | nothing: the Docker socket is not passed in, so the sandbox cannot start containers or reach the server through Docker |
| the sandbox and its own system | no `sudo`: agents can change the home folder (`/home/dev`), not the system |
| your laptop and the sandbox | an SSH login with a key, as the user `dev`; no passwords, no root login |
| the sandbox and your laptop's SSH keys | nothing: agent forwarding is refused by the container and switched off in the laptop's settings |
| the sandbox and VS Code's GitHub sign-in | switched off for git inside the container |
| the network and the sandbox's SSH port | the port listens on the server's loopback (`127.0.0.1`) only; from other machines it is reached through the server's own SSH login |
| the phone and the sandbox | Remote Control: the sandbox connects out to Anthropic; no port is opened for it |

## What it does not protect

- **The network is open.** Agents can reach the internet, and so could send out anything in the
  sandbox. Keep only what the work needs in there.
- **What is inside the sandbox is the agents'.** The Claude login (`~/.claude`), a GitHub key from
  `sandbox-git-setup`, any token or file you copy in: an agent can read, use or send each of them.
  Give the sandbox narrow GitHub access (a deploy key for one repository, or a separate account), and
  never your main keys.
- **The claude.ai account is a way in.** Whoever is logged in to it, on any phone or browser, can
  start sessions in the sandbox through Remote Control. Protect that account (and the e-mail or
  Google account that signs in to it) well.
- **The container is not a virtual machine on Linux.** Docker on Linux shares the server's kernel;
  a kernel flaw could let something out. On a Mac or on Windows, Docker Desktop runs containers
  inside its own Linux virtual machine, which adds a wall.
- **The `docker` group is root.** On Linux, any user in the `docker` group can become root on the
  server. Only the people who look after the server belong in it.
- **A server without FileVault** (automatic login on a Mac) gives its disk, the sandbox's volume
  included, to whoever takes it.

## Choices that keep these boundaries

When a change is asked for that would open one of them, weigh it first:

- **Mounting a folder of the server into the container** (`-v /Users/...:/...`) gives the agents
  that folder, to change or delete. Copy files in and out instead ([setup.md](setup.md), step 11).
- **Passing in the Docker socket** gives the agents the server.
- **Publishing the SSH port on all interfaces** (`-p 2222:22` instead of `-p 127.0.0.1:2222:22`)
  makes the sandbox reachable from the whole network it is on. The jump through the server's own SSH
  login, or Tailscale, does the same job without that.
- **A passphrase on the sandbox's GitHub key** would stop agents pushing unattended: every push then
  waits for a person.

## Going further

- **An outbound firewall:** Anthropic's reference dev container for Claude Code includes a firewall
  script that allows only the hosts the work needs. It can be adapted for this image (it needs the
  `NET_ADMIN` capability at `docker run`).
- **Claude Code's own sandbox** (`/sandbox`) adds a second layer inside the container, at some cost
  in convenience. See Claude Code's documentation on sandboxing.
