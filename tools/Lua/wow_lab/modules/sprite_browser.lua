-- modules/030_sprite_browser.lua
-- Wizard of Wor Lab sprite-browser module entry point.

return {
  start = function(lab)
    lab:show_module_page('SPRITE BROWSER', {
      'MODULE SLOT ACTIVE',
      '',
      'OBJECT AND SPRITE DATA',
      'RENDERING TEST BED',
      'IMPLEMENTATION TARGET',
    })
  end,
}
