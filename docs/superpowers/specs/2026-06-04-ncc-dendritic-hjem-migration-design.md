# Re-platform nix-darwin config onto ncc's Dendritic + hjem architecture

**Date:** 2026-06-04
**Status:** Approved design — pending implementation plan

## Goal

Migrate this nix-darwin configuration from its current shape (a hand-rolled
flake with manual module lists + home-manager) onto the architecture used by
`~/src/ncc` (RGBCube's config):

- **flake-parts + `import-tree`** auto-discovery of `**/*.mod.nix` modules (the
  Dendritic pattern).
- A custom `lib` extension and `options/` registry exposing
  `darwinModules` / `homeModules` / `commonModules`.
- **hjem + hjem-rum** replacing home-manager.
- ncc's supporting infra: `theme` (ThemeNix), `unfree` predicate, `lib`
  helpers (`asShell`, generators).

Folded into the migration are the three originally-requested "yoinks":

1. **Helium** browser config (full port, **minus the Stylus extension**).
2. **macOS screenshot location** → `~/Downloads/Screenshots`.
3. **difftastic** config (theme-aware `difft` wrapper + git/jj integration).

This is a full re-platform of the flake's backbone, not a drop-in of snippets,
because ncc's borrowed modules are written against hjem (not home-manager) and
its custom option/lib layer.

## Non-goals (explicitly NOT ported)

- `persist` / `disko` / bcachefs (Linux-only).
- All NixOS modules, NixOS hosts, ISO, and installer machinery.
- Linux-only applications (krita, KDE apps, etc.).
- agenix / secrets management (the existing sops config is already commented
  out; out of scope for this migration).
- RGBCube's `crash` custom nushell-as-login-shell.

## Context: what ncc actually is

- ncc is **primarily a NixOS config**. Both its hosts (`istanbul`, `vienna`)
  are built via `lib.systems.nixosSystem`. There is **no `darwinSystem`
  builder** — its darwin modules exist but are never assembled into a
  `darwinConfigurations` output. We must write the darwin host builder
  ourselves.
- ncc's "home" layer is **hjem + hjem-rum**, not home-manager.
  `modules/home.mod.nix` aliases `home` → `hjem` and `programs` →
  `rum.programs`, and injects `hjem-rum` via `home.extraModules`.
- The `files.`, `xdg.config.files."…".value` / `.generator`, and bare
  `packages = …` options seen in ncc's home modules are **hjem/hjem-rum APIs**,
  not home-manager.
- ncc's flake `nixConfig` enables `pipe-operators`; modules use `|>` and `<|`
  throughout, plus the house style in ncc's `AGENTS.md` (full
  `inherit (lib.x.y) …` paths, uppercase section comments, `getExe`, etc.).

### hjem-rum program-module coverage (locked rev `fdfb0cd`)

Available (usable as `programs.<name>`): `nushell`, `zoxide`, `starship`,
`zed`, `git`, `direnv`, `helix`, plus many GUI/Wayland modules irrelevant here.

**Not** available (require raw config files via hjem `files`/`xdg.config.files`):
`atuin`, `aerospace`, `jujutsu` (jj), `bat`.

## Current config inventory (what must survive)

- **Hosts/profiles:** `salusa`, `caladan`, `ix`, `rossak` (personal);
  `landerb-mac2` (work). Driven today by `hostProfiles` + `hostConfigs` maps in
  `flake.nix`, with `apps.nix` selecting `apps-common` + `apps-personal` /
  `apps-work`.
- **Home-manager programs:** nushell (ssh-agent snippet, vi mode, banner off,
  filesize binary, cursor shapes), atuin (compact style, nushell integration),
  zoxide (nushell integration), starship (settings), zed-editor (extensions,
  userSettings — vim mode, fonts, LSP config for nix/rust), aerospace
  (**currently `enable = false`**), home-manager itself.
- **Dotfiles symlinked via home.file/xdg.configFile:** hammerspoon
  (SpoonInstall + PaperWM spoons fetched, init.lua), nvim init.vim,
  jj/config.toml, wezterm.lua, rustfmt.toml, `.zshrc`, `.zprofile`, `.profile`,
  `.cargo/config.toml`, claude skills dir.
- **Darwin system:** touchID sudo, dock (autohide, left), finder, trackpad,
  NSGlobalDomain (dark mode, disabled autocorrect/substitutions, beep),
  screenshot location (`~/Desktop/screenshots` → to be changed), loginwindow,
  zsh + nushell shells.
- **Packages:** large `apps-common`/`apps-personal`/`apps-work` lists +
  homebrew taps/brews/casks/masApps.

## Architecture

### Target directory layout

```
flake.nix                      # flake-parts mkFlake, nixConfig, inputs, import-tree
lib/
  default.nix                  # aggregates the lib extension
  shell.nix                    # asShell (used by helium activation script)
  generators.nix               # toCliFlagList / toCliArgumentList (only if a port needs them)
  systems.nix                  # darwinSystem builder (NEW — we author this)
options/
  flake-outputs.mod.nix        # darwinModules/homeModules/commonModules registry
  theme.mod.nix                # ThemeNix-backed theme option
  unfree.mod.nix               # allowedUnfreePackageNames -> allowUnfreePredicate
modules/
  home.mod.nix                 # hjem wiring
  nix.mod.nix                  # nix settings + gc
  darwin-desktop.mod.nix       # dock/finder/trackpad/NSGlobalDomain/screenshots
  fonts.mod.nix
  homebrew.mod.nix             # nix-homebrew + taps/brews/casks/masApps
  primary-user.mod.nix         # user identity / host-users
  apps.mod.nix (+ profile split)   # systemPackages, personal vs work
  version-control.mod.nix      # git homeModule (identity + base settings)
  difftastic.mod.nix           # theme-aware difft + git/jj diff integration
  web-browser.mod.nix          # Helium (minus Stylus)
  programs/                    # nushell, zoxide, starship, zed, atuin, jujutsu, aerospace, dotfiles
hosts/
  salusa.mod.nix
  caladan.mod.nix
  ix.mod.nix
  rossak.mod.nix
  landerb-mac2.mod.nix
docs/superpowers/specs/        # this spec
```

### `flake.nix`

- `inputs.flake-parts.lib.mkFlake` with `specialArgs.lib` extended by
  `import ./lib`.
- `nixConfig` enabling at least `nix-command flakes pipe-operators` (needed for
  `|>` / `<|` used by ported modules). Substituters optional.
- `systems = [ "aarch64-darwin" ]` (darwin-only; add others only if needed).
- `imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./.)`.
- **Inputs:** `nixpkgs` (unstable), `nix-darwin`, `flake-parts`, `hjem`,
  `hjem-rum`, `nix-homebrew` + `homebrew-core`/`homebrew-cask`, `themes`
  (RGBCube/ThemeNix), `helium` (amaanq/helium-flake), `ublock`
  (imputnet/uBlock, `flake = false`). Drop home-manager.

### `lib/systems.nix` — the `darwinSystem` builder (new)

Signature: `darwinSystem hostName profile module`. It:

1. Calls `nix-darwin.lib.darwinSystem` with `specialArgs.lib` = extended lib.
2. Module set = `attrValues self.commonModules`
   + selected `self.darwinModules` (profile-filtered)
   + a fragment setting `home.extraModules = attrValues (profile-filtered self.homeModules)`
     (hjem's darwin module provides the `home` namespace)
   + `networking.hostName = hostName` and the host's own module.
3. Registers `flake.darwinConfigurations.${hostName}`.

**Profiles:** `personal` and `work` are named selectors that decide which
darwin/home modules (and which app lists) are included — replacing the current
`hostProfiles`/`hostConfigs` maps. Per-host identity (username, email) is set in
the host's `.mod.nix`.

### `options/flake-outputs.mod.nix`

Port ncc's registry verbatim: `flake.commonModules`, `flake.darwinModules`,
`flake.homeModules` as `lazyAttrsOf deferredModule`, each wrapped to set
`_file` and preserve `meta`. (Drop `modularServices` and the nixos variants
unless needed.)

### `modules/home.mod.nix` — hjem wiring

Mirror ncc:

- `flake.darwinModules.home = inputs.hjem.darwinModules.hjem;`
- `flake.commonModules.home`: `imports` an alias `home` → `hjem`; sets
  `home.specialArgs = { inherit lib; }`, `home.extraModules = [ hjem-rum ]`,
  `home.clobberByDefault = true`.
- `flake.homeModules.home`: alias `programs` → `rum.programs`; force XDG env
  vars to darwin paths (`~/.cache`, `~/.config`, `~/.local/share`,
  `~/.local/state`).
- Per-user assignment: the host modules set `home.users.${username}` to include
  the selected home modules (via `home.extraModules` in the builder).

### `options/theme.mod.nix` + `options/unfree.mod.nix`

- **theme:** port ncc's `commonModules.theme` (and `homeModules.theme` alias),
  backed by `inputs.themes`. Default to a dark theme (gruvbox-dark-hard or
  user's choice) with `cornerRadius`, fonts, etc. Consumed by difftastic
  (`theme.isDark`) and jj graph style (`theme.cornerRadius`).
- **unfree:** port `allowedUnfreePackageNames` → `allowUnfreePredicate`. Seed
  the list with the unfree packages currently pulled in (claude, spotify,
  vscode-adjacent, etc.) so `allowUnfree = true` can be replaced by an explicit
  allowlist. (If maintaining the list proves noisy, fall back to
  `allowUnfree = true` — decided during implementation.)

## Program ports (home layer)

### Via hjem-rum `programs.*`
- **nushell:** `extraConfig` (ssh-agent env snippet), `settings`
  (`show_banner=false`, `edit_mode="vi"`, binary filesize, cursor shapes),
  `aliases`. Atuin/zoxide/starship init lines integrated.
- **zoxide:** enable + nushell integration (and `--cmd cd` if desired).
- **starship:** port the user's `settings` (directory length, time format,
  gcloud disabled) + nushell integration.
- **zed:** `programs.zed` (hjem-rum `zed.nix`) with the user's `userSettings`
  (vim mode, Berkeley Mono fonts, telemetry off, nix/rust LSP config) and
  `extensions`. **Validation step:** confirm hjem-rum's zed schema can express
  `userSettings`/`extensions`/`package = null`; if not, write
  `~/.config/zed/settings.json` via `xdg.config.files` instead.

### Via raw config files (no hjem-rum module)
- **atuin:** write `~/.config/atuin/config.toml` (style = compact) via
  `xdg.config.files`; append `atuin init nu` output to nushell config to
  replicate `enableNushellIntegration`.
- **jujutsu:** write `jj/config.toml` via a TOML generator (`writeTOML`) from
  the user's **existing** `dotfiles/jj/config.toml` (identity, ssh signing,
  watchman fsmonitor, rustfmt fix tool). The difftastic module merges its
  `ui.diff-formatter` / diff settings into the same file.
- **aerospace:** **kept disabled** (matching today). Port the settings
  structure via nix-darwin's `services.aerospace` (a darwin-level service),
  `enable = false`, ready to flip on later. Keybindings/workspaces/window rules
  preserved from the current `programs.aerospace.settings`.

### Dotfiles via hjem `files` / `xdg.config.files`
hammerspoon (fetched SpoonInstall + PaperWM spoons placed under
`.hammerspoon/Spoons`, plus `init.lua`), nvim `init.vim`, `wezterm.lua`,
`rustfmt.toml`, `.zshrc` / `.zprofile` / `.profile`, `.cargo/config.toml`
(currently generated text), and the claude skills directory.

## The three yoinks

### 1. Screenshots
In `darwin-desktop.mod.nix`:
`system.defaults.screencapture.location = "~/Downloads/Screenshots";`
Replaces the current
`CustomUserPreferences."com.apple.screencapture".location = "~/Desktop/screenshots"`.
(Note: only affects built-in ⌘⇧3/4; CleanShot has its own setting.)

### 2. difftastic (`modules/difftastic.mod.nix`, homeModule)
Port ncc's module:
- `difft` = `writeShellScriptBin` wrapping `difftastic` with
  `--background ${if theme.isDark then "dark" else "light"}`.
- `packages = [ difft ]`.
- Git integration: `git/config` `diff.external = difft`, `diff.tool`,
  `difftool.difftastic.cmd` — written via `xdg.config.files."git/config".value`
  so it **merges** with the identity set by `version-control.mod.nix`.
- jj integration: `jj/config.toml` `ui.diff-formatter = [ difft --color always
  $left $right ]`, merged into the jj config.

### 3. Helium (`modules/web-browser.mod.nix`)
Port ncc's module **verbatim except removing `extensions.stylus`**:
- Add `inputs.helium` and `inputs.ublock`.
- **darwinModule:** activation script (via `lib.shell.asShell` + nushell)
  writing `/Library/Managed Preferences/net.imput.helium.plist` and per-extension
  policy plists, then `chown root:wheel` / `chmod 0644`, then sets Helium as
  default browser via `defaultbrowser`.
- **homeModule:** writes the Helium `Preferences` JSON (layout, onboarding,
  bookmark bar, download prompt) and installs the Helium package.
- Keeps ncc's defaults as-is: Kagi default search, uBlock filter lists +
  custom filters, bookmarklet folders (Archive/Reverse Image/Nuke/Toggle), and
  the extension set: consent-o-matic, ublock-origin, dearrow, sponsorblock,
  dark-reader, refined-github, violentmonkey, vimium-c, floccus, kagi,
  keepassxc-browser. **Stylus removed.**

## Open flags (defaults chosen; tune post-migration)
- Helium ships Kagi as default search and several extensions tied to external
  services (floccus sync, kagi, keepassxc-browser). Full port keeps them;
  prune later if unused.
- Helium `RestoreOnStartup` / session-restore is macOS-limited (documented in
  ncc's inline comments); ported as-is.
- `unfree` allowlist vs blanket `allowUnfree = true` — start with allowlist,
  fall back if noisy.

## Phased implementation (Strategy B — hjem from the start)

Each phase ends with a `jj commit` and a `darwin-rebuild build --flake .#<canary-host>`
(build, not switch). No push; `main` stays at `a9f2dbb` until full cutover.

- **Phase 1 — Scaffolding.** `flake.nix` (flake-parts, import-tree, nixConfig,
  inputs incl. hjem/hjem-rum/themes/helium/ublock/nix-homebrew), `lib/`
  (default, shell, generators, systems with `darwinSystem`), `options/`
  (flake-outputs, theme, unfree), `modules/home.mod.nix` hjem wiring. Prove one
  trivial host builds.
- **Phase 2 — Darwin system concerns.** `nix.mod.nix`, `darwin-desktop.mod.nix`
  (incl. screenshots → Downloads/Screenshots), `fonts.mod.nix`,
  `homebrew.mod.nix` (nix-homebrew), `primary-user.mod.nix`, touchID sudo,
  shells.
- **Phase 3 — Home programs.** nushell/zoxide/starship/zed via hjem-rum;
  atuin/jujutsu/aerospace + all dotfiles via `files`. Verify the canary host's
  home generation matches today's behaviour.
- **Phase 4 — Yoinked features.** difftastic module, version-control (git
  identity), Helium full port (minus Stylus).
- **Phase 5 — Hosts & profiles.** All 5 hosts as `.mod.nix` with personal/work
  profile selection; build each; then cut over (`switch`, advance `main`).

## Verification
- Per phase: `darwin-rebuild build --flake .#<host>` succeeds (use the current
  machine as canary).
- Phase 3 acceptance: shell startup, atuin history, zoxide, starship prompt,
  zed settings, jj all behave as before.
- Phase 4 acceptance: `git diff` / `jj diff` render via difftastic with correct
  theme; Helium launches with policies/extensions applied and Stylus absent.
- Final: every host in `darwinConfigurations` builds; `switch` on the canary
  succeeds; `main` advanced only after that.

## Risks
- **Framework swap (home-manager → hjem):** the largest risk. hjem-rum's module
  schemas differ from home-manager's; zed in particular may need raw-file
  fallback. Mitigated by phased, per-host build verification and keeping `main`
  untouched until cutover.
- **Pipe operators / lib extension** must be enabled before any ported module
  evaluates — handled in Phase 1.
- **Helium activation script** runs as root and writes to
  `/Library/Managed Preferences`; first run requires privileges and sets the
  default browser. Test on the canary before other hosts.
