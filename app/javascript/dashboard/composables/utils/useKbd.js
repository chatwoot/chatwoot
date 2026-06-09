import { computed } from 'vue';

function isMacOS() {
  // Check modern userAgentData API first
  if (navigator.userAgentData?.platform) {
    return navigator.userAgentData.platform === 'macOS';
  }
  // Fallback to navigator.platform
  return (
    navigator.platform.startsWith('Mac') || navigator.platform === 'iPhone'
  );
}

export function useKbd(keys) {
  const keySymbols = {
    $mod: isMacOS() ? '⌘' : 'Ctrl',
    shift: '⇧',
    alt: '⌥',
    ctrl: 'Ctrl',
    cmd: '⌘',
    option: '⌥',
    enter: '↵',
    tab: '⇥',
    esc: '⎋',
  };

  return computed(() => {
    return keys
      .map(key => keySymbols[key.toLowerCase()] || key)
      .join(' ')
      .toUpperCase();
  });
}

export function getModifierKey() {
  return isMacOS() ? '⌘' : 'Ctrl';
}
