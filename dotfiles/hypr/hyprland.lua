local terminal = "env -u WAYLAND_DISPLAY tern"
local browser = "helium"
local fileManager = "dolphin"
local menu = "fuzzel"
local mainMod = "SUPER"

local function setCaptureMode(mainMode, mainScale, captureMode)
    hl.monitor({
        output = "DP-2",
        mode = mainMode,
        position = "0x0",
        scale = mainScale,
    })
    hl.monitor({
        output = "HDMI-A-2",
        mode = captureMode,
        position = "0x0",
        scale = 1,
        disabled = false,
        mirror = "DP-2",
    })
end

local function setNativeMode()
    setCaptureMode("3440x1440@174.963", 1, "2560x1440@240")
end

local function disableCaptureOutput()
    hl.monitor({
        output = "HDMI-A-2",
        disabled = true,
    })
end

setCaptureMode("2560x1440@119.88", 1, "2560x1440@240")
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Breeze-Dark")
    hl.exec_cmd("plasma-apply-colorscheme BreezeDark")
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
end)

hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = "rgba(d79921ff)",
            inactive_border = "rgba(3c3836ff)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 4,
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = 0xaa1d2021,
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.1,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = 0xff282828,
    },
    cursor = {
        no_hardware_cursors = 2,
    },
})

hl.curve("quick", { type = "bezier", points = { { 0.2, 0.8 }, { 0.2, 1.0 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "quick" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "quick" })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + R", hl.dsp.layout("movetoroot"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("rotatesplit"))
hl.bind(mainMod .. " + SHIFT + F1", function()
    setNativeMode()
    hl.dispatch(hl.dsp.focus({ monitor = "DP-2" }))
end, { description = "Native ultrawide mode" })
hl.bind(mainMod .. " + SHIFT + F2", function()
    setCaptureMode("2560x1440@119.88", 1, "2560x1440@240")
    hl.dispatch(hl.dsp.focus({ monitor = "DP-2" }))
end, { description = "Capture mode: 1440p" })
hl.bind(mainMod .. " + SHIFT + F3", function()
    -- The Dell blanks on its 1920x1080 timing. A 4/3 scale on its 2560x1440
    -- timing gives the same 1920x1080 logical desktop.
    setCaptureMode("2560x1440@119.88", 4 / 3, "1920x1080@240")
    hl.dispatch(hl.dsp.focus({ monitor = "DP-2" }))
end, { description = "Capture mode: 1080p" })
hl.bind(mainMod .. " + SHIFT + F4", function()
    disableCaptureOutput()
    hl.dispatch(hl.dsp.focus({ monitor = "DP-2" }))
end, { description = "Disable capture output" })

local directions = {
    H = "left",
    J = "down",
    K = "up",
    L = "right",
}
for key, direction in pairs(directions) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

local resizeDeltas = {
    H = { -40, 0 },
    J = { 0, 40 },
    K = { 0, -40 },
    L = { 40, 0 },
}
for key, delta in pairs(resizeDeltas) do
    hl.bind(
        mainMod .. " + CTRL + " .. key,
        hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }),
        { repeating = true }
    )
end

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | wl-copy"))
