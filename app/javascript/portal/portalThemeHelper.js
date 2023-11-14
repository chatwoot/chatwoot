import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

export const setPortalHoverColor = theme => {
  if (window.portalConfig.isPlainLayoutEnabled === 'true') return;

  if (theme === 'system') {
    const prefersDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;
    theme = prefersDarkMode ? 'dark' : 'light';
  }

  const portalColor = window.portalConfig.portalColor;
  const bgColor = theme === 'dark' ? '#151718' : 'white';
  const hoverColor = adjustColorForContrast(portalColor, bgColor);

  // Set hover color for border and text dynamically
  document.documentElement.style.setProperty(
    '--dynamic-hover-color',
    hoverColor
  );
};

export const updateThemeInHeader = theme => {
  // This function is to update the theme selection in the header in real time
  const themeToggleButton = document.getElementById('toggle-appearance');

  if (!themeToggleButton) return;

  themeToggleButton.dataset.currentTheme = theme;
};

export const switchTheme = theme => {
  if (theme === 'system') {
    localStorage.removeItem('theme');
    const prefersDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;
    // remove this so that the system theme is used

    document.documentElement.classList.remove('dark', 'light');
    document.documentElement.classList.add(prefersDarkMode ? 'dark' : 'light');
  } else {
    localStorage.theme = theme;

    document.documentElement.classList.remove('dark', 'light');
    document.documentElement.classList.add(theme);
  }

  setPortalHoverColor(theme);
  updateThemeInHeader(theme);
};

export const initializeThemeSwitchButtons = () => {
  const appearanceDropdown = document.getElementById('appearance-dropdown');
  appearanceDropdown.dataset.currentTheme = localStorage.theme || 'system';

  appearanceDropdown.addEventListener('click', event => {
    const target = event.target.closest('button[data-theme]');

    if (target) {
      const { theme } = target.dataset;
      // setting this data property will automatically toggle the checkmark using CSS
      appearanceDropdown.dataset.currentTheme = theme;
      switchTheme(theme);
      // wait for a bit before hiding the dropdown
      appearanceDropdown.style.display = 'none';
    }
  });
};

export const initializeToggleButton = () => {
  const themeToggleButton = document.getElementById('toggle-appearance');

  themeToggleButton?.addEventListener('click', () => {
    const appearanceDropdown = document.getElementById('appearance-dropdown');

    const isCurrentlyHidden = appearanceDropdown.style.display === 'none';
    // Toggle the appearanceDropdown
    appearanceDropdown.style.display = isCurrentlyHidden ? 'flex' : 'none';
  });
};

export const initializeMediaQueryListener = () => {
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

  mediaQuery.addEventListener('change', () => {
    if (['light', 'dark'].includes(localStorage.theme)) return;

    switchTheme('system');
  });
};

export const initializeTheme = () => {
  // start with updating the theme in the header, this will set the current theme on the button
  // and set the hover color at the start of init, this is set again when the theme is switched
  setPortalHoverColor(localStorage.theme || 'system');
  window.updateThemeInHeader = updateThemeInHeader;
  updateThemeInHeader(localStorage.theme || 'system');

  // add the event listeners for the dropdown toggle and theme buttons
  initializeToggleButton();
  initializeThemeSwitchButtons();

  // add the media query listener to update the theme when the system theme changes
  initializeMediaQueryListener();
};
