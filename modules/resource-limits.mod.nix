{
  # Everything started from the tern terminal (shells, agents, builds, the
  # watchman they spawn) shares tern's app unit cgroup. Capping it keeps a
  # runaway job from exhausting RAM and freezing the desktop: past MemoryMax the
  # kernel OOM-kills the largest process inside tern instead. OOMPolicy=continue
  # keeps systemd from then stopping the whole unit (every tab with it), which
  # is the service default.
  #
  # The template drop-in also applies to the transient app-so.stencil.tern@<id>
  # units the desktop launcher creates.
  flake.homeModules.resource-limits = {
    xdg.config.files."systemd/user/app-so.stencil.tern@.service.d/50-memory.conf".text = ''
      [Service]
      MemoryMax=80%
      OOMPolicy=continue
    '';
  };
}
