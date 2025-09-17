local wezterm = require("wezterm")

return {
  font = wezterm.font("Fira Code"),
  font_size = 13.0,
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
