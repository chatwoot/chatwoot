import {
  setPortalHoverColor,
  removeQueryParamsFromUrl,
  updateThemeInHeader,
  switchTheme,
  initializeThemeHandlers,
  initializeMediaQueryListener,
  initializeTheme,
} from '../portalThemeHelper.js';
import { adjustColorForContrast } from '../../shared/helpers/colorHelper.js';

describe('portalThemeHelper', () => {
  let themeToggleButton;
  let appearanceDropdown;

  beforeEach(() => {
    themeToggleButton = document.createElement('div');
    themeToggleButton.id = 'toggle-appearance';
    document.body.appendChild(themeToggleButton);

    appearanceDropdown = document.createElement('div');
    appearanceDropdown.id = 'appearance-dropdown';
    appearanceDropdown.classList.add('appearance-menu');
    document.body.appendChild(appearanceDropdown);

    window.matchMedia = vi.fn().mockImplementation(query => ({
      matches: query === '(prefers-color-scheme: dark)',
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }));

    window.portalConfig = { portalColor: '#ff5733' };
    document.documentElement.style.setProperty = vi.fn();
    document.documentElement.classList.remove('dark', 'light');

    vi.clearAllMocks();
  });

  afterEach(() => {
    themeToggleButton.remove();
    appearanceDropdown.remove();
    delete window.portalConfig;
    document.documentElement.style.setProperty.mockRestore();
    document.documentElement.classList.remove('dark', 'light');
    localStorage.clear();
  });

  describe('#setPortalHoverColor', () => {
    it('should apply dark hover color in dark theme', () => {
      const hoverColor = adjustColorForContrast('#ff5733', '#151718');
      setPortalHoverColor('dark');
      expect(document.documentElement.style.setProperty).toHaveBeenCalledWith(
        '--dynamic-hover-color',
        hoverColor
      );
    });

    it('should apply light hover color in light theme', () => {
      const hoverColor = adjustColorForContrast('#ff5733', '#ffffff');
      setPortalHoverColor('light');
      expect(document.documentElement.style.setProperty).toHaveBeenCalledWith(
        '--dynamic-hover-color',
        hoverColor
      );
    });
  });

  describe('#removeQueryParamsFromUrl', () => {
    let originalLocation;

    beforeEach(() => {
      originalLocation = window.location;
      delete window.location;
      window.location = new URL('http://localhost:3000/');
      window.history.replaceState = vi.fn();
    });

    afterEach(() => {
      window.location = originalLocation;
    });

    it('should not remove query params if theme is not in the URL', () => {
      removeQueryParamsFromUrl();
      expect(window.history.replaceState).not.toHaveBeenCalled();
    });

    it('should remove theme query param from the URL', () => {
      window.location = new URL(
        'http://localhost:3000/?theme=light&show_plain_layout=true'
      );
      removeQueryParamsFromUrl('theme');
      expect(window.history.replaceState).toHaveBeenCalledWith(
        {},
        '',
        'http://localhost:3000/?show_plain_layout=true'
      );
    });
  });

  describe('#updateThemeInHeader', () => {
    beforeEach(() => {
      themeToggleButton.innerHTML = `
        <div class="theme-button" data-theme="light"></div>
        <div class="theme-button" data-theme="dark"></div>
        <div class="theme-button" data-theme="system"></div>
      `;
    });

    it('should not update header if theme toggle button is not found', () => {
      themeToggleButton.remove();
      updateThemeInHeader('light');
      expect(document.querySelector('.theme-button')).toBeNull();
    });

    it('should show the theme button for the selected theme', () => {
      updateThemeInHeader('light');
      const lightButton = themeToggleButton.querySelector(
        '.theme-button[data-theme="light"]'
      );
      expect(lightButton.classList).toContain('flex');
    });
  });

  describe('#switchTheme', () => {
    it('should set theme to system theme and update classes', () => {
      window.matchMedia = vi.fn().mockReturnValue({ matches: true });
      switchTheme('system');
      expect(localStorage.theme).toBeUndefined();
      expect(document.documentElement.classList).toContain('dark');
    });

    it('should set theme to light theme and update classes', () => {
      switchTheme('light');
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList).toContain('light');
    });

    it('should set theme to dark theme and update classes', () => {
      switchTheme('dark');
      expect(localStorage.theme).toBe('dark');
      expect(document.documentElement.classList).toContain('dark');
    });
  });

  describe('#initializeThemeHandlers', () => {
    beforeEach(() => {
      appearanceDropdown.innerHTML = `
        <button data-theme="light"><span class="check-mark-icon light-theme"></span></button>
        <button data-theme="dark"><span class="check-mark-icon dark-theme"></span></button>
        <button data-theme="system"><span class="check-mark-icon system-theme"></span></button>
      `;
    });

    it('does nothing if the appearance dropdown is not found', () => {
      appearanceDropdown.remove();
      expect(() => initializeThemeHandlers()).not.toThrow();
    });

    it('should handle theme button clicks', () => {
      initializeThemeHandlers();

      // Simulate clicking a theme button
      const lightButton = appearanceDropdown.querySelector(
        'button[data-theme="light"]'
      );
      const clickEvent = new Event('click', { bubbles: true });
      Object.defineProperty(clickEvent, 'target', {
        value: lightButton,
        enumerable: true,
      });

      document.dispatchEvent(clickEvent);

      expect(localStorage.theme).toBe('light');
      expect(appearanceDropdown.dataset.currentTheme).toBe('light');
    });

    it('should toggle dropdown visibility on toggle button click', () => {
      initializeThemeHandlers();

      // Initially closed
      expect(appearanceDropdown.dataset.dropdownOpen).toBeUndefined();

      // Click to open
      themeToggleButton.click();
      expect(appearanceDropdown.dataset.dropdownOpen).toBe('true');

      // Click to close
      themeToggleButton.click();
      expect(appearanceDropdown.dataset.dropdownOpen).toBe('false');
    });

    it('should close dropdown when clicking outside', () => {
      initializeThemeHandlers();

      // Open dropdown
      appearanceDropdown.dataset.dropdownOpen = 'true';

      // Click outside
      const outsideClick = new Event('click', { bubbles: true });
      Object.defineProperty(outsideClick, 'target', {
        value: document.body,
        enumerable: true,
      });
      document.dispatchEvent(outsideClick);

      expect(appearanceDropdown.dataset.dropdownOpen).toBe('false');
    });
  });

  describe('#initializeMediaQueryListener', () => {
    let mediaQuery;

    beforeEach(() => {
      mediaQuery = {
        addEventListener: vi.fn(),
        matches: false,
      };
      window.matchMedia = vi.fn().mockReturnValue(mediaQuery);
    });

    it('adds a listener to the media query', () => {
      initializeMediaQueryListener();
      expect(window.matchMedia).toHaveBeenCalledWith(
        '(prefers-color-scheme: dark)'
      );
      expect(mediaQuery.addEventListener).toHaveBeenCalledWith(
        'change',
        expect.any(Function)
      );
    });

    it('does not switch theme if local storage theme is light or dark', () => {
      localStorage.theme = 'light';
      initializeMediaQueryListener();
      mediaQuery.matches = true;
      mediaQuery.addEventListener.mock.calls[0][1]();
      expect(localStorage.theme).toBe('light');
    });

    it('switches to dark theme if system preference changes to dark and no theme is set in local storage', () => {
      localStorage.removeItem('theme');
      initializeMediaQueryListener();
      mediaQuery.matches = true;
      mediaQuery.addEventListener.mock.calls[0][1]();
      expect(document.documentElement.classList).toContain('dark');
    });

    it('switches to light theme if system preference changes to light and no theme is set in local storage', () => {
      localStorage.removeItem('theme');
      initializeMediaQueryListener();
      mediaQuery.matches = false;
      mediaQuery.addEventListener.mock.calls[0][1]();
      expect(document.documentElement.classList).toContain('light');
    });
  });

  describe('#initializeTheme', () => {
    it('should not initialize theme if plain layout is enabled', () => {
      window.portalConfig.isPlainLayoutEnabled = 'true';
      initializeTheme();
      expect(localStorage.theme).toBeUndefined();
      expect(document.documentElement.classList).not.toContain('light');
      expect(document.documentElement.classList).not.toContain('dark');
    });

    it('sets the theme to the system theme', () => {
      initializeTheme();
      expect(localStorage.theme).toBeUndefined();
      const prefersDarkMode = window.matchMedia(
        '(prefers-color-scheme: dark)'
      ).matches;
      expect(document.documentElement.classList.contains('light')).toBe(
        !prefersDarkMode
      );
    });

    it('sets the theme to the light theme', () => {
      localStorage.theme = 'light';
      document.documentElement.classList.add('light');
      initializeTheme();
      expect(localStorage.theme).toBe('light');
      expect(document.documentElement.classList.contains('light')).toBe(true);
    });

    it('sets the theme to the dark theme', () => {
      localStorage.theme = 'dark';
      document.documentElement.classList.add('dark');
      initializeTheme();
      expect(localStorage.theme).toBe('dark');
      expect(document.documentElement.classList.contains('dark')).toBe(true);
    });
  });
});
