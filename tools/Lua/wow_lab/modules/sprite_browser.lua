-- modules/sprite_browser.lua
-- Wizard of Wor Lab sprite-browser module entry point.

local M = {}
M.VERSION = '0.1.0-20260817-0846'

function M.start(lab)
  lab:show_module_page('SPRITE BROWSER', {
    'MODULE SLOT ACTIVE',
    '',
    'OBJECT AND SPRITE DATA',
    'RENDERING TEST BED',
    'IMPLEMENTATION TARGET',
  })
end

return M
