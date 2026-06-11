import { notifyTrustedHapticTap } from 'dashboard/composables/useHaptics';

// iOS 26.5 removed programmatic switch haptics: only a trusted user tap that
// physically lands on an `<input type="checkbox" switch>` still triggers the
// Taptic Engine. This directive overlays a transparent switch on tappable
// elements so the real tap toggles it (firing the system haptic) and the
// click then bubbles to the host's own handler. Where the Vibration API
// exists (Android) useHaptics already vibrates programmatically, so the
// overlay is skipped.
const needsSwitchOverlay = () =>
  typeof navigator !== 'undefined' &&
  typeof document !== 'undefined' &&
  typeof navigator.vibrate !== 'function';

const POSITIONED = ['relative', 'absolute', 'fixed', 'sticky'];

const overlays = new WeakMap();

export const vHapticTap = {
  mounted(el) {
    if (!needsSwitchOverlay()) return;

    if (!POSITIONED.includes(window.getComputedStyle(el).position)) {
      el.style.position = 'relative';
    }

    const input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    input.setAttribute('aria-hidden', 'true');
    input.tabIndex = -1;
    Object.assign(input.style, {
      position: 'absolute',
      inset: '0',
      width: '100%',
      height: '100%',
      margin: '0',
      opacity: '0',
      zIndex: '10',
    });
    input.addEventListener('click', event => {
      // A disabled host must not produce tactile feedback for a dead control.
      if (el.disabled || el.getAttribute('aria-disabled') === 'true') {
        event.preventDefault();
        return;
      }
      if (event.isTrusted) notifyTrustedHapticTap();
    });
    overlays.set(el, input);
    el.appendChild(input);
  },
  unmounted(el) {
    overlays.get(el)?.remove();
    overlays.delete(el);
  },
};

export default vHapticTap;
