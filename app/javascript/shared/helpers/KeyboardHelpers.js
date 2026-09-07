import { isApple } from './platform';

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

// True when the platform's "command" modifier is held: Cmd (metaKey) on
// Apple platforms (macOS, iOS/iPadOS hardware keyboards), Ctrl (ctrlKey)
// elsewhere. Mirrors the `$mod` convention used by tinykeys and
// prosemirror-keymap so the editor and the app agree on what counts as the
// send modifier.
export const hasPressedMod = e => Boolean(isApple() ? e.metaKey : e.ctrlKey);

export const hasPressedEnterAndNotCmdOrShift = e => {
  return isEnter(e) && !hasPressedMod(e) && !hasPressedShift(e);
};

// Detects the platform-aware "send" shortcut: Cmd+Enter on Apple platforms,
// Ctrl+Enter on Windows/Linux.
export const hasPressedCommandAndEnter = e => hasPressedMod(e) && isEnter(e);

// If layout is QWERTZ then we add the Shift+keysToModify to fix an known issue
// https://github.com/chatwoot/chatwoot/issues/9492
export const keysToModifyInQWERTZ = new Set(['Alt+KeyP', 'Alt+KeyL']);

/**
 * True when AltGr was held for this keydown, which means the keystroke is
 * typing a character and must not be matched as a shortcut.
 *
 * Windows reports AltGr as Ctrl+Alt, and tinykeys deliberately treats an
 * AltGraph modifier state as satisfying both `Control` and `Alt` on Win32.
 * That makes AltGr+<letter> match the `$mod+Alt+<letter>` keybindings, so on a
 * Polish layout "ą" (AltGr+A) fired "add attachment" ($mod+Alt+KeyA) and "ę"
 * (AltGr+E) fired "resolve and next" ($mod+Alt+KeyE). Global shortcut handlers
 * must drop these events before any matching runs. The same class of collision
 * exists on other AltGr layouts (Czech, Croatian, Hungarian, …).
 *
 * Plain Alt+<letter> shortcuts were never affected: tinykeys rejects them when
 * Control is also held, which AltGr implies.
 *
 * KNOWN TRADEOFF, deliberate — please read before "fixing" this:
 * Windows collapses AltGr into left Ctrl + right Alt, so a single keydown
 * carries no signal that separates AltGr from a purposely pressed Ctrl+Alt.
 * Wherever a browser reports AltGraph for a deliberate chord (Option on Apple
 * platforms, reportedly Ctrl+Alt in Firefox on Windows), that chord stops
 * firing. Typing wins over the shortcut here, because a user who cannot type
 * their own language is worse off than one who loses a keybinding.
 *
 * Heuristics that try to infer intent from the event were tried and dropped:
 * comparing the produced character against the physical key's Latin letter
 * misfires on every non-Latin layout, where the two never match. Deciding this
 * correctly needs `navigator.keyboard.getLayoutMap()`, which Chromium has and
 * Firefox does not. The robust fix is to stop binding `$mod+Alt+<letter>` — a
 * chord that is indistinguishable from AltGr on Windows — see #10060.
 *
 * @param {KeyboardEvent} e - The keyboard event object.
 * @returns {boolean} `true` when AltGr was held.
 */
export const isAltGraphEvent = e =>
  typeof e.getModifierState === 'function' && e.getModifierState('AltGraph');

export const LAYOUT_QWERTY = 'QWERTY';
export const LAYOUT_QWERTZ = 'QWERTZ';
export const LAYOUT_AZERTY = 'AZERTY';

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
