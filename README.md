# agent-server-sandbox

An always-on sandbox for AI coding agents: a container on a spare computer, where agents work
without permission prompts, and which you reach remotely with the tools you prefer. The instructions
cover **VS Code with Claude Code** in most detail, and the **Claude app** on a phone.

```
phone: Claude app ──── HTTPS, through Anthropic ────┐  (Remote Control: the sandbox connects out)
                                                     │
laptop: VS Code ──ssh──> server ──ssh 127.0.0.1:2222──> container "agent-sandbox"
        (or a terminal,  (a spare Mac, Ubuntu or       Debian, user dev, Claude Code,
         another editor)  Windows machine, Docker)      ~/work in a Docker volume
```

## What you get

- **A container** with Claude Code, git, tmux and an SSH server, and nothing project-specific: what
  your project needs is added in one list. Its home folder, with your work, the Claude login and
  settings, is a Docker volume that survives rebuilds.
- **Ways in:**

  | Tool | From | Guide |
  |---|---|---|
  | VS Code with Remote-SSH and the Claude Code extension | a laptop | [docs/connect.md](docs/connect.md) |
  | the Claude app, or claude.ai/code in a browser | a phone, any browser | [docs/setup.md](docs/setup.md), steps 6–7 |
  | a terminal with `ssh`, or another editor or app that works over SSH | a laptop, a tablet | [docs/connect.md](docs/connect.md), section 6 |

- **From anywhere:** the Claude app works from anywhere as it is. For the SSH tools, the set-up
  encourages Tailscale, a free private network between your own devices
  ([docs/tailscale.md](docs/tailscale.md)); without it they work on the home network.
- **Boundaries:** no folder of the server is mounted in, the Docker socket is not passed in, there is
  no `sudo` inside, and SSH takes keys only, on the server's loopback. What that protects and what it
  does not: [docs/security.md](docs/security.md).

## What you need

- **A spare computer that can stay on and plugged in:** a Mac with Docker Desktop (the main path),
  Ubuntu with Docker Engine, or Windows with Docker Desktop (an outline so far).
- **A Claude Pro, Max, Team or Enterprise plan** for the Claude app route (Remote Control needs a
  claude.ai login; an API key does not work for it).
- **Recommended:** a free Tailscale account. **Optional:** VS Code on a laptop; a GitHub account or
  deploy key for the sandbox.

## Setting it up

Follow [docs/setup.md](docs/setup.md), step by step. Each step ends with a check.

**With an AI agent helping:** open this repository in Claude Code (or another coding agent) on the
server or on your laptop, and ask it to help you set up the sandbox. [AGENTS.md](AGENTS.md) tells it
how to go about it: what it can run itself, what it hands to you, and what it must never touch.

## Files

| Path | What it is |
|---|---|
| [docs/setup.md](docs/setup.md) | the set-up, step by step |
| [docs/host-mac.md](docs/host-mac.md) | the server on a Mac: Docker Desktop, staying awake, automatic login, Remote Login and Screen Sharing |
| [docs/host-ubuntu.md](docs/host-ubuntu.md) | the server on Ubuntu: Docker Engine, no sleep, SSH |
| [docs/host-windows.md](docs/host-windows.md) | the server on Windows: Docker Desktop with WSL 2 (an outline) |
| [docs/tailscale.md](docs/tailscale.md) | Tailscale from scratch: reaching the server from anywhere |
| [docs/connect.md](docs/connect.md) | a laptop: the login key, SSH settings, VS Code with Claude Code, other SSH tools |
| [docs/maintenance.md](docs/maintenance.md) | everyday commands, updates, backup, a fresh start, troubleshooting |
| [docs/security.md](docs/security.md) | what the sandbox protects, and what it does not |
| `host/run.sh` | on the server: builds the image and starts the container |
| `host/add-key.sh` | on the server: lets another device's public key in |
| `container/Dockerfile` | the image: Debian, SSH server, git, tmux, Claude Code |
| `container/packages.txt` | the system packages your project needs on top (empty to begin with) |
| `container/entrypoint.sh` | the container's start-up: keys in place, Remote Control started, SSH server |
| `container/sshd_sandbox.conf` | the SSH server: key login for `dev` only, no agent forwarding |
| `container/sandbox-remote-control.sh` | inside, as `sandbox-remote-control`: keeps Remote Control running in tmux |
| `container/sandbox-git-setup.sh` | inside, as `sandbox-git-setup`: the sandbox's own git identity and GitHub key |

## Licence

[CC0 1.0](LICENSE): dedicated to the public domain. Use it, change it and share it in any way, with
no conditions.
