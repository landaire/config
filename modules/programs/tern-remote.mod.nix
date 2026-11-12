{
  # Tern's remote service for this user, as `tern remote install --user`
  # writes it. Tern is not packaged in nix: ExecStart runs the downloaded build
  # that ~/.local/bin/tern links to, and `tern remote update` replaces that
  # build in place and restarts the service.
  #
  # Linger (set by richese-provision) starts the user manager, and so this
  # service, at boot without a login.
  flake.homeModules.tern-remote =
    { pkgs, ... }:
    let
      # The unit sits in a directory under its own name: systemd expects a
      # .wants symlink to point at a file of the same name.
      unit = pkgs.writeTextDir "tern-remote.service" ''
        [Unit]
        Description=Tern remote sessions (this user)
        Documentation=https://stencil.so
        StartLimitIntervalSec=60
        StartLimitBurst=10

        [Service]
        Type=exec
        ExecStart=%h/.local/bin/tern remote serve --user --state-dir %h/.config/tern
        Restart=on-failure
        RestartSec=2
        # Bad arguments do not fix themselves by restarting.
        RestartPreventExitStatus=2
        # Stopping the service leaves the session daemon and its shells running.
        KillMode=process
        TimeoutStopSec=10

        [Install]
        WantedBy=default.target
      '';
      unitFile = "${unit}/tern-remote.service";
    in
    {
      xdg.config.files."systemd/user/tern-remote.service".source = unitFile;
      xdg.config.files."systemd/user/default.target.wants/tern-remote.service".source = unitFile;
    };
}
