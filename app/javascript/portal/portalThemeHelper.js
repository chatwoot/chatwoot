import Cookies from 'js-cookie';
import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

const SYSTEM_COOKIE = 'system_theme';
const SELECTED_COOKIE = 'selected_theme';

let portalDiv = null;
let appearanceDropdown = null;
let themeToggleButton = null;

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

export const setPortalClass = theme => {
  portalDiv =
    portalDiv !== null ? portalDiv : document.getElementById('portal');
  if (!portalDiv) return;
  portalDiv.classList.remove('light', 'dark', 'system');
  portalDiv.classList.add(theme);
};

export const updateThemeStyles = theme => {
  setPortalClass(theme);
  setPortalHoverColor(theme);
};

export const toggleAppearanceDropdown = () => {
  appearanceDropdown =
    appearanceDropdown !== null
      ? appearanceDropdown
      : document.getElementById('appearance-dropdown');
  if (!appearanceDropdown) return;
  const isCurrentlyHidden = appearanceDropdown.style.display === 'none';
  // Toggle the appearanceDropdown
  appearanceDropdown.style.display = isCurrentlyHidden ? 'flex' : 'none';
};

export const updateThemeSelectionInHeader = theme => {
  // This function is to update the theme selection in the header in real time
  themeToggleButton =
    themeToggleButton !== null
      ? themeToggleButton
      : document.getElementById('toggle-appearance');
  if (!themeToggleButton) return;
  const allElementInButton =
    themeToggleButton.querySelectorAll('.theme-button');

  allElementInButton.forEach(button => {
    button.classList.remove('flex');
    button.classList.add('hidden');
  });

  const activeThemeElement = themeToggleButton.querySelector(
    `[data-theme="${theme}"]`
  );

  if (activeThemeElement) {
    activeThemeElement.classList.remove('hidden');
    activeThemeElement.classList.add('flex');
  }
};

export const setActiveThemeIconInDropdown = theme => {
  // This function is to set the check mark icon for the active theme in the dropdown in real time
  appearanceDropdown =
    appearanceDropdown !== null
      ? appearanceDropdown
      : document.getElementById('appearance-dropdown');
  if (!appearanceDropdown) return;
  const allCheckMarkIcons =
    appearanceDropdown.querySelectorAll('.check-mark-icon');

  allCheckMarkIcons.forEach(icon => {
    icon.classList.remove('flex');
    icon.classList.add('hidden');
  });

  const activeIcon = appearanceDropdown.querySelector(
    `.check-mark-icon.${theme}-theme`
  );

  if (activeIcon) {
    activeIcon.classList.remove('hidden');
    activeIcon.classList.add('flex');
  }
};

export const updateActiveThemeInHeader = theme => {
  updateThemeSelectionInHeader(theme);
  setActiveThemeIconInDropdown(theme);
};

export const switchTheme = theme => {
  Cookies.set(SELECTED_COOKIE, theme, { expires: 365 });

  if (theme === 'system') {
    const mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
    updateThemeStyles(mediaQueryList.matches ? 'dark' : 'light');
  } else {
    updateThemeStyles(theme);
  }
  updateActiveThemeInHeader(theme);
  toggleAppearanceDropdown();
};

export const updateTheme = (theme, cookie) => {
  Cookies.set(cookie, theme, { expires: 365 });
  updateThemeStyles(theme);
};

export const updateThemeBasedOnSystem = (event, cookie) => {
  if (Cookies.get(SELECTED_COOKIE) !== 'system') return;

  const newTheme = event.matches ? 'dark' : 'light';
  updateTheme(newTheme, cookie);
};

export const initializeTheme = () => {
  const mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
  const getThemePreference = () => (mediaQueryList.matches ? 'dark' : 'light');
  const { theme: themeFromServer } = window.portalConfig || {};

  if (themeFromServer === 'system') {
    // Handle dynamic theme changes for system theme
    mediaQueryList.addEventListener('change', event => {
      updateThemeBasedOnSystem(event, SYSTEM_COOKIE);
    });
    const themePreference = getThemePreference();
    updateTheme(themePreference, SYSTEM_COOKIE);
    updateActiveThemeInHeader('system');
  } else {
    updateTheme(themeFromServer, SELECTED_COOKIE);
    updateActiveThemeInHeader(themeFromServer);
  }
};

export const initializeToggleButton = () => {
  themeToggleButton =
    themeToggleButton !== null
      ? themeToggleButton
      : document.getElementById('toggle-appearance');
  if (themeToggleButton) {
    themeToggleButton.addEventListener('click', toggleAppearanceDropdown);
  }
};

export const initializeThemeSwitchButtons = () => {
  appearanceDropdown =
    appearanceDropdown !== null
      ? appearanceDropdown
      : document.getElementById('appearance-dropdown');
  if (!appearanceDropdown) return;
  appearanceDropdown.addEventListener('click', event => {
    const target = event.target.closest('button[data-theme]');

    if (target) {
      const theme = target.getAttribute('data-theme');
      switchTheme(theme);
    }
  });
};
