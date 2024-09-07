import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

/**
 * Composable for handling dark mode.
 * @returns {Object} An object containing computed properties and methods for dark mode.
 */

export function useDarkMode() {
  const darkMode = useMapGetter('appConfig/darkMode');
  const prefersDarkMode = computed(() => {
    const isOSOnDarkMode =
      darkMode.value === 'auto' &&
      window.matchMedia('(prefers-color-scheme: dark)').matches;
    return isOSOnDarkMode || darkMode.value === 'dark';
  });
const getThemeClass = (light, dark) => 
  darkMode.value === 'auto' ? `${light} ${dark}` : darkMode.value === 'dark' ? dark : light;
  return {
    darkMode,
    prefersDarkMode,
    getThemeClass,
  };
}
