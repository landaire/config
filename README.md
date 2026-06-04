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
(work). Each `hosts/<name>.mod.nix` is:

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

## Rebuilding

Use the `mise` tasks (they include `sudo`, required for activation):

```
mise run rebuild:caladan   # or salusa / ix / rossak / work
mise run rebuild            # list targets
```

Each task runs `sudo nix run 'nix-darwin/master#darwin-rebuild' -- switch --flake 'path:.#<host>'`.

System-level activation (writing `/Library/Managed Preferences` for Helium,
shadow-xcode symlinks, Homebrew) runs via `system.activationScripts.postActivation.text`.

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
