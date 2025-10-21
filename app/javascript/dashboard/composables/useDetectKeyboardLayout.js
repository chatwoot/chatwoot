import {
  LAYOUT_QWERTY,
  LAYOUT_QWERTZ,
  LAYOUT_AZERTY,
} from 'shared/helpers/KeyboardHelpers';

/**
 * Detects the keyboard layout using a legacy method by creating a hidden input and dispatching a key event.
 * @returns {Promise<string>} A promise that resolves to the detected keyboard layout.
 */
async function detectLegacy() {
  const input = document.createElement('input');
  input.style.position = 'fixed';
  input.style.top = '-100px';
  document.body.appendChild(input);
  input.focus();

  return new Promise(resolve => {
    const keyboardEvent = new KeyboardEvent('keypress', {
      key: 'y',
      keyCode: 89,
      which: 89,
      bubbles: true,
      cancelable: true,
    });

    const handler = e => {
      document.body.removeChild(input);
      document.removeEventListener('keypress', handler);
      if (e.key === 'z') {
        resolve(LAYOUT_QWERTY);
      } else if (e.key === 'y') {
        resolve(LAYOUT_QWERTZ);
      } else {
        resolve(LAYOUT_AZERTY);
      }
    };

    document.addEventListener('keypress', handler);
    input.dispatchEvent(keyboardEvent);
  });
}

/**
 * Detects the keyboard layout using the modern navigator.keyboard API.
 * @returns {Promise<string>} A promise that resolves to the detected keyboard layout.
 */
async function detect() {
  const map = await navigator.keyboard.getLayoutMap();
  const q = map.get('KeyQ');
  const w = map.get('KeyW');
  const e = map.get('KeyE');
  const r = map.get('KeyR');
  const t = map.get('KeyT');
  const y = map.get('KeyY');

  return [q, w, e, r, t, y].join('').toUpperCase();
}

/**
 * Uses either the modern or legacy method to detect the keyboard layout, caching the result.
 * @returns {Promise<string>} A promise that resolves to the detected keyboard layout.
 */
export async function useDetectKeyboardLayout() {
  const cachedLayout = window.cw_keyboard_layout;
  if (cachedLayout) {
    return cachedLayout;
  }

  const layout = navigator.keyboard ? await detect() : await detectLegacy();
  window.cw_keyboard_layout = layout;
  return layout;
}
