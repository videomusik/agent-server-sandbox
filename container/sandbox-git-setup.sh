#!/bin/bash
# Installed as sandbox-git-setup. Run it once inside the container, if agents in here are to clone
# private repositories or push.
#
# Gives the container its own git identity and its own SSH key for GitHub, both in the home volume:
#   ~/.gitconfig                 commit name and e-mail (GitHub's noreply address by default)
#   ~/.ssh/id_ed25519_github     the key; add its .pub to a GitHub account, or to one repository as a
#                                deploy key (docs/setup.md, step 10)
#   ~/.ssh/config                GitHub uses that key only; no SSH agent is ever used
set -eu

KEY="$HOME/.ssh/id_ed25519_github"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

printf 'GitHub account the commits are made as (username): '
read -r GH_USER
[ -n "$GH_USER" ] || { echo "no username given"; exit 1; }

# GitHub's noreply address is <numeric id>+<username>@users.noreply.github.com.
GH_ID="$(curl -fsS "https://api.github.com/users/$GH_USER" 2>/dev/null \
         | sed -n 's/^  "id": *\([0-9][0-9]*\),*$/\1/p' | head -n 1 || true)"
DEFAULT_EMAIL=""
[ -n "$GH_ID" ] && DEFAULT_EMAIL="${GH_ID}+${GH_USER}@users.noreply.github.com"
printf 'Commit e-mail [%s]: ' "${DEFAULT_EMAIL:-none found, type one}"
read -r EMAIL
EMAIL="${EMAIL:-$DEFAULT_EMAIL}"
[ -n "$EMAIL" ] || { echo "no e-mail given"; exit 1; }
printf 'Commit name [%s]: ' "$GH_USER"
read -r NAME
NAME="${NAME:-$GH_USER}"

# A fresh ~/.gitconfig: this identity, no credential helper, nothing else.
{
    printf '[user]\n\tname = %s\n\temail = %s\n' "$NAME" "$EMAIL"
    printf '[credential]\n\thelper =\n'
    printf '[init]\n\tdefaultBranch = main\n'
    printf '[advice]\n\tdetachedHead = false\n'
} > "$HOME/.gitconfig"
echo "wrote ~/.gitconfig"

if [ ! -f "$KEY" ]; then
    # No passphrase, so that agents can use the key without anyone typing it. The comment is stored
    # in the public key; without -C it would be dev@<container name>.
    ssh-keygen -t ed25519 -N "" -C "$GH_USER sandbox" -f "$KEY"
fi
cat > "$HOME/.ssh/config" <<EOF
Host github.com
	HostName github.com
	User git
	IdentityFile $KEY
	IdentitiesOnly yes
	IdentityAgent none

Host *
	IdentityAgent none
	IdentitiesOnly yes
EOF
chmod 600 "$HOME/.ssh/config"

echo
echo "The public key (safe to copy):"
echo
cat "$KEY.pub"
echo
echo "Add it on GitHub, either to the account '$GH_USER' (Settings > SSH and GPG keys), or to"
echo "one repository only (that repository's Settings > Deploy keys; tick 'Allow write access' to push)."
echo "Then test:  ssh -o StrictHostKeyChecking=accept-new -T git@github.com"
