-- modules/020_sound_browser.lua
-- Wizard of Wor Lab sound-browser module entry point.

return {
  start = function(lab)
    lab:show_module_page('SOUND BROWSER', {
      'MODULE SLOT ACTIVE',
      '',
      'NATIVE SOUND CATALOG',
      'AND ENGINE CONTROLLER',
      'IMPLEMENTATION TARGET',
    })
  end,
}
