#!/bin/bash
# Installed as sandbox-remote-control. Keeps Claude Code's Remote Control server running in a tmux
# session, so that the Claude app (Code tab) and claude.ai/code can start and drive sessions in here.
#
#   sandbox-remote-control enable    start it now, and again at every container start
#   sandbox-remote-control disable   stop it, and no longer start it with the container
#   sandbox-remote-control start | stop | restart
#   sandbox-remote-control status    whether it runs, and the last lines of its screen
#   sandbox-remote-control attach    watch it (space shows a QR code); detach with Ctrl-b, then d
#
# Settings, in ~/.config/agent-sandbox/remote-control.conf (written on first use; restart after a
# change):
#   RC_DIR              the folder its sessions start in                  [~/work]
#   RC_PERMISSION_MODE  the permission mode of the sessions it starts     [bypassPermissions]
#   RC_SPAWN            same-dir, worktree or session                     [same-dir]
#   RC_NAME             the session name in the app; empty: automatic     []
set -eu

CONF_DIR="$HOME/.config/agent-sandbox"
CONF="$CONF_DIR/remote-control.conf"
AUTOSTART="$CONF_DIR/remote-control.autostart"
SESSION=remote-control

load_conf() {
    mkdir -p "$CONF_DIR"
    if [ ! -f "$CONF" ]; then
        cat > "$CONF" <<'EOF'
# Read by sandbox-remote-control. After a change: sandbox-remote-control restart
RC_DIR="$HOME/work"
RC_PERMISSION_MODE=bypassPermissions
RC_SPAWN=same-dir
RC_NAME=
EOF
    fi
    # shellcheck source=/dev/null
    . "$CONF"
    mkdir -p "$RC_DIR"
}

running() {
    tmux has-session -t "$SESSION" 2>/dev/null
}

serve() {
    # Runs inside the tmux session: the server, started again whenever it exits. It exits, for
    # example, after about ten minutes without a network.
    load_conf
    cd "$RC_DIR"
    set -- --permission-mode "$RC_PERMISSION_MODE" --spawn "$RC_SPAWN"
    if [ -n "$RC_NAME" ]; then
        set -- "$@" --name "$RC_NAME"
    fi
    while true; do
        claude remote-control "$@" || true
        echo
        echo "claude remote-control exited at $(date '+%Y-%m-%d %H:%M'); starting it again in 60 s."
        echo "To stop it: sandbox-remote-control stop"
        sleep 60
    done
}

start() {
    if running; then
        echo "already running (tmux session '$SESSION')"
        return 0
    fi
    load_conf
    tmux new-session -d -s "$SESSION" -c "$RC_DIR" "sandbox-remote-control serve"
    echo "started in tmux session '$SESSION', in $RC_DIR"
    echo "watch it: sandbox-remote-control attach"
}

stop() {
    if running; then
        tmux kill-session -t "$SESSION"
        echo "stopped"
    else
        echo "not running"
    fi
}

status() {
    if running; then
        echo "running (tmux session '$SESSION'); its screen ends with:"
        echo
        tmux capture-pane -p -t "$SESSION" | sed '/^[[:space:]]*$/d' | tail -n 15
        echo
    else
        echo "not running"
    fi
    if [ -f "$AUTOSTART" ]; then
        echo "starts with the container: yes"
    else
        echo "starts with the container: no (sandbox-remote-control enable)"
    fi
}

case "${1:-}" in
    enable)
        mkdir -p "$CONF_DIR"
        touch "$AUTOSTART"
        start
        ;;
    disable)
        rm -f "$AUTOSTART"
        stop
        ;;
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    status) status ;;
    attach) exec tmux attach -t "$SESSION" ;;
    serve) serve ;;
    *)
        sed -n '2,16p' "$0"
        exit 2
        ;;
esac
