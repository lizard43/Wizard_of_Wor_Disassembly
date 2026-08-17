-- modules/speech_browser.lua
-- Wizard of Wor Lab speech-browser module entry point.

local M = {}
M.VERSION = '0.1.0-20260817-0846'

function M.start(lab)
  lab:show_module_page('SPEECH BROWSER', {
    'MODULE SLOT ACTIVE',
    '',
    'NATIVE SPEECH CATALOG',
    'AND PLAYBACK CONTROLLER',
    'IMPLEMENTATION TARGET',
  })
end

return M
