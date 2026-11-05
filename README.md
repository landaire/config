# nix-darwin config

A multi-host nix-darwin configuration using the **Dendritic pattern**
(flake-parts + [`import-tree`-style auto-discovery]) with **hjem + hjem-rum** as
the home layer (instead of home-manager).

## Layout

```
flake.nix              # flake-parts mkFlake; globs and imports every **/*.mod.nix
lib/
  default.nix          # extends nixpkgs lib (merged into `lib` everywhere)
  shell.nix            # asShell — run a script as an activation/shell step
  generators.nix       # toCliFlagList / toCliArgumentList (bat/ripgrep)
  systems.nix          # lib.systems.darwinSystem — the host builder
options/
  flake-outputs.mod.nix # the commonModules / darwinModules / homeModules registries
  theme.mod.nix        # ThemeNix-backed `theme` option (theme.isDark, .cornerRadius)
  unfree.mod.nix       # allowedUnfreePackageNames -> allowUnfreePredicate
modules/
  *.mod.nix            # one concern per file (darwin system, home programs, etc.)
  programs/*.mod.nix   # per-program home modules
hosts/
  <name>.mod.nix       # one file per machine; calls lib.systems.darwinSystem
docs/superpowers/      # the design spec + implementation plan for the migration
```

Every `*.mod.nix` is a flake-parts module, auto-discovered by `flake.nix`. A
module contributes to the build by registering into one of three registries:

- `flake.commonModules.<name>` — shared by every system type.
- `flake.darwinModules.<name>` — nix-darwin (system-level) modules.
- `flake.homeModules.<name>` — hjem (home-level) modules.

`lib.systems.darwinSystem` assembles each host from
`commonModules ++ darwinModules` plus all `homeModules` (attached to the user
via hjem's `home.extraModules`).

## Home layer (hjem + hjem-rum)

This config uses [hjem] + [hjem-rum] rather than home-manager. Inside a home
module:

- `programs.<x>` is aliased to hjem-rum's `rum.programs.<x>`.
- `packages = [ ... ]` installs user packages.
- `files.".path".{source,text}` writes files under `$HOME`.
- `xdg.config.files."p".{source,text,value,generator}` writes under
  `$XDG_CONFIG_HOME`; `.value` + `.generator` render structured config (e.g.
  `pkgs.writers.writeTOML`).
- `config.directory` is the home directory; `config.xdg.{config,data,state,cache}.directory`
  are the XDG dirs.

## Hosts & profiles

Hosts: `caladan`, `salusa`, `ix`, `rossak` (personal) and `landerb-mac2`
(work) are nix-darwin hosts built via `lib.systems.darwinSystem`. Each
`hosts/<name>.mod.nix` is:

```nix
{ lib, ... }:
lib.systems.darwinSystem "<hostname>" {
  username = "...";
  useremail = "...";
  profile = "personal"; # or "work"
}
```

`profile`/`isPersonal` is passed as a specialArg; profile-specific content is
gated with `lib.mkIf isPersonal` (see `modules/apps.mod.nix`). `useremail` is
threaded into the git/jujutsu home modules for commit identity.

To add a host: create `hosts/<name>.mod.nix` as above — no other wiring needed.

`richese` is different: it's a Bazzite (Linux) host built via
`lib.systems.hjemSystem` (hjem standalone) instead of `darwinSystem` -
see "richese (Bazzite / Linux)" below.

## Rebuilding

Use the `mise` tasks (they include `sudo`, required for activation):

```
mise run rebuild:caladan   # or salusa / ix / rossak / work
mise run rebuild            # list targets
```

Each task runs `sudo nix run 'nix-darwin/master#darwin-rebuild' -- switch --flake 'path:.#<host>'`.

System-level activation (writing `/Library/Managed Preferences` for Helium,
shadow-xcode symlinks, Homebrew) runs via `system.activationScripts.postActivation.text`.

## richese (Bazzite / Linux)

`richese` is a Bazzite (immutable Fedora Atomic, x86_64) host. It is managed
by `lib.systems.hjemSystem` (hjem standalone), not nix-darwin, but it reuses
the same shared hjem home modules as the macOS hosts above.

There is a single entry point for it, `richese-switch` - the darwin-rebuild
analogue for this host. Bootstrapping a fresh machine:

```
1. Install Nix (Determinate Systems installer).
2. Clone this repo; from its root run:  nix run 'path:.#richese-switch'
   (full sync: home + apps + system; one sudo prompt; no rpm-ostree staging -
   OS packages/services come from the bazzite-nix image).
3. Reboot; then:  tailscale up  ;  chsh to the nushell from the tools profile.

Day-to-day:  nix run .#richese-switch            (full)
             nix run .#richese-switch -- --home  (fast, no sudo)
```

`richese-switch` takes an optional scope flag:

- `--all` (default): home + apps + system, in order.
- `--home`: hjem standalone switch (links dotfiles/config) plus `nix profile`
  install of the pinned tools env. Fast, no sudo.
- `--apps`: syncs the declared Flatpak set.
- `--system`: host config not baked into the image - writes Helium's managed
  policies and opens the ssh firewall port. Needs sudo.

The switch bakes in the pinned hjem CLI, tools env, flatpak lists, and Helium
policy, so a first run only needs Nix installed beforehand. It makes no
rpm-ostree changes itself; OS-level packages and services come from the
bazzite-nix image, which is rebased/rebooted separately (Bazzite is atomic).

Binaries that need OS integration ship baked into the bazzite-nix image (`ghcr.io/landaire/bazzite-nix`), not layered by the switch. This includes Hyprland, its desktop portal and session utilities, Helium (`helium-bin`), and Sunshine. Baking them keeps `bootc upgrade` working and lets the Sunshine RPM apply its udev rules and file capabilities.

The home switch links the Hyprland, Hypridle, Hyprlock, Waybar, Fuzzel, and Mako configuration from `dotfiles/`. Run `nix run .#richese-switch -- --home` before the first Hyprland login. Select `Hyprland` from Plasma Login Manager after deploying the image. Plasma remains available as a fallback session.

Hyprland treats the Elgato 4K X as a mirror of `DP-2`, not as another workspace. `Super+Shift+F1` selects the highest-resolution desktop: native 3440x1440 at 174.963 Hz on the Dell, mirrored to the capture card at 2560x1440 and 240 Hz. The card does not advertise 3440x1440, so Hyprland letterboxes the ultrawide image. `Super+Shift+F2` selects 2560x1440 capture mode and `Super+Shift+F3` selects 1920x1080 capture mode. Both drive the Dell at 2560x1440 and 119.88 Hz, its highest 16:9 refresh rate, and the capture card at 240 Hz. The Dell goes into standby on its own 1920x1080 timing, so the 1080p mode scales the desktop by 4/3 instead. `Super+Shift+F4` disables the capture output without changing the Dell's mode. F1, F2, or F3 re-enables it.

Other UI apps are installed as user Flatpaks. Zed's Flatpak export is named `dev.zed.Zed`, so the Linux workstation tools profile provides a `zed` wrapper for terminal use. The workstation tools profile also installs [Steamroom](https://github.com/landaire/steamroom). The switch also uninstalls the Firefox system flatpak and the redundant Sunshine flatpak after its native replacement is available. Waydroid is removed and sshd and tailscaled are enabled in the image build. Hyprland screenshots use Grim and Slurp. Press `Super+Shift+S` to select a region and copy the screenshot to the clipboard. `Print` does the same if available, and `Shift+Print` copies the full screen. Plasma screenshots use Spectacle.

On `richese`, run `mount-windows-drive E` from Nushell. The command accepts `C`, `D`, `E`, or `G` and uses each volume's stable UUID. New mounts are read-only under `/var/mnt`. Existing mounts keep their current path and access mode. Pass `--write` or `-w` to mount or remount read-write. Every mount uses `fmask=0111` so regular files do not receive execute bits. Run `unmount-windows-drive E` to unmount that volume from every current path. A remount preserves options reported by NTFS3. Options omitted from its mount table return to kernel defaults.

Not automated by the switch - install or use these as-is:

- Claude desktop - use the web app instead.
- Proton Drive - mount with rclone instead.
- Raycast - the user's own separate project, not part of this flake.
- macOS-only utilities with no richese equivalent here: Ice, Monodraw,
  DevUtils, KeyCastr, KeepingYouAwake, macFUSE, Glide. 010 Editor/ImHex is
  covered on richese by `hxy`, which the tools profile does install via Nix.

## Radicle on junction

`modules/radicle.mod.nix` runs a Radicle seed node and radicle-httpd in the
`radicle` NixOS container on junction. Ports 8776 (node) and 8080 (httpd) are
forwarded from the host. An hourly timer runs `modules/radicle/mirror.nu`,
which mirrors and seeds only this allow list:

- `landaire/noscope360`
- `landaire/xenon-forge`
- `landaire-contrib/buck2-rustc-bootstrap`
- `landaire-contrib/llvm-project`

Radicle project names use the full `owner/repository` slug. GitHub repositories
with the same short name therefore remain distinguishable in `rad-system ls`
and Garden. Their GitHub node IDs key separate local mirrors, and their RIDs
remain distinct and unchanged when the display name is synchronized.

The last slug is the existing GitHub LLVM fork; there is no
`landaire-contrib/llvm` repository. The node's default seeding policy is
`block`. Each successful mirror run removes stale explicit policies, so
repositories previously mirrored by the old account-wide job are no longer
seeded.

`landaire/noscope360` is private. Its Radicle identity allows the Radicle
Garden DID, and the local node seeds it so Garden can fetch it. Radicle 1.x
transport is neither encrypted nor authenticated; a peer can impersonate an
allow-listed DID and fetch the repository
([disclosure](https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol)).
The risk remains until Radicle 2.0. `radicle-node` is permitted as an insecure
package by its exact version; a version bump fails evaluation until the permit
is reviewed.

The mirror uses separate fine-grained PATs because GitHub tokens are scoped to
one resource owner. Both need Contents read-only access:

- `secrets/radicle-github-token.age` covers `landaire`.
- `secrets/radicle-landaire-contrib-token.age` covers `landaire-contrib`.

From Nushell, set or replace either token with raw pipeline input:

```nu
cd secrets
open --raw /absolute/path/to/landaire-token |
  nix run 'path:..#agenix' -- --edit radicle-github-token.age
open --raw /absolute/path/to/landaire-contrib-token |
  nix run 'path:..#agenix' -- --edit radicle-landaire-contrib-token.age
```

After deploying, the first mirror run starts on the next hour. To start it
now, on junction:

```
nixos-container run radicle -- systemctl start --no-block radicle-mirror
journalctl -M radicle -u radicle-mirror -f
```

Inside the container (`nixos-container root-login radicle`), `rad-system`
runs `rad` as the node's user, for example `rad-system ls --all`.

After the mirror succeeds, copy the four RIDs from `rad-system ls --all` into
the Garden dashboard's **Add a repo** form. The node is configured to prefer
and persistently connect to
`z6MkrwUPtWaeqYEAS4YzPfzc94UQQFBpPqVVEw2vHKun2Tgy@lander.radicle.garden:58038`.
The bare DID is also in the private repository's identity allow list. Confirm
all four dashboard entries reach `synced`.

## Spotify playlists on junction

`hosts/junction-system.nix` runs the Spotify playlist organizer through Buck2 every day at 04:00 with up to 30 minutes of randomized delay. The timer is persistent, so a missed run starts after the host returns.

Deploy the application repository to `/home/lander/dev/spotify-playlist` before enabling the timer. The service builds and runs that checkout through Buck2.

The client configuration and bootstrap OAuth session are agenix secrets encrypted to the user SSH keys and the junction host key. Give junction a separate Spotify grant so token refreshes do not interfere with the Mac session:

```console
cd /Users/lander/dev/spotify-playlist
SPOTIFY_PLAYLIST_KEYCHAIN_ACCOUNT=junction-oauth-session devenv shell -- buck2 run //:spotify-playlist -- authorize

cd /etc/nix-darwin/secrets
cat /Users/lander/dev/spotify-playlist/SECRETS | nix run 'path:..#agenix' -- -e spotify-playlist-config.age
security find-generic-password -s dev.lander.spotify-playlist -a junction-oauth-session -w | nix run 'path:..#agenix' -- -e spotify-playlist-session.age
cd ..
mise run rebuild:junction
ssh root@junction.tail8a811.ts.net 'systemctl stop spotify-playlist-sync; rm -f /var/lib/spotify-playlist/session.json; systemctl start --no-block spotify-playlist-sync'
```

The service copies the bootstrap session into `/var/lib/spotify-playlist/session.json` when that file is absent. Refreshed tokens and playlist management state remain in that private state directory. Remove the session file after deploying a replacement bootstrap secret.

## Secrets

Secrets are [agenix](https://github.com/ryantm/agenix) files in `secrets/`,
encrypted to the user keys and host keys in `keys.nix`. `secrets/secrets.nix`
lists the recipients of each file. Hosts decrypt them with
`/etc/ssh/ssh_host_ed25519_key`: NixOS during activation, nix-darwin from the
`activate-agenix` launchd daemon. Piping into `agenix -e` replaces a
secret without decrypting it. Editing in `$EDITOR` decrypts first, and
agenix cannot use ssh-agent, so it needs an unencrypted key or the
passphrase. After changing recipients, run
`nix run 'path:..#agenix' -- --rekey` from `secrets/`.

## Notes

- Homebrew is managed declaratively via `nix-homebrew` with pinned taps and
  `onActivation.cleanup = "zap"` — anything not declared in `modules/apps.mod.nix`
  is removed on switch.
- `theme.isDark` / `theme.cornerRadius` (from `options/theme.mod.nix`) drive the
  difftastic background and jujutsu graph style.
- Berkeley Mono is copied into `~/Library/Fonts` on each darwin host that is a
  recipient of `secrets/fonts/*.age` (`fontRecipients` in
  `secrets/secrets.nix`). To add a host, put its
  `/etc/ssh/ssh_host_ed25519_key.pub` in `keys.nix`, add it to
  `fontRecipients`, and rekey.

[hjem]: https://github.com/feel-co/hjem
[hjem-rum]: https://github.com/snugnug/hjem-rum
[`import-tree`-style auto-discovery]: https://github.com/hercules-ci/flake-parts
