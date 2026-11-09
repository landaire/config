{
  flake.homeModules.nushell = { config, ... }: {
    programs.nushell = {
      enable = true;

      extraConfig = /* nu */ ''
        # cargo install puts binaries in $CARGO_HOME/bin (see use-xdg-dirs).
        $env.PATH = $env.PATH | prepend "${config.xdg.data.directory}/cargo/bin"

        let radicle_nodes_path = $env.HOME | path join ".config" "radicle" "nodes.json"
        if ($radicle_nodes_path | path exists) {
          $env.RADICLE_NODES = open $radicle_nodes_path
        }

        def radicle-node [name: string]: nothing -> record {
          let nodes = $env.RADICLE_NODES? | default {}
          let node = $nodes | get --optional $name
          if $node == null {
            error make {msg: $"unknown Radicle node: ($name)"}
          }
          $node
        }

        def "rad-node connect" [name: string] {
          let node = radicle-node $name
          ^rad node connect $"($node.nid)@($node.address)"
        }

        def "rad-node inventory" [name: string] {
          let node = radicle-node $name
          ^rad node inventory --nid $node.nid
        }

        def "rad-node clone" [name: string, rid: string, ...args: string] {
          let node = radicle-node $name
          let signed_refs = $node | get --optional signed_refs_feature_level
          let signed_refs_args = if $signed_refs == null {
            []
          } else {
            ["--signed-refs-feature-level" $signed_refs]
          }
          ^rad clone ...$signed_refs_args --seed $node.nid $rid ...$args
        }

        ^ssh-agent -c
         | lines
         | first 2
         | parse "setenv {name} {value};"
         | transpose -r
         | into record
         | load-env
      '';

      settings = {
        show_banner = false;
        edit_mode = "vi";
        filesize.unit = "binary";
        cursor_shape = {
          emacs = "blink_line";
          vi_insert = "blink_line";
          vi_normal = "blink_block";
        };
      };
    };
  };
}
