import { computed } from 'vue';
import { useStore } from 'vuex';

/**
 * Composable for handling dark mode preferences and utility functions.
 * @returns {Object} An object containing computed properties and methods for dark mode management.
 */
export function useDarkMode() {
  const store = useStore();

  const darkMode = computed(() => store.getters['appConfig/darkMode']);

  const prefersDarkMode = computed(() => {
    const isOSOnDarkMode =
      darkMode.value === 'auto' &&
      window.matchMedia('(prefers-color-scheme: dark)').matches;
    return isOSOnDarkMode || darkMode.value === 'dark';
  });

  const dm = (light, dark) => {
    if (darkMode.value === 'light') {
      return light;
    }
    if (darkMode.value === 'dark') {
      return dark;
    }
    return `${light} ${dark}`;
  };

  return {
    darkMode,
    prefersDarkMode,
    dm,
  };
}
