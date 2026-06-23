local wezterm = require("wezterm")

local conf = {
  font = wezterm.font_with_fallback({
    "FiraCode Nerd Font", -- macOS Homebrew cask: font-fira-code-nerd-font
    "Fira Code",          -- plain Fira Code (font-fira-code / Linux fonts-firacode)
    "FiraCode Nerd Font Mono",
  }),
  -- Different machines have different ones of the above installed; wezterm uses
  -- the first that exists. This silences the "Unable to load a font" popup for
  -- the entries that aren't present on a given machine.
  warn_about_missing_glyphs = false,
  font_size = 16.0,
  color_scheme = "Catppuccin Frappe",
  hide_tab_bar_if_only_one_tab = true,
  window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.25cell",
    bottom = "0.25cell",
  },
  keys = {
    { key = "Enter", mods = "SHIFT", action = wezterm.action { SendString = "\x1b\r" } },
  }

}

-- letters with ctrl- binding in vim or tmux that I want to use with CMD in mac
local modified_keys = { 'a', 'c', 'd', 'f', 'h', 'k', 'j', 'l', 'n', 'r', 's', 'x', 'w' }
for _, k in ipairs(modified_keys) do
  table.insert(conf.keys,
    { key = k, mods = "CMD", action = wezterm.action { SendKey = { key = k, mods = "CTRL" } } }
  )
end

return conf
