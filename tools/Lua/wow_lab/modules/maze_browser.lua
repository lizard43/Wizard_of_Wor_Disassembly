-- modules/maze_browser.lua
-- Wizard of Wor Lab maze-browser module entry point.

local M = {}
M.VERSION = '0.1.0-20260817-0846'

function M.start(lab)
  lab:show_module_page('MAZE BROWSER', {
    'MODULE SLOT ACTIVE',
    '',
    'MAZE TABLE AND DRAWING',
    'ROUTINE TEST BED',
    'IMPLEMENTATION TARGET',
  })
end

return M
