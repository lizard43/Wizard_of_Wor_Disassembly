-- modules/010_speech_browser.lua
-- Wizard of Wor Lab speech-browser module entry point.

return {
  start = function(lab)
    lab:show_module_page('SPEECH BROWSER', {
      'MODULE SLOT ACTIVE',
      '',
      'NATIVE SPEECH CATALOG',
      'AND PLAYBACK CONTROLLER',
      'IMPLEMENTATION TARGET',
    })
  end,
}
