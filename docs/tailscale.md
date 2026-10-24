# Tailscale: reaching the server from anywhere

Recommended, and free for personal use. Without it, a laptop reaches the server only on the home
network. The Claude app does not need it: Remote Control works from anywhere on its own.

## What it is, and why here

Tailscale joins your own devices into a private network, over the internet, wherever each of them
is. Each device gets a fixed name on that network, and the connections between them are encrypted
end to end. Nothing is opened on the home router, and no device is exposed to the internet.

For the sandbox this gives:

- **VS Code, a terminal, or any other SSH tool on a laptop reaches the sandbox away from home**, the
  same way as at home.
- **The server's desktop** (Screen Sharing, Remote Desktop) from anywhere.
- **A name for the server that always works.** Home-network names (`<name>.local`) depend on the
  router and the systems involved; the Tailscale name does not.

## 1. An account (you)

At tailscale.com, sign up with an account you already have (Google, Microsoft, GitHub, Apple, or
another the sign-in page offers). This makes your private network, which Tailscale calls a
*tailnet*. Personal use is free; the plan's limits are on Tailscale's pricing page.

## 2. The server (you)

- **Mac:** install Tailscale from tailscale.com (or the Mac App Store), open it, and log in with the
  account. Allow the VPN configuration when macOS asks. Set it to open at login (in its settings, or
  **System Settings > General > Login Items**). Like Docker Desktop, it runs once the user is logged
  in ([host-mac.md](host-mac.md), section 4).
- **Ubuntu:**

  ```sh
  curl -fsSL https://tailscale.com/install.sh | sh
  sudo tailscale up
  ```

  The second command prints a link: open it in a browser and log in. Tailscale then starts at every
  boot.
- **Windows:** the installer from tailscale.com; then log in from its icon in the taskbar.

## 3. The laptop (you)

Install it the same way, and log in to the **same** account.

The phone needs it only for an SSH app or for the server's desktop, not for the Claude app.

## 4. The server's name, and no expiry

1. Open the admin console at login.tailscale.com, page **Machines**. Both devices are listed.
2. The server's name there (for example `old-macbook-pro`) is its name on the tailnet. The full form,
   `old-macbook-pro.<your tailnet>.ts.net`, is shown under the machine.
3. In the server's **…** menu, choose **Disable key expiry**. Otherwise Tailscale asks it to log in
   again after some months, and from then on it is unreachable until someone does.

**Check**, on the laptop: `ping <server's Tailscale name>` gets answers. Then once more with the
laptop on another network (a phone's hotspot): it still answers.

## 5. Using it

Wherever these instructions ask for `<server name>`, use the Tailscale name. In particular,
`HostName` in the `sandbox-server` entry of the laptop's SSH settings ([connect.md](connect.md),
section 3). It then works at home and away alike.

If Tailscale is added later: change that one `HostName` line; nothing else changes.

## Good to know

- Every device in the tailnet can reach the server's SSH login, which still asks for a key or the
  server user's password. Add only your own devices, and protect the Tailscale account (and the
  account you sign in to it with) well.
- Tailscale's other features (sharing devices with other people, exit nodes, Tailscale SSH) are not
  needed here.
