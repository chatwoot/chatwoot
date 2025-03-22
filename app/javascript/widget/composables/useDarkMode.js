import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const isDarkModeAuto = mode => mode === 'auto';
const isDarkMode = mode => mode === 'dark';

const getSystemPreference = () =>
  window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false;

const calculatePrefersDarkMode = (mode, systemPreference) =>
  isDarkModeAuto(mode) ? systemPreference : isDarkMode(mode);

/**
 * Composable for handling dark mode.
 * @returns {Object} An object containing computed properties and methods for dark mode.
 */
export function useDarkMode() {
  const darkMode = useMapGetter('appConfig/darkMode');

  const systemPreference = computed(getSystemPreference);

  const prefersDarkMode = computed(() =>
    calculatePrefersDarkMode(darkMode.value, systemPreference.value)
  );

  return {
    darkMode,
    prefersDarkMode,
  };
}
