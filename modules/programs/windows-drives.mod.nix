{
  flake.homeModules.windows-drives =
    { pkgs, ... }:
    let
      driveScript = pkgs.writeText "windows-drive.nu" /* nu */ ''
        const findmnt = "${pkgs.util-linux}/bin/findmnt"
        const id = "${pkgs.coreutils}/bin/id"
        const mkdir = "${pkgs.coreutils}/bin/mkdir"
        const mount = "${pkgs.util-linux}/bin/mount"
        const realpath = "${pkgs.coreutils}/bin/realpath"
        const umount = "${pkgs.util-linux}/bin/umount"

        def windows-drive-spec [drive: string] {
          let letter = $drive | str trim | str lowercase
          let volumes = {
            c: "F456FC3D56FC01E2"
            d: "847AA48A7AA47B16"
            e: "081E13F51E13DA90"
            g: "06F82043F82032FB"
          }
          if $letter not-in ($volumes | columns) {
            error make {
              msg: $"unknown Windows drive '($drive)'; expected C, D, E, or G"
            }
          }

          {
            letter: $letter
            uuid: ($volumes | get $letter)
          }
        }

        def --wrapped findmnt-filesystems [...args] {
          let result = ^($findmnt) ...$args --json | complete
          if $result.exit_code == 0 {
            $result.stdout | from json | get filesystems
          } else {
            let diagnostic = [$result.stdout $result.stderr] | str join "\n" | str trim
            if $result.exit_code == 1 and ($diagnostic | is-empty) {
              []
            } else {
              let detail = if ($diagnostic | is-empty) { "no diagnostic" } else { $diagnostic }
              error make {
                msg: $"findmnt failed with exit code ($result.exit_code): ($detail)"
              }
            }
          }
        }

        def assert-canonical-mount-path [mount_point: string] {
          let resolved = ^($realpath) --canonicalize-missing -- $mount_point | str trim
          if $resolved != $mount_point {
            error make {
              msg: $"refusing noncanonical mount path ($mount_point), which resolves to ($resolved)"
            }
          }
        }

        def assert-windows-mount-target [target: string uuid: string] {
          let live = findmnt-filesystems --target $target --direction backward --first-only --output TARGET,UUID,FSTYPE
          if ($live | is-empty) {
            error make {
              msg: $"($target) is no longer a mount target"
            }
          }

          let filesystem = $live | first
          if $filesystem.target != $target or $filesystem.uuid != $uuid or $filesystem.fstype != "ntfs3" {
            error make {
              msg: $"($target) resolves to mount ($filesystem.target), UUID=($filesystem.uuid), ($filesystem.fstype); expected that exact target with UUID=($uuid) as ntfs3"
            }
          }
        }

        def mount-windows-drive-locked [drive: string write: bool] {
          let spec = windows-drive-spec $drive
          let mount_point = $"/var/mnt/($spec.letter)"
          assert-canonical-mount-path $mount_point

          let canonical = findmnt-filesystems --mountpoint $mount_point --output SOURCE,UUID,FSTYPE
          if ($canonical | any {|filesystem| $filesystem.uuid != $spec.uuid or $filesystem.fstype != "ntfs3" }) {
            let filesystem = $canonical | first
            error make {
              msg: $"($mount_point) contains ($filesystem.source) as ($filesystem.fstype); refusing to mount UUID=($spec.uuid)"
            }
          }

          let user_id = ^($id) -u | str trim
          let group_id = ^($id) -g | str trim
          let mounts = findmnt-filesystems --source $"UUID=($spec.uuid)" --output TARGET,UUID,FSTYPE,OPTIONS

          if ($mounts | is-not-empty) {
            if ($mounts | any {|mounted| $mounted.uuid != $spec.uuid or $mounted.fstype != "ntfs3" }) {
              error make {
                msg: $"findmnt returned a mount that does not match UUID=($spec.uuid) as ntfs3"
              }
            }

            let targets = $mounts | get target
            if ($targets | uniq | length) != ($targets | length) {
              error make {
                msg: $"UUID=($spec.uuid) has multiple mounts at the same target; unmount it before changing mount options"
              }
            }

            let mount_states = $mounts | each {|mounted|
              let options = $mounted.options | split row ","
              {
                mounted: $mounted
                options: $options
                writable: ("rw" in $options)
                masks_execute: ($options | any {|option| $option in ["fmask=0111" "fmask=111"] })
              }
            }
            let requires_remount = $mount_states | any {|state| ($write and not $state.writable) or not $state.masks_execute }
            for state in ($mount_states | sort-by writable) {
              assert-windows-mount-target $state.mounted.target $spec.uuid
              if $requires_remount {
                let access = if $write or $state.writable { "rw" } else { "ro" }
                let preserved_options = $state.options | where {|option| $option not-in ["ro" "rw" "remount"] and not ($option | str starts-with "fmask=") }
                let remount_options = ["remount" $access "fmask=0111"]
                  | append $preserved_options
                  | str join ","
                ^sudo $mount -t ntfs3 -o $remount_options $"UUID=($spec.uuid)" $state.mounted.target
                print $"($spec.letter | str uppercase): remounted ($access) at ($state.mounted.target)"
              } else {
                let access = if $state.writable { "read-write" } else { "read-only" }
                print $"($spec.letter | str uppercase): is already mounted ($access) at ($state.mounted.target)"
              }
            }
            return
          }

          if ($canonical | is-not-empty) {
            error make {
              msg: $"($mount_point) contains UUID=($spec.uuid), but findmnt did not return it by source"
            }
          }

          let access = if $write { "rw" } else { "ro" }
          ^sudo $mkdir -p $mount_point
          assert-canonical-mount-path $mount_point
          ^sudo $mount -t ntfs3 -o $"($access),uid=($user_id),gid=($group_id),fmask=0111" $"UUID=($spec.uuid)" $mount_point
        }

        def unmount-windows-drive-locked [drive: string] {
          let spec = windows-drive-spec $drive
          let mounts = findmnt-filesystems --source $"UUID=($spec.uuid)" --output TARGET,UUID
          if ($mounts | is-empty) {
            print $"($spec.letter | str uppercase): is not mounted"
            return
          }

          if ($mounts | any {|mounted| $mounted.uuid != $spec.uuid }) {
            error make {
              msg: $"findmnt returned a filesystem other than UUID=($spec.uuid)"
            }
          }

          let ordered_mounts = $mounts
            | enumerate
            | each {|entry| {
              mounted: $entry.item
              depth: ($entry.item.target | path split | length)
              order: $entry.index
            }}
            | sort-by --reverse depth order
          for entry in $ordered_mounts {
            assert-windows-mount-target $entry.mounted.target $spec.uuid
            ^sudo $umount -- $entry.mounted.target
            print $"($spec.letter | str uppercase): unmounted ($entry.mounted.target)"
          }
        }

        def main [operation: string drive: string --write] {
          if $operation == "mount" {
            mount-windows-drive-locked $drive $write
          } else if $operation == "unmount" {
            unmount-windows-drive-locked $drive
          } else {
            error make {
              msg: $"unknown Windows drive operation '($operation)'"
            }
          }
        }
      '';
    in
    {
      programs.nushell.extraConfig = /* nu */ ''
        def mount-windows-drive [
          drive: string # Windows drive letter: C, D, E, or G
          --write (-w) # Mount read-write instead of read-only
        ] {
          let lock_file = $"/run/user/(^${pkgs.coreutils}/bin/id -u | str trim)/windows-drives.lock"
          let write_arg = if $write { ["--write"] } else { [] }
          ^${pkgs.util-linux}/bin/flock --exclusive $lock_file ${pkgs.nushell}/bin/nu --no-config-file ${driveScript} mount $drive ...$write_arg
        }

        def unmount-windows-drive [
          drive: string # Windows drive letter: C, D, E, or G
        ] {
          let lock_file = $"/run/user/(^${pkgs.coreutils}/bin/id -u | str trim)/windows-drives.lock"
          ^${pkgs.util-linux}/bin/flock --exclusive $lock_file ${pkgs.nushell}/bin/nu --no-config-file ${driveScript} unmount $drive
        }
      '';
    };
}
