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
- `--home`: hjem standalone switch (links dotfiles/config, reloads and starts
  user services) plus `nix profile` install of the pinned tools env. Fast, no
  sudo.
- `--apps`: syncs the declared Flatpak set.
- `--system`: host config not baked into the image - writes Helium's managed
  policies, opens the ssh firewall port, and enables lingering so user
  services start at boot. Needs sudo.

The switch bakes in the pinned hjem CLI, tools env, flatpak lists, and Helium
policy, so a first run only needs Nix installed beforehand. It makes no
rpm-ostree changes itself; OS-level packages and services come from the
bazzite-nix image, which is rebased/rebooted separately (Bazzite is atomic).

The installed `richese-tools` profile also roots the generated hjem manifest
and every managed-file source. This keeps links such as
`~/.config/jj/config.toml` valid after Nix garbage collection.

Binaries that need OS integration ship baked into the bazzite-nix image (`ghcr.io/landaire/bazzite-nix`), not layered by the switch. This includes Hyprland, its desktop portal and session utilities, Helium (`helium-bin`), and Sunshine. Baking them keeps `bootc upgrade` working and lets the Sunshine RPM apply its udev rules and file capabilities.

The home switch links the Hyprland, Hypridle, Hyprlock, Waybar, Fuzzel, and Mako configuration from `dotfiles/`. Run `nix run .#richese-switch -- --home` before the first Hyprland login. Select `Hyprland` from Plasma Login Manager after deploying the image. Plasma remains available as a fallback session.

Hyprland treats the Elgato 4K X as a mirror of `DP-2`, not as another workspace. `Super+Shift+F1` selects the highest-resolution desktop: native 3440x1440 at 174.963 Hz on the Dell, mirrored to the capture card at 2560x1440 and 240 Hz. The card does not advertise 3440x1440, so Hyprland letterboxes the ultrawide image. `Super+Shift+F2` selects 2560x1440 capture mode and `Super+Shift+F3` selects 1920x1080 capture mode. Both drive the Dell at 2560x1440 and 119.88 Hz, its highest 16:9 refresh rate, and the capture card at 240 Hz. The Dell goes into standby on its own 1920x1080 timing, so the 1080p mode scales the desktop by 4/3 instead. `Super+Shift+F4` disables the capture output without changing the Dell's mode. F1, F2, or F3 re-enables it.

Other UI apps are installed as user Flatpaks. Zed's Flatpak export is named `dev.zed.Zed`, so the Linux workstation tools profile provides a `zed` wrapper for terminal use. The workstation tools profile also installs [Steamroom](https://github.com/landaire/steamroom). The switch also uninstalls the Firefox system flatpak and the redundant Sunshine flatpak after its native replacement is available. Waydroid is removed and sshd and tailscaled are enabled in the image build. Hyprland screenshots use Grim and Slurp. Press `Super+Shift+S` to select a region and copy the screenshot to the clipboard. `Print` does the same if available, and `Shift+Print` copies the full screen. Plasma screenshots use Spectacle.

The shared macOS and Linux workstation profile installs the Radicle CLI as `rad`. Each workstation must have its own Radicle DID. Run `rad auth` once when adding a device and `rad node start` when needed. On macOS, `modules/radicle-identity.mod.nix` restores host-specific private and public keys from `secrets/radicle-identities/<host>.age` and `<host>.pub.age`. Both files are age-encrypted so the public configuration does not associate a device with its Radicle identity.

On `richese`, run `mount-windows-drive E` from Nushell. The command accepts `C`, `D`, `E`, or `G` and uses each volume's stable UUID. New mounts are read-only under `/var/mnt`. Existing mounts keep their current path and access mode. Pass `--write` or `-w` to mount or remount read-write. Every mount uses `fmask=0111` so regular files do not receive execute bits. Run `unmount-windows-drive E` to unmount that volume from every current path. A remount preserves options reported by NTFS3. Options omitted from its mount table return to kernel defaults.

Not automated by the switch - install or use these as-is:

- Claude desktop - use the web app instead.
- Proton Drive - mount with rclone instead.
- Raycast - the user's own separate project, not part of this flake.
- macOS-only utilities with no richese equivalent here: Ice, Monodraw,
  DevUtils, KeyCastr, KeepingYouAwake, macFUSE, Glide. 010 Editor/ImHex is
  covered on richese by `hxy`, which the tools profile does install via Nix.

## Radicle on junction

`modules/radicle.mod.nix` runs a Radicle seed node, Tor client, onion service, and radicle-httpd in the `radicle` NixOS container on junction. It forwards HTTP port 8080 and Radicle node port 8776 for LAN and tailnet clients. An hourly timer runs `modules/radicle/mirror.nu`, which mirrors and seeds only this allow list:

- `landaire/noscope360`
- `landaire/xenon-forge`
- `landaire-contrib/buck2-rustc-bootstrap`
- `landaire-contrib/llvm-project`

Radicle project names replace the owner/repository slash with a dot because Radicle names cannot contain slashes. Repositories with the same short name under different GitHub owners therefore remain distinguishable in `rad-system ls` and Garden. Their GitHub node IDs key separate local mirrors, and their RIDs remain distinct and unchanged when the display name is synchronized.

The last slug is the existing GitHub LLVM fork; there is no
`landaire-contrib/llvm` repository. The node's default seeding policy is
`block`. Each successful mirror run removes stale explicit policies, so
repositories previously mirrored by the old account-wide job are no longer
seeded.

Repository visibility is synchronized from GitHub on every run. Public repositories are seeded directly. Private repository identities allow the DIDs listed in `secrets/radicle-private-repo-dids.age` before the local node seeds them. Edit that secret to grant a workstation access without publishing its DID in this repository.

Radicle 1.x transport is neither encrypted nor authenticated. A peer can impersonate an allow-listed DID and fetch a private repository ([disclosure](https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol)). The risk remains until Radicle 2.0. `radicle-node` is permitted as an insecure package by its exact version. A version bump fails evaluation until the permit is reviewed.

The node accepts up to 16 inbound sessions from the LAN, tailnet, and its Tor onion service. Every outbound Radicle session uses the container's Tor SOCKS proxy and remains limited to the Radicle-operated Iris and Rosa seeds plus the configured Garden node. A systemd IP address filter prevents the Radicle daemon from reaching public addresses directly if its proxy configuration changes. Garden and the public seeds see a Tor exit address. They still see Junction's public NID.

Tor bootstraps through the Tor Project's Snowflake bridge because direct relay connections may be blocked. Snowflake's broker and temporary proxy can observe Junction's network address. Radicle peers and Garden see only the Tor exit address.

The onion hostname is generated and retained by Tor. Read it on junction after deployment:

```console
nixos-container run radicle -- cat /var/lib/tor/onion/radicle/hostname
```

Personal macOS workstations receive named Radicle node profiles from the age-encrypted `secrets/radicle-nodes.json.age`. Nushell loads those profiles without storing node IDs in the shell configuration:

```console
rad node start
rad-node connect junction
rad-node inventory junction
rad-node clone junction rad:<RID>
```

The clone command accepts Junction's older root-level signed refs because it is a trusted seed. Add another record to the encrypted JSON file to name another hosted node.

The GitHub mirror job is not routed through Tor. GitHub sees Junction's public address. Keeping it direct avoids Tor-exit authentication challenges and does not create a direct network path for the separately sandboxed Radicle daemon.

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

## Poseidon on junction

`deploy/junction/poseidon.nix` runs [Poseidon](https://github.com/landaire/poseidon), the World of Warships Discord and Twitch bot, on junction. The deployment-only flake imports the private Poseidon input and creates three NixOS containers:

- `poseidongw` runs the Discord and Twitch front ends. It holds the secrets and keeps its state in `/var/lib/poseidon-gateway` on the host.
- `poseidonagt` answers questions for the gateway. It holds no secrets and keeps game data in `/var/lib/poseidon` on the host.
- `poseidonllm` runs llama-server on the GPU. It has no internet access and accepts connections only from the agent.

The Discord bot token is `secrets/poseidon-discord-token.age` and the Twitch client secret is `secrets/poseidon-twitch-client-secret.age`. Replace one with:

```console
cd secrets
cat /path/to/discord-token | nix run 'path:..#agenix' -- -e poseidon-discord-token.age
```

The Poseidon repository is private. Its input and lock file live under `deploy/junction`, outside the shared flake. Other hosts can update the root lock without access to Poseidon. Update only the Poseidon pin with:

```console
mise run update:poseidon
```

The update task decrypts `secrets/radicle-github-token.age` with your age identity and gives the token to Nix through the process environment. It does not write the plaintext token to the repository or Nix store.

`mise run rebuild:junction` refreshes the deployment lock's `base` input from the shared lock before it copies the tree and switches Junction.

`modules/nix-github-access.mod.nix` gives Nix on Junction read access to GitHub with the token in `secrets/radicle-github-token.age`. Activation writes it to the root-only `/run/nix/github-access-token.conf`, which `nix.conf` includes. When adding the module to a host that already has the Radicle GitHub secret, the first rebuild copies the tree but fails to fetch Poseidon because that include is not active yet. After that failure, switch once with the token and CUDA cache passed in the environment:

```console
ssh root@junction.tail8a811.ts.net 'NIX_CONFIG="access-tokens = github.com=$(cat /var/lib/secrets/radicle/github-token)
extra-substituters = https://cache.nixos-cuda.org
extra-trusted-public-keys = cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" nixos-rebuild switch --flake "git+file:///root/config?dir=deploy/junction#junction"'
```

Later deploys need only `mise run rebuild:junction`.

After the first deploy, authorize the Twitch bot account once. Open the printed URL while logged in to Twitch as AdalBotSchneider and enter the code:

```console
ssh -t root@junction.tail8a811.ts.net 'nixos-container run poseidongw -- poseidon-authorize-twitch && systemctl -M poseidongw restart poseidon-gateway'
```

Copy the archive of old game scripts once:

```console
ssh -A root@junction.tail8a811.ts.net 'rsync -a richese.local:/var/mnt/e/poseidon/scripts-zips/ /var/lib/poseidon/scripts-archive/ && chown -R 2742:2742 /var/lib/poseidon/scripts-archive && systemctl -M poseidonagt restart poseidon-agent'
```

On junction, follow the services with:

```console
journalctl -M poseidongw -u poseidon-gateway -f
journalctl -M poseidonagt -u poseidon-agent -f
journalctl -M poseidonllm -u llama-server -f
```

The agent downloads new game data each time it starts and restarts every day at 11:00 UTC.

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
- Berkeley Mono is installed on every host whose key is in `keys.hosts`
  except junction (`fontRecipients` in `secrets/secrets.nix`). darwin hosts
  get it in `~/Library/Fonts` on switch. richese gets it in
  `~/.local/share/fonts` from `richese-switch --system`. To add a host, put its
  `/etc/ssh/ssh_host_ed25519_key.pub` in `keys.nix` and rekey.

[hjem]: https://github.com/feel-co/hjem
[hjem-rum]: https://github.com/snugnug/hjem-rum
[`import-tree`-style auto-discovery]: https://github.com/hercules-ci/flake-parts
