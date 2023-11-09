import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

let appearanceDropdown = document.getElementById('appearance-dropdown');
let themeToggleButton = document.getElementById('toggle-appearance');

export const setPortalHoverColor = theme => {
  if (window.portalConfig.isPlainLayoutEnabled === 'true') return;
  const portalColor = window.portalConfig.portalColor;
  const bgColor = theme === 'dark' ? '#151718' : 'white';
  const hoverColor = adjustColorForContrast(portalColor, bgColor);

  // Set hover color for border and text dynamically
  document.documentElement.style.setProperty(
    '--dynamic-hover-color',
    hoverColor
  );
};

export const updateThemeInHeader = () => {
  // This function is to update the theme selection in the header in real time
  if (!themeToggleButton) {
    themeToggleButton = document.getElementById('toggle-appearance');
  }
  if (!themeToggleButton) return;
  const theme = localStorage.theme || 'system';

  const allElementInButton =
    themeToggleButton.querySelectorAll('.theme-button');

  allElementInButton.forEach(button => {
    if (button.dataset.theme === theme) {
      button.classList.remove('hidden');
      button.classList.add('flex');
    } else {
      button.classList.remove('flex');
      button.classList.add('hidden');
    }
  });
};

export const switchTheme = theme => {
  if (theme === 'system') {
    const prefersDarkMode = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;
    // remove this so that the system theme is used
    localStorage.removeItem(theme);

    document.documentElement.classList.remove('dark', 'light');
    document.documentElement.classList.add(prefersDarkMode ? 'dark' : 'light');
  } else {
    localStorage.theme = theme;

    document.documentElement.classList.remove('dark', 'light');
    document.documentElement.classList.add(theme);
  }
};

export const initializeThemeSwitchButtons = () => {
  if (!appearanceDropdown) {
    appearanceDropdown = document.getElementById('appearance-dropdown');
  }
  appearanceDropdown.dataset.currentTheme = localStorage.theme || 'system';

  appearanceDropdown.addEventListener('click', event => {
    const target = event.target.closest('button[data-theme]');

    if (target) {
      const { theme } = target.dataset;
      // setting this data property will automatically toggle the checkmark using CSS
      appearanceDropdown.dataset.currentTheme = theme;
      switchTheme(theme);
      updateThemeInHeader();
      setPortalHoverColor(theme);
      // wait for a bit before hiding the dropdown
      appearanceDropdown.style.display = 'none';
    }
  });
};

export const initializeToggleButton = () => {
  if (!themeToggleButton) {
    themeToggleButton = document.getElementById('toggle-appearance');
  }

  themeToggleButton?.addEventListener('click', () => {
    if (!appearanceDropdown) {
      appearanceDropdown = document.getElementById('appearance-dropdown');
    }

    const isCurrentlyHidden = appearanceDropdown.style.display === 'none';
    // Toggle the appearanceDropdown
    appearanceDropdown.style.display = isCurrentlyHidden ? 'flex' : 'none';
  });
};

export const initializeTheme = () => {
  updateThemeInHeader();
  initializeToggleButton();
  initializeThemeSwitchButtons();
  setPortalHoverColor(localStorage.theme || 'system');
};
