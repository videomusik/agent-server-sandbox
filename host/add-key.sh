#!/bin/bash
# Let one more login key into the sandbox. Runs on the server.
#
#   bash host/add-key.sh PATH.pub [--name NAME]
#
#   PATH.pub  a PUBLIC key file (one line, starting with ssh-), for example copied from a laptop
#   --name    the container                                                          [agent-sandbox]
set -euo pipefail
export MSYS_NO_PATHCONV=1

NAME=agent-sandbox
PUB=""
while [ $# -gt 0 ]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
        *) PUB="$1"; shift ;;
    esac
done

[ -n "$PUB" ] || { sed -n '2,7p' "$0"; exit 2; }
[ -f "$PUB" ] || { echo "no such file: $PUB" >&2; exit 1; }
if grep -q "PRIVATE KEY" "$PUB"; then
    echo "$PUB is a PRIVATE key. Use the .pub file next to it, and keep the private key where it is." >&2
    exit 1
fi
KEYLINE="$(head -n 1 "$PUB")"
case "$KEYLINE" in
    ssh-*|ecdsa-*|sk-*) ;;
    *) echo "$PUB does not look like an SSH public key" >&2; exit 1 ;;
esac

printf '%s\n' "$KEYLINE" | docker exec -i -u dev "$NAME" sh -c '
    umask 077
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys
    read -r k
    if grep -qxF "$k" ~/.ssh/authorized_keys; then
        echo "that key was already in"
    else
        printf "%s\n" "$k" >> ~/.ssh/authorized_keys
        echo "key added"
    fi'
