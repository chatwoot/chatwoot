(function(global) {
  var keyCodes = {
    'A': 65,
    'TAB': 9,
    'ENTER': 13,
    'ESCAPE': 27,
    'SPACE': 32,
    'END': 35,
    'HOME': 36,
    'ARROW_LEFT': 37,
    'ARROW_UP': 38,
    'ARROW_RIGHT': 39,
    'ARROW_DOWN': 40
  };

  /**
   * Creates a dummy event to parse.
   * Uses jQuery Event class constructor.
   * @param  {number} keyCode Key code of the key that is simulated.
   * @param  {object} opts    Options that say if modifiers are pressed.
   * @return {Event}          Event to use.
   */
  global.mockKeyboardEvent =  mockKeyboardEvent = function(keyCode, opts) {
    var options = opts || {},
        isCtrl = !!options.ctrl,
        isAlt = !!options.alt,
        isShift = !!options.shift,
        isMeta = !!options.meta,
        keyCode = typeof keyCode === 'number' ? keyCode : keyCodes[keyCode],
        event = {
          shiftKey: isShift,
          altKey: isAlt,
          ctrlKey: isCtrl,
          metaKey: isMeta,
          keyCode: keyCode,
          which: keyCode
        };
    return new $.Event('keydown', event);
  };
})(window);