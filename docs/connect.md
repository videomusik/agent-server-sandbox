# A laptop: VS Code with Claude Code, or another SSH tool

How a laptop reaches the sandbox. The route described in detail is **VS Code with Remote-SSH and the
Claude Code extension**: VS Code opens the sandbox's folders and terminals as if it were a remote
server, and Claude works in there. A terminal with `ssh`, and any other editor or app that works
over SSH, use the same set-up (section 6). The Claude app needs none of this; it uses Remote Control
([setup.md](setup.md), steps 6–7).

The sandbox's SSH port listens only on the server's loopback (`127.0.0.1:2222`). A laptop therefore
reaches it in two hops: an SSH login to the server, then from there into the container. SSH does
both in one command (`ProxyJump`), and VS Code follows it.

```
laptop ──ssh──> server (its own SSH login) ──ssh 127.0.0.1:2222──> agent-sandbox
```

`<server name>` below is the server's **Tailscale name** if Tailscale is set up
([tailscale.md](tailscale.md)); then all of this works at home and away. Without Tailscale it is the
server's name on the home network (for example `Old-MacBook-Pro.local`), and it works at home only.

Steps 1–4 happen on the **laptop**, except where a step says otherwise.

## 1. The login key

```sh
ssh-keygen -t ed25519 -C agent-sandbox-login -f ~/.ssh/id_ed25519_agent_sandbox
```

- It asks for a passphrase. On a laptop, give one: the private key is then useless to whoever copies
  it. On a Mac, the keychain remembers the passphrase (section 3).
- This makes two files: `~/.ssh/id_ed25519_agent_sandbox`, the **private** key, which never leaves
  the laptop and is never pasted anywhere, and `~/.ssh/id_ed25519_agent_sandbox.pub`, the **public**
  key, which is safe to copy.

## 2. Let the key in, twice

**a) The server's own SSH login** (the first hop). The server's SSH must be on: Remote Login on a Mac
([host-mac.md](host-mac.md), section 5), `openssh-server` on Ubuntu, OpenSSH Server on Windows (an
administrator's keys go elsewhere there: [host-windows.md](host-windows.md), section 4).

```sh
ssh-copy-id -i ~/.ssh/id_ed25519_agent_sandbox.pub <server user>@<server name>
```

This asks for the server user's password once.

**b) The container** (the second hop). Copy the public key to the server and add it there:

```sh
scp ~/.ssh/id_ed25519_agent_sandbox.pub <server user>@<server name>:
ssh <server user>@<server name>
```

Then, in that login on the server, in the folder where [setup.md](setup.md) step 3 put this
repository:

```sh
bash host/add-key.sh ~/id_ed25519_agent_sandbox.pub
exit
```

It answers "key added". (If the key already existed on the server when the container was first
created with `--key`, it is in already.)

## 3. The SSH settings

Add two entries to `~/.ssh/config` on the laptop (make the file if there is none; back it up first
if there is: `cp ~/.ssh/config ~/.ssh/config.bak`). Put in the real server name and user:

```
Host sandbox-server
    HostName <server name>
    User <server user>
    IdentityFile ~/.ssh/id_ed25519_agent_sandbox
    IdentitiesOnly yes
    ForwardAgent no

Host agent-sandbox
    HostName 127.0.0.1
    Port 2222
    User dev
    ProxyJump sandbox-server
    IdentityFile ~/.ssh/id_ed25519_agent_sandbox
    IdentitiesOnly yes
    ForwardAgent no
    UserKnownHostsFile ~/.ssh/known_hosts_agent_sandbox
    StrictHostKeyChecking accept-new
```

- On a **Mac** laptop, add these two lines to both entries, so that the keychain keeps the key's
  passphrase:

  ```
      UseKeychain yes
      AddKeysToAgent yes
  ```

  (Other systems do not know `UseKeychain`; leave it out there.)
- `ForwardAgent no`: nothing in the sandbox can use the laptop's keys.
- The sandbox's own known-hosts file keeps its host key apart from everything else at `127.0.0.1`.
  If the sandbox is reset ([maintenance.md](maintenance.md)), its host key changes; delete that one
  file then.
- When the tool runs **on the server itself** (Ubuntu or Windows with a desktop), the `agent-sandbox`
  entry alone is enough, without its `ProxyJump` line.

**Check:**

- `ssh sandbox-server` logs in to the server without the server's password (the key's passphrase
  may be asked once). `exit`.
- `ssh agent-sandbox` gives the prompt `dev@agent-sandbox:~$`. `exit`.

## 4. VS Code and Claude Code

1. Install VS Code on the laptop, and from its Extensions view Microsoft's **Remote - SSH**.
2. In VS Code's user settings, set `remote.SSH.enableAgentForwarding` to `false`.
3. Command Palette (**Cmd-Shift-P** on a Mac, **Ctrl-Shift-P** elsewhere) > **Remote-SSH: Connect to
   Host…** > `agent-sandbox`. If asked for the platform: **Linux**. The bottom-left corner of the
   window then says `SSH: agent-sandbox`.
4. **File > Open Folder…** > `/home/dev/work` (or a project folder inside it).
5. In the Extensions view, find **Claude Code** and choose **Install in SSH: agent-sandbox**. It runs
   inside the sandbox and uses the Claude login made in [setup.md](setup.md), step 5; there is no
   second login.
6. Open Claude Code from its icon (or the Command Palette: **Claude Code**). Its permission mode can
   be chosen in the panel; in the sandbox, the mode that does not ask before acting is the point.

The container keeps git in VS Code's terminals from using the GitHub account that VS Code is signed
in to on the laptop. Git in the sandbox uses only its own identity ([setup.md](setup.md), step 10).

**Check:** Claude Code in VS Code answers "what is the hostname of this machine?" with
`agent-sandbox`.

## 5. Working this way

- **Closing the laptop ends what runs in VS Code's terminals.** Long runs belong in tmux: in VS Code's
  terminal, `tmux new -s work`, then `claude --dangerously-skip-permissions` (or anything else);
  detach with **Ctrl-b**, then **d**. Later, from VS Code, a terminal, or after reconnecting:
  `tmux attach -t work`.
- **Handing a session to the phone:** type `/remote-control` in a running Claude Code session, and it
  shows up in the Claude app as well. `/config` > **Enable Remote Control for all sessions** does that
  for every session.
- **Seeing a web page the sandbox serves** (a development server, a preview): VS Code forwards the
  port to the laptop by itself, or in its **Ports** view. Then open `http://localhost:<port>` on the
  laptop. From a terminal: `ssh -L <port>:localhost:<port> agent-sandbox`.
- **Several projects:** one folder each under `~/work`; open each in its own VS Code window.

## 6. Other ways in

All of these use the two SSH entries from section 3.

- **A terminal:** `ssh agent-sandbox`, then `claude` (or `tmux attach -t work`).
- **Another editor with a remote-over-SSH mode:** point it at the host `agent-sandbox`. If it reads
  `~/.ssh/config`, nothing else is needed; if not, give it the same values (host `127.0.0.1`, port
  `2222`, user `dev`, the key, and the server as jump host).
- **An SSH app on a phone or tablet:** it needs Tailscale on that device, and its own key let in
  with `host/add-key.sh` (section 2b). The app's own key screen shows the public half to copy.

## 7. Away from home

With Tailscale set up ([tailscale.md](tailscale.md)) and its name in the `sandbox-server` entry,
nothing changes away from home.

Without Tailscale, the laptop cannot reach `<server name>.local` from outside. Set Tailscale up then,
and change `HostName` in the `sandbox-server` entry to the server's Tailscale name; nothing else
changes.

**Check**, with the laptop on another network (a phone's hotspot): `ssh agent-sandbox` gives the
sandbox's prompt, and VS Code connects as at home.
