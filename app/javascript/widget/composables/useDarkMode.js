import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

// Helper functions to improve readability and reduce complexity
const isDarkModeAuto = mode => mode === 'auto';
const isDarkMode = mode => mode === 'dark';

/**
 * Composable for handling dark mode.
 * @returns {Object} An object containing computed properties and methods for dark mode.
 */
export function useDarkMode() {
  const darkMode = useMapGetter('appConfig/darkMode');

  const memoizedMatchMedia = computed(
    () => window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false
  );

  const prefersDarkMode = computed(() =>
    isDarkModeAuto(darkMode.value)
      ? memoizedMatchMedia.value
      : isDarkMode(darkMode.value)
  );

  const getThemeClass = (light, dark) => {
    if (isDarkModeAuto(darkMode.value)) {
      return `${light} ${dark}`;
    }
    return isDarkMode(darkMode.value) ? dark : light;
  };

  return {
    darkMode,
    prefersDarkMode,
    getThemeClass,
  };
}
