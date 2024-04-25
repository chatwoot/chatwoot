export const isEnter = e => {
  return e.key === 'Enter';
};

export const isEscape = e => {
  return e.key === 'Escape';
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
  return hasPressedCommand(e) && isEnter(e);
};

/**
 * Returns a string representation of the hotkey pattern based on the provided event object.
 * @param {KeyboardEvent} e - The keyboard event object.
 * @returns {string} - The hotkey pattern string.
 */
export const buildHotKeys = e => {
  // remove the prefix "key"
  const key = e.code.toLowerCase().replace('key', '');

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

/**
 * Determines whether the active element is typeable.
 *
 * @param {KeyboardEvent} e - The keyboard event object.
 * @returns {boolean} `true` if the active element is typeable, `false` otherwise.
 *
 * @example
 * document.addEventListener('keydown', e => {
 *   if (isActiveElementTypeable(e)) {
 *     handleTypeableElement(e);
 *   }
 * });
 */
export const isActiveElementTypeable = e => {
  /** @type {HTMLElement | null} */
  // @ts-ignore
  const activeElement = e.target || document.activeElement;

  return !!(
    activeElement?.tagName === 'INPUT' ||
    activeElement?.tagName === 'NINJA-KEYS' ||
    activeElement?.tagName === 'TEXTAREA' ||
    activeElement?.contentEditable === 'true' ||
    activeElement?.className?.includes('ProseMirror')
  );
};
