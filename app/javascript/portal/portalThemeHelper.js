import Cookies from 'js-cookie';
import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

const SYSTEM_COOKIE = 'system_theme';
const SELECTED_COOKIE = 'selected_theme';

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
  const portalDiv = document.getElementById('portal');
  if (!portalDiv) return;
  portalDiv.classList.remove('light', 'dark', 'system');
  portalDiv.classList.add(theme);
};

export const updateThemeStyles = theme => {
  setPortalClass(theme);
  setPortalHoverColor(theme);
};

export const toggleAppearanceDropdown = () => {
  const dropdown = document.getElementById('appearance-dropdown');
  if (!dropdown) return;
  const isCurrentlyHidden = dropdown.style.display === 'none';
  // Toggle the dropdown
  dropdown.style.display = isCurrentlyHidden ? 'flex' : 'none';
};

export const updateThemeSelectionInHeader = theme => {
  // This function is to update the theme selection in the header in real time
  const buttonContainer = document.getElementById('toggle-appearance');
  if (!buttonContainer) return;
  const allElementInButton = buttonContainer.querySelectorAll('.theme-button');
  const activeThemeElement = document.querySelector(
    `.theme-button.${theme}-theme`
  );

  allElementInButton.forEach(button => {
    button.classList.remove('flex');
    button.classList.add('hidden');
  });

  if (activeThemeElement) {
    activeThemeElement.classList.remove('hidden');
    activeThemeElement.classList.add('flex');
  }
};

export const setActiveThemeIconInDropdown = theme => {
  // This function is to set the check mark icon for the active theme in the dropdown in real time
  const dropdownContainer = document.getElementById('appearance-dropdown');
  if (!dropdownContainer) return;
  const allCheckMarkIcons =
    dropdownContainer.querySelectorAll('.check-mark-icon');
  const activeIcon = document.querySelector(`.check-mark-icon.${theme}-theme`);

  allCheckMarkIcons.forEach(icon => {
    icon.classList.remove('flex');
    icon.classList.add('hidden');
  });

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
  const toggleButton = document.getElementById('toggle-appearance');
  if (toggleButton) {
    toggleButton.addEventListener('click', toggleAppearanceDropdown);
  }
};

export const initializeThemeSwitchButtons = () => {
  const appearanceDropdown = document.getElementById('appearance-dropdown');
  if (!appearanceDropdown) return;
  appearanceDropdown.addEventListener('click', event => {
    const target = event.target.closest('button[data-theme]');

    if (target) {
      const theme = target.getAttribute('data-theme');
      switchTheme(theme);
    }
  });
};
