# Looking after it

Commands marked **server** run in a terminal on the server (on a Mac, an interactive SSH login to it
works too); commands marked **inside** run in the container's shell
(`docker exec -it -u dev agent-sandbox bash -l` on the server, or `ssh agent-sandbox`).

## Everyday

| What | Where | Command |
|---|---|---|
| a shell in the sandbox | server | `docker exec -it -u dev agent-sandbox bash -l` |
| is it running? | server | `docker ps --filter name=agent-sandbox` |
| stop / start it | server | `docker stop agent-sandbox` / `docker start agent-sandbox` |
| the Remote Control server | inside | `sandbox-remote-control status` (also `attach`, `restart`, `disable`) |
| the container's start-up messages | server | `docker logs agent-sandbox` |

## Updates

- **Claude Code** updates itself inside the sandbox; `claude update` updates it at once, `claude
  doctor` shows its state. After an update, `sandbox-remote-control restart` moves the Remote
  Control server to the new version.
- **The image** (Debian, the tools, the scripts in `container/`): after a change to `container/`, or
  now and then for Debian's security updates, rebuild on the server:

  ```sh
  git pull
  docker rm -f agent-sandbox
  bash host/run.sh
  ```

  `docker rm -f` removes the container, not its volumes: the home folder (`~/work`, the Claude login,
  keys, settings) and the SSH host key stay. If Remote Control was enabled, it starts again by itself.

## Backup

Everything worth keeping is in the volume `agent-sandbox-home`. To save it as a file in the current
folder on the server (this mounts that one folder into a short-lived helper container, not into the
sandbox):

```sh
docker run --rm -v agent-sandbox-home:/data:ro -v "$PWD":/backup debian:trixie-slim \
    tar czf /backup/agent-sandbox-home.tgz -C /data .
```

The file holds the Claude login and any keys made in the sandbox: keep it as private as the server.
To restore it into a new, empty volume, stop the container first, then:

```sh
docker run --rm -v agent-sandbox-home:/data -v "$PWD":/backup debian:trixie-slim \
    tar xzf /backup/agent-sandbox-home.tgz -C /data
```

## Starting completely fresh

⚠️ This deletes everything in the sandbox, including work not yet pushed or copied out, its Claude
login and its keys. Back up first if in doubt.

```sh
docker rm -f agent-sandbox
docker volume rm agent-sandbox-home agent-sandbox-hostkeys
bash host/run.sh
```

Then [setup.md](setup.md) from step 5. On each laptop, delete `~/.ssh/known_hosts_agent_sandbox`
(the sandbox has a new host key), and add the laptop's key again
([connect.md](connect.md), step 2b), unless `host/run.sh` was given it with `--key`.

## Installing more software

There is no `sudo` inside: agents cannot change the system, only the home folder.

- **System packages, lasting:** add them to `container/packages.txt`, then rebuild (Updates, above).
  [setup.md](setup.md), step 9.
- **Installs into the home folder** survive rebuilds, since the home folder is a volume.
- **System packages, for now only:** `docker exec -u root agent-sandbox apt-get update`, then
  `docker exec -u root agent-sandbox apt-get install -y <package>`, on the server. This is lost when
  the container is rebuilt.

## When something goes wrong

| What you see | What to do |
|---|---|
| `docker`: "Cannot connect to the Docker daemon" / "failed to connect to the docker API" | Start Docker Desktop (`open -a Docker` on a Mac) or the engine. |
| The server shows offline in the Claude app | Is the server awake and on the network? Then, inside: `sandbox-remote-control status`. Not running: `sandbox-remote-control start`. Running but with an error on its screen: `sandbox-remote-control attach` to read it. |
| Remote Control says the account cannot use it | It needs a Pro, Max, Team or Enterprise plan and a claude.ai login (not an API key). On Team and Enterprise, an owner switches it on. Log in again inside with `claude`, then `/login`. |
| Sessions from the phone ask whether to trust the folder, or stop at a warning | Run `claude` once inside in that folder and answer, and `claude --dangerously-skip-permissions` once and accept ([setup.md](setup.md), step 5). Then `sandbox-remote-control restart`. |
| Nothing comes back after the server restarted | A Mac: is its user logged in? Docker Desktop only runs then ([host-mac.md](host-mac.md), section 4). |
| `ssh agent-sandbox`: "Permission denied (publickey)" | The key is not in the container: [connect.md](connect.md), step 2b. Inside, `cat ~/.ssh/authorized_keys` lists the keys that are. |
| `ssh agent-sandbox`: "REMOTE HOST IDENTIFICATION HAS CHANGED" | Expected after a fresh start only. Then delete `~/.ssh/known_hosts_agent_sandbox` on the laptop. Otherwise stop and find out why. |
| `ssh agent-sandbox` hangs, or "Connection refused" | Does `ssh sandbox-server` work? If not, the server's SSH or the network (next row). If it does, is the container running? |
| The laptop cannot reach the server over Tailscale | Is Tailscale running and logged in on both? Does the admin console list the server as connected, and is its key expiry disabled ([tailscale.md](tailscale.md), section 4)? On a Mac server: is its user logged in? |
| Building over SSH on a Mac: "error getting credentials … User interaction is not allowed" | [host-mac.md](host-mac.md), section 6. |
| The container restarts again and again; `docker logs agent-sandbox` shows `$'\r': command not found` | The scripts got Windows line endings. Clone the repository inside WSL or Linux, or set the files back to LF, and rebuild. |
