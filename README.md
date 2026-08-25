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

Binaries that need OS integration ship baked into the bazzite-nix image
(`ghcr.io/landaire/bazzite-nix`), not layered by the switch: Helium
(`helium-bin`) and Sunshine (game streaming). Baking them keeps `bootc
upgrade` working and lets the Sunshine RPM apply its udev rules and
`cap_sys_admin`/`cap_sys_nice` file capabilities, which the sandboxed flatpak
cannot. Helium's config and policies are still managed declaratively by the
switch, same as on macOS.

Other UI apps are installed as user Flatpaks. The switch also uninstalls the
Firefox system flatpak and the now-redundant Sunshine flatpak (the latter only
once the native RPM is on PATH). Waydroid is removed and sshd/tailscaled are
enabled in the image build. Screenshots use the built-in KDE Spectacle.

Not automated by the switch - install or use these as-is:

- Claude desktop - use the web app instead.
- Proton Drive - mount with rclone instead.
- Raycast - the user's own separate project, not part of this flake.
- macOS-only utilities with no richese equivalent here: Ice, Monodraw,
  DevUtils, KeyCastr, KeepingYouAwake, macFUSE, Glide. 010 Editor/ImHex is
  covered on richese by `hxy`, which the tools profile does install via Nix.

## Notes

- Homebrew is managed declaratively via `nix-homebrew` with pinned taps and
  `onActivation.cleanup = "zap"` — anything not declared in `modules/apps.mod.nix`
  is removed on switch.
- `theme.isDark` / `theme.cornerRadius` (from `options/theme.mod.nix`) drive the
  difftastic background and jujutsu graph style.
- Fonts (Berkeley Mono) are NOT managed here (the old sops-based module was
  dropped); install separately.

[hjem]: https://github.com/feel-co/hjem
[hjem-rum]: https://github.com/snugnug/hjem-rum
[`import-tree`-style auto-discovery]: https://github.com/hercules-ci/flake-parts
