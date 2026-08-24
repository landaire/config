# PipeWire / WirePlumber audio routing for richese (linux-only home module).
#
# Default output: "headphones_and_elgato" combines the Fiio headphones and the
# GPU HDMI feed to the Elgato, and is pinned as default (high priority.session).
# So general/system audio is heard AND captured on the Elgato.
#
# Per-app VBAN splits: each app in `vbanApps` gets its own VBAN stream (distinct
# name, shared port 6980) while playing in the Fiio headphones only (NOT the
# Elgato). A "<key>_split" combine sink fans the app out to the Fiio plus a
# dedicated "vban-<key>" sender. A WirePlumber hook (route-apps.lua) auto-routes matched
# apps to their split sink by writing target.object into the "default" metadata;
# unlike pulse.rules this also covers native PipeWire clients (e.g. Spotify).
#
# VBAN mic: "vban-mic" sink only. Wire "Shure MV7 -> VBAN Mic" in qpwgraph and
# save it; the mic is sent over VBAN only while that patch is active.
{ lib, ... }:
let
  inherit (lib.strings) concatMapStringsSep;

  receiverIp = "192.168.1.140";
  # All VBAN streams share one port; the receiver demuxes them by stream name.
  receiverPort = 6980;

  fiioSink = "alsa_output.usb-FiiO_DigiHug_USB_Audio-01.analog-stereo";
  hdmiSink = "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1";
  defaultSink = "headphones_and_elgato";

  # Apps diverted onto their own VBAN stream. `pattern` is a lowercase substring
  # matched against application.name / application.process.binary. Add apps here
  # to extend.
  vbanApps = [
    {
      key = "spotify";
      label = "Spotify";
      pattern = "spotify";
    }
    {
      key = "discord";
      label = "Discord";
      pattern = "discord";
    }
    {
      key = "helium";
      label = "Helium";
      pattern = "helium";
    }
    {
      # Steam client + games that identify as Steam. Individual games often do
      # not; route those to "game_split" manually (qpwgraph) or add a pattern.
      key = "game";
      label = "Game";
      pattern = "steam";
    }
  ];

  mkAppSplit = app: ''
    {
      name = libpipewire-module-vban-send
      args = {
        destination.ip = "${receiverIp}"
        destination.port = ${toString receiverPort}

        sess.name = "${app.label}"
        sess.media = "audio"

        audio.format = "S16LE"
        audio.rate = 48000
        audio.channels = 2
        audio.position = [ FL FR ]

        stream.props = {
          node.name = "vban-${app.key}"
          node.description = "VBAN ${app.label}"
          node.autoconnect = false
        }
      }
    }

    {
      name = libpipewire-module-combine-stream
      args = {
        combine.mode = sink
        node.name = "${app.key}_split"
        node.description = "${app.label} (split)"

        combine.props = {
          audio.position = [ FL FR ]
        }

        stream.rules = [
          {
            matches = [
              { node.name = "${fiioSink}" }
              { node.name = "vban-${app.key}" }
            ]
            actions = {
              create-stream = { }
            }
          }
        ]
      }
    }
  '';

  routesLua = concatMapStringsSep "\n" (
    app: ''    { pattern = "${app.pattern}", target = "${app.key}_split" },''
  ) vbanApps;

  micConf = ''
    context.modules = [
      {
        name = libpipewire-module-vban-send
        args = {
          destination.ip = "${receiverIp}"
          destination.port = ${toString receiverPort}

          sess.name = "Mic"
          sess.media = "audio"

          audio.format = "S16LE"
          audio.rate = 48000
          audio.channels = 1
          audio.position = [ MONO ]

          stream.props = {
            node.name = "vban-mic"
            node.description = "VBAN Mic"
            # No default-source auto-link; wire Shure MV7 -> VBAN Mic in
            # qpwgraph. This is the toggle.
            node.autoconnect = false
          }
        }
      }
    ]
  '';

  appSplitsConf = ''
    context.modules = [
    ${concatMapStringsSep "\n" mkAppSplit vbanApps}
    ]
  '';

  # Default sink: general/system audio -> Fiio headphones + Elgato HDMI. A high
  # priority.session makes WirePlumber pick this as the default over the raw
  # hardware sinks and the per-app split sinks.
  mainCombineConf = ''
    context.modules = [
      {
        name = libpipewire-module-combine-stream
        args = {
          combine.mode = sink
          node.name = "headphones_and_elgato"
          node.description = "Headphones + Elgato"
          priority.session = 2000

          combine.latency-compensate = true

          combine.props = {
            audio.position = [ FL FR ]
          }

          stream.rules = [
            {
              matches = [
                { node.name = "${fiioSink}" }
                { node.name = "${hdmiSink}" }
              ]
              actions = {
                create-stream = { }
              }
            }
          ]
        }
      }
    ]
  '';

  # Loaded from the data-dir scripts path (WP does not search the config dir).
  routeScript = ''
    -- Route matched application streams to a target sink via the "default"
    -- metadata. Works for native AND pulse clients (pipewire-pulse's pulse.rules
    -- only cover pulse clients; native ones like Spotify bypass them). Also pins
    -- the configured default sink (overrides stale stored state each start).
    routes = {
    ${routesLua}
    }
    default_sink = "${defaultSink}"

    sinks_om = ObjectManager {
      Interest { type = "node",
        Constraint { "media.class", "=", "Audio/Sink", type = "pw-global" } }
    }
    metadata_om = ObjectManager {
      Interest { type = "metadata",
        Constraint { "metadata.name", "=", "default" } }
    }
    streams_om = ObjectManager {
      Interest { type = "node",
        Constraint { "media.class", "=", "Stream/Output/Audio", type = "pw-global" } }
    }

    function routeNode(node)
      local props = node.properties
      local nname = props["node.name"] or ""
      -- Skip module-combine-stream's own internal output streams.
      if string.sub(nname, 1, 7) == "output." then return end
      local name = string.lower(props["application.name"] or "")
      local bin = string.lower(props["application.process.binary"] or "")
      for _, r in ipairs(routes) do
        if string.find(name, r.pattern, 1, true) or string.find(bin, r.pattern, 1, true) then
          local sink = sinks_om:lookup {
            Constraint { "node.name", "=", r.target, type = "pw-global" } }
          local md = metadata_om:lookup {}
          if sink and md then
            md:set(node["bound-id"], "target.object", "Spa:Id",
                sink.properties["object.serial"])
            Log.info(node, "route-apps: " .. tostring(nname) .. " -> " .. r.target)
          end
          return
        end
      end
    end

    function setDefaultSink(md)
      md:set(0, "default.configured.audio.sink", "Spa:String:JSON",
          '{"name":"' .. default_sink .. '"}')
      Log.info("route-apps: default sink -> " .. default_sink)
    end

    streams_om:connect("object-added", function (_, node) routeNode(node) end)
    metadata_om:connect("object-added", function (_, md) setDefaultSink(md) end)
    sinks_om:activate()
    metadata_om:activate()
    streams_om:activate()
  '';

  routeComponentConf = ''
    wireplumber.components = [
      { name = route-apps.lua, type = script/lua }
    ]
  '';
  # Toggle for the one manual link (Shure MV7 -> VBAN Mic). Everything else
  # auto-links from config; this is the qpwgraph "activate" toggle as a CLI.
  micToggle = pkgs: pkgs.writers.writeNuBin "vban-mic" ''
    const SRC = "alsa_input.usb-Shure_Inc_Shure_MV7-00.mono-fallback:capture_MONO"
    const DST = "vban-mic:send_MONO"

    def is-on [] {
      (^pw-link -l $DST | complete | get stdout) =~ "mono-fallback"
    }

    def src-present [] {
      (^pw-link -o | complete | get stdout) =~ "Shure_Inc_Shure_MV7-00.mono-fallback"
    }

    def "main status" [] {
      if (is-on) { print "vban-mic: on" } else { print "vban-mic: off" }
    }

    def "main on" [] {
      if (is-on) {
        print "vban-mic: already on"
      } else if not (src-present) {
        print "vban-mic: Shure MV7 not found (connected and powered on?)"
      } else {
        ^pw-link $SRC $DST
        print "vban-mic: on"
      }
    }

    def "main off" [] {
      if (is-on) {
        ^pw-link -d $SRC $DST
        print "vban-mic: off"
      } else {
        print "vban-mic: already off"
      }
    }

    def "main toggle" [] {
      if (is-on) { main off } else { main on }
    }

    def main [] {
      print "usage: vban-mic (status|on|off|toggle)"
    }
  '';
in
{
  flake.homeModules.audio =
    { pkgs, ... }:
    {
      packages = [ (micToggle pkgs) ];

      xdg.config.files."pipewire/pipewire.conf.d/vban-mic.conf".text = micConf;
      xdg.config.files."pipewire/pipewire.conf.d/combine-headphones-elgato.conf".text = mainCombineConf;
      xdg.config.files."pipewire/pipewire.conf.d/vban-app-splits.conf".text = appSplitsConf;
      xdg.config.files."wireplumber/wireplumber.conf.d/52-route-apps.conf".text = routeComponentConf;
      xdg.data.files."wireplumber/scripts/route-apps.lua".text = routeScript;
    };
}
