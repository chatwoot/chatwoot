export const isEnter = e => {
  return e.keyCode === 13;
};

export const isEscape = e => {
  return e.keyCode === 27;
};

export const hasPressedShift = e => {
  return e.shiftKey;
};

export const hasPressedCommand = e => {
  return e.metaKey;
};

export const hasPressedEnterAndNotCmdOrShift = e => {
  return isEnter(e) && !hasPressedCommand(e) && !hasPressedShift(e);
};

export const hasPressedCommandAndEnter = e => {
  return e.metaKey && e.keyCode === 13;
};

export const hasPressedCommandAndForwardSlash = e => {
  return e.metaKey && e.keyCode === 191;
};

export const hasPressedAltAndCKey = e => {
  return e.altKey && e.keyCode === 67;
};

export const hasPressedAltAndVKey = e => {
  return e.altKey && e.keyCode === 86;
};

export const hasPressedAltAndRKey = e => {
  return e.altKey && e.keyCode === 82;
};

export const hasPressedAltAndSKey = e => {
  return e.altKey && e.keyCode === 83;
};

export const hasPressedAltAndBKey = e => {
  return e.altKey && e.keyCode === 66;
};

export const hasPressedAltAndNKey = e => {
  return e.altKey && e.keyCode === 78;
};

export const hasPressedAltAndAKey = e => {
  return e.altKey && e.keyCode === 65;
};

export const hasPressedAltAndPKey = e => {
  return e.altKey && e.keyCode === 80;
};

export const hasPressedAltAndLKey = e => {
  return e.altKey && e.keyCode === 76;
};

export const hasPressedAltAndEKey = e => {
  return e.altKey && e.keyCode === 69;
};

export const hasPressedCommandPlusAltAndEKey = e => {
  return e.metaKey && e.altKey && e.keyCode === 69;
};

export const hasPressedAltAndOKey = e => {
  return e.altKey && e.keyCode === 79;
};

export const hasPressedAltAndJKey = e => {
  return e.altKey && e.keyCode === 74;
};

export const hasPressedAltAndKKey = e => {
  return e.altKey && e.keyCode === 75;
};

export const hasPressedAltAndMKey = e => {
  return e.altKey && e.keyCode === 77;
};

export const hasPressedArrowUpKey = e => {
  return e.keyCode === 38;
};

export const hasPressedArrowDownKey = e => {
  return e.keyCode === 40;
};

export const hasPressedCommandPlusKKey = e => {
  return e.metaKey && e.keyCode === 75;
};

export const buildHotKeys = e => {
  const key = e.key.toLowerCase();
  if (['shift', 'meta', 'alt', 'control'].includes(key)) {
    return key;
  }
  let hotKeyPattern = '';
  if (e.altKey) {
    hotKeyPattern += 'alt+';
  }
  if (e.ctrlKey) {
    hotKeyPattern += 'ctrl+';
  }
  if (e.metaKey && !e.ctrlKey) {
    hotKeyPattern += 'meta+';
  }
  if (e.shiftKey) {
    hotKeyPattern += 'shift+';
  }
  hotKeyPattern += key;
  return hotKeyPattern;
};
