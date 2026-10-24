# The server: Ubuntu with Docker Engine

An Ubuntu machine (a server, or a desktop or laptop kept on) as the sandbox's host. Every step is
done on that machine by a user who can `sudo`. Then go back to [setup.md](setup.md), step 2.

Unlike a Mac, Docker Engine on Linux starts at boot, before anyone logs in, so the sandbox comes back
by itself after a restart.

## 1. Docker Engine

From Ubuntu's own packages:

```sh
sudo apt update
sudo apt install docker.io docker-buildx
sudo systemctl enable --now docker
```

Or from Docker's own apt repository, as Docker's "Install Docker Engine on Ubuntu" page describes;
either works.

To run `docker` without `sudo`, add your user to the `docker` group, then log out and in again:

```sh
sudo usermod -aG docker $USER
```

⚠️ Membership of the `docker` group is equivalent to root on this machine. If `docker ps` still
says "permission denied" after logging in again, restart the machine (a desktop session, or a
user manager kept running with `loginctl enable-linger`, can keep the old groups).

**Check:** `docker run --rm hello-world` prints "Hello from Docker!".

## 2. Never sleep

On a desktop install, stop suspend altogether:

```sh
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

On a laptop, also keep it running with the lid closed: in `/etc/systemd/logind.conf`, set

```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
```

and restart the machine (restarting `systemd-logind` alone can end the desktop session).

## 3. SSH server

So that the machine can be looked after from another computer, and so that a laptop can reach the
sandbox through it ([connect.md](connect.md)):

```sh
sudo apt install openssh-server
```

The machine's name on the home network is `hostname` followed by `.local` if Avahi runs (the default
on Ubuntu desktop), or its IP address (`ip -4 addr`).

**Check**, from another computer: `ssh <user>@<hostname>.local` logs in.

## 4. Its desktop from another computer (optional)

Ubuntu 24.04 and later: **Settings > System > Remote Desktop**. **Desktop Sharing** shares the
session of the user logged in at the machine; **Remote Login** lets an RDP client log in while
no one is logged in there. Each has its own user name and password, set on that page. RDP clients:
Microsoft's Windows App on a Mac, Remote Desktop Connection on Windows.

## 5. Updates

`unattended-upgrades` installs security updates by itself and does not restart the machine unless
told to (`Unattended-Upgrade::Automatic-Reboot`). A restart brings Docker and the sandbox back on
its own.
