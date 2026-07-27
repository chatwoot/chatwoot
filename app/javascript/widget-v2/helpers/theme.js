const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)');

// Order of precedence: defaults in widget-v2.scss → inbox widget_color → host theme.
export const applyTheme = (theme = {}) => {
  const root = document.documentElement;
  if (theme.primary) root.style.setProperty('--cw-primary', theme.primary);
  if (theme.radius) root.style.setProperty('--cw-radius', theme.radius);
  if (theme.font) root.style.setProperty('--cw-font-sans', theme.font);
};

export const applyDarkMode = mode => {
  const root = document.documentElement;
  const isDark = mode === 'dark' || (mode === 'auto' && darkModeQuery.matches);
  root.classList.toggle('dark', isDark);
};

export const watchSystemDarkMode = getMode => {
  darkModeQuery.addEventListener('change', () => applyDarkMode(getMode()));
};
