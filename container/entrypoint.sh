#!/bin/bash
# Container start-up, as root: the SSH host key and the login key in place, VS Code's GitHub sign-in
# kept out of git in here, the Remote Control server started if it is enabled, then sshd in the
# foreground.
set -eu

KEYDIR=/etc/ssh/sandbox_keys
mkdir -p "$KEYDIR" /run/sshd
chmod 700 "$KEYDIR"
if [ ! -f "$KEYDIR/ssh_host_ed25519_key" ]; then
    ssh-keygen -q -t ed25519 -N "" -C "agent-sandbox host key" -f "$KEYDIR/ssh_host_ed25519_key"
fi

# The login key: the PUBLIC key that host/run.sh passes in (SANDBOX_AUTHORIZED_KEY), added once.
# More keys: host/add-key.sh.
install -d -m 700 -o dev -g dev /home/dev/.ssh
touch /home/dev/.ssh/authorized_keys
if [ -n "${SANDBOX_AUTHORIZED_KEY:-}" ] && ! grep -qxF "$SANDBOX_AUTHORIZED_KEY" /home/dev/.ssh/authorized_keys; then
    printf '%s\n' "$SANDBOX_AUTHORIZED_KEY" >> /home/dev/.ssh/authorized_keys
fi
chown dev:dev /home/dev/.ssh/authorized_keys
chmod 600 /home/dev/.ssh/authorized_keys

# ssh inside the container never uses an agent, only key files named in ~/.ssh/config.
if [ ! -f /home/dev/.ssh/config ]; then
    printf 'Host *\n\tIdentityAgent none\n\tIdentitiesOnly yes\n' > /home/dev/.ssh/config
    chown dev:dev /home/dev/.ssh/config
    chmod 600 /home/dev/.ssh/config
fi

# VS Code Remote-SSH machine settings: git in this container must not be answered with the GitHub
# account VS Code is signed in to on your own computer.
MACHINE=/home/dev/.vscode-server/data/Machine
if [ ! -f "$MACHINE/settings.json" ]; then
    install -d -o dev -g dev /home/dev/.vscode-server /home/dev/.vscode-server/data "$MACHINE"
    printf '{\n  "git.terminalAuthentication": false,\n  "github.gitAuthentication": false\n}\n' > "$MACHINE/settings.json"
    chown dev:dev "$MACHINE/settings.json"
fi

# The Remote Control server, if `sandbox-remote-control enable` was run. A failure here must not stop
# the container: `sandbox-remote-control status` shows what went wrong.
if [ -f /home/dev/.config/agent-sandbox/remote-control.autostart ]; then
    runuser -l dev -c 'sandbox-remote-control start' || echo "sandbox-remote-control did not start" >&2
fi

exec /usr/sbin/sshd -D -e
