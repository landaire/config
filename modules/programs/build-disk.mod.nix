{
  # richese keeps build artifacts on a dedicated NVMe mounted at /var/mnt/build
  # (btrfs, zstd, nofail in /etc/fstab), off the system drive.
  flake.homeModules.build-disk =
    { lib, pkgs, ... }:
    let
      buildDisk = "/var/mnt/build";

      # buck2 always writes to <project root>/buck-out and has no setting to put
      # it elsewhere. A symlink does not work either: buck-out holds relative
      # symlinks back into the source tree, which break once buck-out resolves
      # to another directory. A bind mount keeps the path, so it is the only
      # way to move it.
      buckOutScript = pkgs.writeText "buck-out-to-build-disk.nu" /* nu */ ''
        const build_disk = "${buildDisk}"
        const findmnt = "${pkgs.util-linux}/bin/findmnt"
        const mount = "${pkgs.util-linux}/bin/mount"

        def main [repo: string --discard] {
          let repo = $repo | path expand
          if not ($repo | path join ".buckconfig" | path exists) {
            error make { msg: $"($repo) has no .buckconfig" }
          }
          if ($repo =~ '\s') {
            error make { msg: $"($repo) contains whitespace, which fstab cannot hold" }
          }
          let disk = ^$findmnt --mountpoint $build_disk --json | complete
          if $disk.exit_code != 0 {
            error make { msg: $"($build_disk) is not mounted" }
          }

          let target = $repo | path join "buck-out"
          let name = $repo | path relative-to ($env.HOME | path expand) | str replace --all "/" "-"
          let source = $build_disk | path join "buck-out" $name

          let bound = ^$findmnt --mountpoint $target --json | complete
          if $bound.exit_code == 0 {
            print $"($target) is already a mount point"
            return
          }

          # The daemon holds buck-out open; stop it before moving anything.
          # Projects pin buck2 through bin/buck2; fall back to the one on PATH.
          let buck2 = if ($repo | path join "bin" "buck2" | path exists) { $repo | path join "bin" "buck2" } else { "buck2" }
          do --ignore-errors { cd $repo; ^$buck2 kill } | complete | ignore

          mkdir $source
          if ($target | path type) == "symlink" {
            rm $target
          }
          if ($target | path exists) {
            if $discard {
              rm -rf $target
            } else {
              print $"moving ($target) to ($source)"
              ls --all $target | get name | each {|entry| mv $entry $source } | ignore
              rm -rf $target
            }
          }
          mkdir $target

          let line = $"($source) ($target) none bind,nofail,x-systemd.requires-mounts-for=($build_disk) 0 0"
          let fstab = open --raw /etc/fstab | lines
          if not ($fstab | any {|l| ($l | split row --regex '\s+' | get --optional 1) == $target }) {
            $line | ^sudo tee -a /etc/fstab | ignore
            ^sudo systemctl daemon-reload
          }
          ^sudo $mount $target
          print $"($target) now lives on ($source)"
        }
      '';
    in
    {
      # Replaces the default build-dir from the dotfiles module on this host.
      xdg.data.files."cargo/config.toml".text = lib.mkForce ''
        [build]
        build-dir = "${buildDisk}/cargo"
      '';

      programs.nushell.extraConfig = /* nu */ ''
        # Move a buck2 project's buck-out onto the build disk with a bind mount
        # recorded in /etc/fstab. Existing artifacts are moved unless --discard.
        def buck-out-to-build-disk [
          repo: path = "." # Project root (contains .buckconfig)
          --discard # Delete the existing buck-out instead of moving it
        ] {
          let discard_arg = if $discard { ["--discard"] } else { [] }
          ^${pkgs.nushell}/bin/nu --no-config-file ${buckOutScript} $repo ...$discard_arg
        }
      '';
    };
}
