import { adjustColorForContrast } from '../shared/helpers/colorHelper.js';

const getResolvedTheme = theme => {
  // Helper to get resolved theme (handles 'system' -> 'dark'/'light')
  if (theme === 'system') {
    return window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light';
  }
  return theme;
};

export const setPortalHoverColor = theme => {
  // This function is to set the hover color for the portal
  const resolvedTheme = getResolvedTheme(theme);
  const portalColor = window.portalConfig.portalColor;
  const bgColor = resolvedTheme === 'dark' ? '#151718' : 'white';
  const hoverColor = adjustColorForContrast(portalColor, bgColor);

  // Set hover color for border and text dynamically
  document.documentElement.style.setProperty(
    '--dynamic-hover-color',
    hoverColor
  );
};

export const removeQueryParamsFromUrl = (queryParam = 'theme') => {
  // This function is to remove the theme query param from the URL
  // This is done so that the theme is not persisted in the URL
  // This is called when the theme is switched from the dropdown
  const url = new URL(window.location.href);
  const param = url.searchParams.get(queryParam);

  if (param) {
    url.searchParams.delete(queryParam);
    window.history.replaceState({}, '', url.toString()); // Convert URL to string
  }
};

export const updateThemeInHeader = theme => {
  // This function is to update the theme selection in the header in real time
  const themeToggleButton = document.getElementById('toggle-appearance');
  if (!themeToggleButton) return;

  const allThemeButtons = themeToggleButton.querySelectorAll('.theme-button');
  if (!allThemeButtons.length) return;

  allThemeButtons.forEach(button => {
    const isActive = button.dataset.theme === theme;
    button.classList.toggle('hidden', !isActive);
    button.classList.toggle('flex', isActive);
  });
};

export const switchTheme = theme => {
  // Update localStorage
  if (theme === 'system') {
    localStorage.removeItem('theme');
  } else {
    localStorage.theme = theme;
  }

  const resolvedTheme = getResolvedTheme(theme);
  document.documentElement.classList.remove('dark', 'light');
  document.documentElement.classList.add(resolvedTheme);

  setPortalHoverColor(theme);
  updateThemeInHeader(theme);
  removeQueryParamsFromUrl();
  // Update both dropdown data attributes
  document.querySelectorAll('.appearance-menu').forEach(menu => {
    menu.dataset.currentTheme = theme;
  });
};

export const initializeThemeHandlers = () => {
  const toggle = document.getElementById('toggle-appearance');
  const dropdown = document.getElementById('appearance-dropdown');
  if (!toggle || !dropdown) return;

  // Toggle appearance dropdown
  toggle.addEventListener('click', e => {
    e.stopPropagation();
    dropdown.dataset.dropdownOpen = String(
      dropdown.dataset.dropdownOpen !== 'true'
    );
  });

  document.addEventListener('click', ({ target }) => {
    if (toggle.contains(target)) return;

    const themeBtn = target.closest('.appearance-menu button[data-theme]');
    const menu = themeBtn?.closest('.appearance-menu');

    if (themeBtn && menu) {
      switchTheme(themeBtn.dataset.theme);
      menu.dataset.dropdownOpen = 'false';

      if (menu.id === 'mobile-appearance-dropdown') {
        // Set the mobile menu toggle to false after a delay to ensure the transition is completed
        setTimeout(() => {
          const mobileToggle = document.getElementById('mobile-menu-toggle');
          if (mobileToggle) mobileToggle.checked = false;
        }, 300);
      }

      return;
    }

    // Close the desktop appearance dropdown if clicked outside
    if (
      dropdown.dataset.dropdownOpen === 'true' &&
      !dropdown.contains(target)
    ) {
      dropdown.dataset.dropdownOpen = 'false';
    }
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
  if (window.portalConfig.isPlainLayoutEnabled === 'true') return;
  // start with updating the theme in the header, this will set the current theme on the button
  // and set the hover color at the start of init, this is set again when the theme is switched
  switchTheme(localStorage.theme || 'system');

  window.updateThemeInHeader = updateThemeInHeader;

  // add the event listeners for the dropdown toggle and theme buttons
  initializeThemeHandlers();

  // add the media query listener to update the theme when the system theme changes
  initializeMediaQueryListener();
};
