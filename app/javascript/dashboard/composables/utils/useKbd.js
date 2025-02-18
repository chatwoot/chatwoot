import { computed } from 'vue';

export function useKbd(keys) {
  const keySymbols = {
    $mod: navigator.platform.includes('Mac') ? '⌘' : 'Ctrl',
    shift: '⇧',
    alt: '⌥',
    ctrl: 'Ctrl',
    cmd: '⌘',
    option: '⌥',
    enter: '↩',
    tab: '⇥',
    esc: '⎋',
  };

  return computed(() => {
    return keys
      .map(key => keySymbols[key.toLowerCase()] || key)
      .join('')
      .toUpperCase();
  });
}
