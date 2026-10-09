import { useKbd } from 'dashboard/composables/utils/useKbd';

const KEY_LABELS = {
  Slash: '/',
  ArrowUp: '↑',
  ArrowDown: '↓',
  Enter: '↵',
  Escape: 'esc',
  Backspace: '⌫',
};

export const shortcutKeys = binding =>
  useKbd(
    binding.split('+').map(key => KEY_LABELS[key] ?? key.replace(/^Key/, ''))
  ).value.split(' ');
