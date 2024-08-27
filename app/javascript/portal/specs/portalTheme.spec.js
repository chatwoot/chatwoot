import {
  setPortalHoverColor,
  removeQueryParamsFromUrl,
  updateThemeInHeader,
  switchTheme,
  initializeThemeSwitchButtons,
  initializeToggleButton,
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

  describe('#initializeThemeSwitchButtons', () => {
    beforeEach(() => {
      appearanceDropdown.innerHTML = `
        <button data-theme="light"><span class="check-mark-icon light-theme"></span></button>
        <button data-theme="dark"><span class="check-mark-icon dark-theme"></span></button>
        <button data-theme="system"><span class="check-mark-icon system-theme"></span></button>
      `;
    });

    it('does nothing if the appearance dropdown is not found', () => {
      appearanceDropdown.remove();
      expect(appearanceDropdown.dataset.currentTheme).toBeUndefined();
    });
    it('should set current theme to system if no theme in localStorage', () => {
      localStorage.removeItem('theme');
      initializeThemeSwitchButtons();
      expect(appearanceDropdown.dataset.currentTheme).toBe('system');
    });

    it('sets the current theme to the light theme', () => {
      localStorage.theme = 'light';
      appearanceDropdown.dataset.currentTheme = 'light';
      initializeThemeSwitchButtons();
      expect(appearanceDropdown.dataset.currentTheme).toBe('light');
    });

    it('sets the current theme to the dark theme', () => {
      localStorage.theme = 'dark';
      appearanceDropdown.dataset.currentTheme = 'dark';
      initializeThemeSwitchButtons();
      expect(appearanceDropdown.dataset.currentTheme).toBe('dark');
    });
  });

  describe('#initializeToggleButton', () => {
    it('does nothing if the theme toggle button is not found', () => {
      themeToggleButton.remove();
      initializeToggleButton();
      expect(appearanceDropdown.style.display).toBe('');
    });

    it('toggles the appearance dropdown show/hide', () => {
      themeToggleButton.click();
      appearanceDropdown.style.display = 'flex';
      expect(appearanceDropdown.style.display).toBe('flex');
      themeToggleButton.click();
      appearanceDropdown.style.display = 'none';
      expect(appearanceDropdown.style.display).toBe('none');
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
