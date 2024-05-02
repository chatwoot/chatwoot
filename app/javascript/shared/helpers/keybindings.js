let KEYBINDING_MODIFIER_KEYS = ['Shift', 'Meta', 'Alt', 'Control'];
let PLATFORM = typeof navigator === 'object' ? navigator.platform : '';
let APPLE_DEVICE = /Mac|iPod|iPhone|iPad/.test(PLATFORM);
let MOD = APPLE_DEVICE ? 'Meta' : 'Control';
let ALT_GRAPH_ALIASES =
  // eslint-disable-next-line no-nested-ternary
  PLATFORM === 'Win32' ? ['Control', 'Alt'] : APPLE_DEVICE ? ['Alt'] : [];

function getModifierState(event, mod) {
  return typeof event.getModifierState === 'function'
    ? event.getModifierState(mod) ||
        (ALT_GRAPH_ALIASES.includes(mod) && event.getModifierState('AltGraph'))
    : false;
}

export function parseKeybinding(str) {
  return str
    .trim()
    .split(' ')
    .map(press => {
      let mods = press.split(/\b\+/);
      let key = mods.pop();
      mods = mods.map(mod => (mod === '$mod' ? MOD : mod));
      return [mods, key];
    });
}

function match(event, press) {
  const [mods, key] = press;

  // Check if the pressed key matches the expected key
  if (key.toUpperCase() !== event.key.toUpperCase() && key !== event.code) {
    return false;
  }

  // Check if all required modifiers are pressed
  if (mods.some(mod => !getModifierState(event, mod))) {
    return false;
  }

  // Check if any unexpected modifiers are pressed
  if (
    KEYBINDING_MODIFIER_KEYS.some(
      mod => !mods.includes(mod) && key !== mod && getModifierState(event, mod)
    )
  ) {
    return false;
  }

  return true;
}

export function createKeybindingsHandler(keyBindingMap) {
  let keyBindings = Object.keys(keyBindingMap).map(key => {
    return [parseKeybinding(key), keyBindingMap[key]];
  });

  let possibleMatches = new Map();
  let timer = null;

  return event => {
    if (!(event instanceof KeyboardEvent)) {
      return;
    }

    // eslint-disable-next-line no-console
    console.log(event.key, event.code, event.getModifierState('Control'));

    keyBindings.forEach(keyBinding => {
      let sequence = keyBinding[0];
      let callback = keyBinding[1];

      let prev = possibleMatches.get(sequence);
      let remainingExpectedPresses = prev ?? sequence;
      let currentExpectedPress = remainingExpectedPresses[0];

      let matches = match(event, currentExpectedPress);

      if (!matches) {
        if (!getModifierState(event, event.key)) {
          possibleMatches.delete(sequence);
        }
      } else if (remainingExpectedPresses.length > 1) {
        possibleMatches.set(sequence, remainingExpectedPresses.slice(1));
      } else {
        possibleMatches.delete(sequence);
        callback(event);
      }
    });

    if (timer) {
      clearTimeout(timer);
    }

    timer = setTimeout(possibleMatches.clear.bind(possibleMatches), 1000);
  };
}
