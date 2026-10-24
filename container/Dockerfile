# The sandbox: a plain Debian container that you reach like a remote server, over SSH (a terminal,
# VS Code Remote-SSH) and from the Claude app through Claude Code's Remote Control. Nothing from the
# host is mounted into it and the Docker socket is not passed in. How to set it up: docs/setup.md.
FROM debian:trixie-slim

# Only what the sandbox itself needs: the SSH server, tmux (so long runs and the Remote Control server
# outlive a closed connection), git and curl, and a few basics. What a project needs on top: below
# (docs/setup.md, step 9).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-server ca-certificates curl git tmux \
      less nano procps unzip \
 && rm -rf /var/lib/apt/lists/*

# Your project's system packages: container/packages.txt, one Debian package name per line (none by
# default). After a change, rebuild the image (docs/maintenance.md, "Updates").
COPY packages.txt /tmp/packages.txt
RUN pkgs="$(sed -e 's/#.*//' /tmp/packages.txt | xargs)" \
 && if [ -n "$pkgs" ]; then \
      apt-get update \
      && apt-get install -y --no-install-recommends $pkgs \
      && rm -rf /var/lib/apt/lists/*; \
    fi \
 && rm /tmp/packages.txt

# Locale. Debian's sshd takes over the client's LANG and LC_* (AcceptEnv); a Mac sends a locale this
# slim image does not have, and every shell then warns. Sessions use C.UTF-8 instead.
RUN sed -i 's/^AcceptEnv/# AcceptEnv/' /etc/ssh/sshd_config \
 && printf 'LANG=C.UTF-8\n' > /etc/default/locale
ENV LANG=C.UTF-8

# The one user you log in as: no password, no sudo.
RUN useradd --create-home --shell /bin/bash dev \
 && mkdir -p /run/sshd /etc/ssh/sandbox_keys \
 && chmod 700 /etc/ssh/sandbox_keys

COPY sshd_sandbox.conf /etc/ssh/sshd_config.d/sandbox.conf
COPY entrypoint.sh /usr/local/sbin/sandbox-entrypoint
COPY sandbox-remote-control.sh /usr/local/bin/sandbox-remote-control
COPY sandbox-git-setup.sh /usr/local/bin/sandbox-git-setup
RUN chmod 755 /usr/local/sbin/sandbox-entrypoint /usr/local/bin/sandbox-remote-control /usr/local/bin/sandbox-git-setup

# Claude Code, installed as dev with the native installer (into ~/.local). /home/dev becomes a named
# volume at run time; a new, empty volume starts as a copy of this, so claude is there on the first
# run, and from then on it updates itself inside the volume.
USER dev
RUN mkdir -p /home/dev/work \
 && curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/dev/.local/bin:${PATH}"

# sshd has to start as root; it logs you in as dev.
USER root
EXPOSE 22
ENTRYPOINT ["/usr/local/sbin/sandbox-entrypoint"]
