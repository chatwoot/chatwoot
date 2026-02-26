import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = isOSOnDarkMode => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';

  // 1. Limpeza de estados anteriores
  document.body.classList.remove('dark');
  document.body.removeAttribute('data-theme');
  
  // 2. Lógica de aplicação do tema
  if (selectedColorScheme === 'secret') {
    // Aplica o tema rosa do Dia das Mulheres
    document.body.setAttribute('data-theme', 'secret');
    document.documentElement.style.setProperty('color-scheme', 'light');
  } else if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    // Aplica o tema Dark padrão
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    // Tema Light padrão
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};