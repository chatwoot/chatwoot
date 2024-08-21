import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

/**
 * Composable for handling dark mode.
 * @returns {Object} An object containing computed properties and methods for dark mode.
 */

export function useDarkMode() {
  const darkMode = useMapGetter('appConfig/getDarkMode');
  const prefersDarkMode = computed(() => {
    const isOSOnDarkMode =
      darkMode.value === 'auto' &&
      window.matchMedia('(prefers-color-scheme: dark)').matches;
    return isOSOnDarkMode || darkMode.value === 'dark';
  });
  const $dm = (light, dark) => {
    if (darkMode.value === 'light') {
      return light;
    }
    if (darkMode.value === 'dark') {
      return dark;
    }
    return light + ' ' + dark;
  };
  return {
    darkMode,
    prefersDarkMode,
    $dm,
  };
}
