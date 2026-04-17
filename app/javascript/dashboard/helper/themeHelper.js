export const setColorTheme = _isOSOnDarkMode => {
  document.body.classList.add('dark');
  document.documentElement.style.setProperty('color-scheme', 'dark');
};
