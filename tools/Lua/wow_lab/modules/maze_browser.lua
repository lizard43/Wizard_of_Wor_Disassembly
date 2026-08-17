-- modules/040_maze_browser.lua
-- Wizard of Wor Lab maze-browser module entry point.

return {
  start = function(lab)
    lab:show_module_page('MAZE BROWSER', {
      'MODULE SLOT ACTIVE',
      '',
      'MAZE TABLE AND DRAWING',
      'ROUTINE TEST BED',
      'IMPLEMENTATION TARGET',
    })
  end,
}
