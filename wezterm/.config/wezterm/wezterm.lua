local wezterm = require 'wezterm'

return {
  color_scheme = 'Catppuccin Mocha',
  font = wezterm.font('JetBrainsMono Nerd Font'),
  font_size = 12.5,
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  window_decorations = 'RESIZE',
  window_padding = { left = 8, right = 8, top = 8, bottom = 8 },
  keys = {
    { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  },
}
