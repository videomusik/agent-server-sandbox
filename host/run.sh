#!/bin/bash
# Build the image and start the sandbox container. Runs on the server: a Mac (Docker Desktop, OrbStack,
# Colima), Linux (Docker Engine), or Windows (Docker Desktop, from a WSL or Git Bash shell).
#
#   bash host/run.sh [--name NAME] [--port PORT] [--key PATH]
#
#   --name  container name and hostname; also names its volumes NAME-home and NAME-hostkeys [agent-sandbox]
#   --port  the SSH port, on the server's loopback interface only: 127.0.0.1:PORT              [2222]
#   --key   a login key whose PUBLIC half (PATH.pub) is let in                     [~/.ssh/id_ed25519_agent_sandbox]
#
# A login key is optional at first: without one, use the container from the server itself
# (docker exec), and let a key in later with host/add-key.sh.
#
# The container gets two named volumes (its home folder, its SSH host key) and one port on 127.0.0.1.
# No host folder is mounted and the Docker socket is not passed in.
set -euo pipefail
# Git Bash on Windows would otherwise rewrite the container paths below into Windows paths.
export MSYS_NO_PATHCONV=1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=agent-sandbox
PORT=2222
KEY="$HOME/.ssh/id_ed25519_agent_sandbox"
KEY_GIVEN=no
while [ $# -gt 0 ]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --key)  KEY="$2"; KEY_GIVEN=yes; shift 2 ;;
        -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
        *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
done

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not answering. Start Docker Desktop (or your Docker engine) and try again." >&2
    echo "(On a Mac: open -a Docker)" >&2
    exit 1
fi

PUBKEY=""
if [ -f "$KEY.pub" ]; then
    PUBKEY="$(cat "$KEY.pub")"
elif [ "$KEY_GIVEN" = yes ]; then
    echo "No public key at $KEY.pub" >&2
    exit 1
else
    echo "No login key at $KEY.pub: starting without one. Let a key in later with host/add-key.sh."
fi

docker build -t agent-sandbox "$HERE/container"

if docker container inspect "$NAME" >/dev/null 2>&1; then
    echo "Container '$NAME' already exists; starting it."
    echo "(To rebuild it from the new image: docker rm -f $NAME, then run this again. Its home volume stays.)"
    docker start "$NAME" >/dev/null
else
    docker volume create "$NAME-home" >/dev/null
    docker volume create "$NAME-hostkeys" >/dev/null
    docker run -d \
        --name "$NAME" \
        --hostname "$NAME" \
        --init \
        -p "127.0.0.1:$PORT:22" \
        -v "$NAME-home:/home/dev" \
        -v "$NAME-hostkeys:/etc/ssh/sandbox_keys" \
        -e SANDBOX_AUTHORIZED_KEY="$PUBKEY" \
        --restart unless-stopped \
        agent-sandbox >/dev/null
fi

echo
echo "Running '$NAME', SSH on 127.0.0.1:$PORT."
echo "A shell in it, on this machine:  docker exec -it -u dev $NAME bash -l"
