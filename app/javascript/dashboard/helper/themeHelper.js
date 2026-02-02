import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = isOSOnDarkMode => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';
  document.body.classList.remove('dark');
  document.body.classList.remove('heycommerce');

  if (selectedColorScheme === 'heycommerce-dark') {
    document.body.classList.add('heycommerce');
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else if (selectedColorScheme === 'heycommerce-light') {
    document.body.classList.add('heycommerce');
    document.documentElement.style.setProperty('color-scheme', 'light');
  } else if (selectedColorScheme === 'heycommerce') {
    document.body.classList.add('heycommerce');
    // HeyCommerce theme respects system dark mode preference
    if (isOSOnDarkMode) {
      document.body.classList.add('dark');
      document.documentElement.style.setProperty('color-scheme', 'dark');
    } else {
      document.documentElement.style.setProperty('color-scheme', 'light');
    }
  } else if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
