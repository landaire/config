-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Afterglow'

-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
-- Sets the font for the window frame (tab bar)
config.window_frame = {
  -- Berkeley Mono for me again, though an idea could be to try a
  -- serif font here instead of monospace for a nicer look?
  font = wezterm.font({ family = 'TX-02', weight = 'Bold' }),
  font_size = 11,
}

config.automatically_reload_config = true

config.keys = {
  -- ... add these new entries to your config.keys table
  {
    key = 'r',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ReloadConfiguration,
  },
  {
    -- I like to use vim direction keybindings, but feel free to replace
    -- with directional arrows instead.
    key = 'j', -- or DownArrow
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection('Down'),
  },
  {
    key = 'k', -- or UpArrow
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection('Up'),
  },
  {
    key = 'h', -- or LeftArrow
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection('Left'),
  },
  {
    key = 'l', -- or RightArrow
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection('Right'),
  },
  {
    key = 'h',
    mods = 'LEADER|CTRL',
    -- "3" here is the amount of cells we wish to resize
    -- the terminal by
    action = wezterm.action.AdjustPaneSize { 'Left', 3 },
  },
}



-- and finally, return the configuration to wezterm
return config
