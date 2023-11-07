import Cookies from 'js-cookie';
jest.mock('js-cookie');

import {
  setPortalHoverColor,
  setPortalClass,
  updateThemeStyles,
  toggleAppearanceDropdown,
  switchTheme,
  updateThemeSelectionInHeader,
  setActiveThemeIconInDropdown,
  updateTheme,
  updateThemeBasedOnSystem,
  initializeTheme,
  initializeToggleButton,
  initializeThemeSwitchButtons,
} from '../portalThemeHelper';

describe('Theme Functions', () => {
  describe('#setPortalHoverColor', () => {
    beforeEach(() => {
      window.portalConfig = { portalColor: '#ff5733' };
    });

    afterEach(() => {
      document.documentElement.style.removeProperty('--dynamic-hover-color');
    });

    it('sets styles for portal hover based on theme', () => {
      setPortalHoverColor('dark');
      const hoverColorStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-hover-color');
      const expectedHoverColorStyle = '#ff5733';
      expect(hoverColorStyle.trim()).toBe(expectedHoverColorStyle);
    });
  });

  describe('#setPortalClass', () => {
    let mockPortalDiv;

    beforeEach(() => {
      // Mocking portal div
      mockPortalDiv = document.createElement('div');
      mockPortalDiv.id = 'portal';
      mockPortalDiv.classList.add('light');
      document.body.appendChild(mockPortalDiv);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('sets portal class to "dark" based on theme', () => {
      setPortalClass('dark');
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
      expect(mockPortalDiv.classList.contains('light')).toBe(false);
    });

    it('sets portal class to "light" based on theme', () => {
      setPortalClass('light');
      expect(mockPortalDiv.classList.contains('light')).toBe(true);
      expect(mockPortalDiv.classList.contains('dark')).toBe(false);
    });
  });

  describe('#updateThemeStyles', () => {
    let mockPortalDiv;

    beforeEach(() => {
      mockPortalDiv = document.createElement('div');
      mockPortalDiv.id = 'portal';
      document.body.appendChild(mockPortalDiv);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('updates theme styles based on theme', () => {
      window.portalConfig = { portalColor: '#FF5733' };
      updateThemeStyles('dark');
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });
  });

  describe('toggleAppearanceDropdown', () => {
    it('sets dropdown display to flex if initially none', () => {
      document.body.innerHTML = `<div id="appearance-dropdown" style="display: none;"></div>`;
      toggleAppearanceDropdown();
      const dropdown = document.getElementById('appearance-dropdown');
      expect(dropdown.style.display).toBe('flex');
    });

    it('sets dropdown display to none if initially flex', () => {
      document.body.innerHTML = `<div id="appearance-dropdown" style="display: flex;"></div>`;
      toggleAppearanceDropdown();
      const dropdown = document.getElementById('appearance-dropdown');
      expect(dropdown.style.display).toBe('none');
    });

    it('does nothing if dropdown element does not exist', () => {
      document.body.innerHTML = ``;
      expect(() => toggleAppearanceDropdown()).not.toThrow();
    });
  });

  describe('switchTheme', () => {
    let mockPortalDiv;

    beforeEach(() => {
      mockPortalDiv = document.createElement('div');
      mockPortalDiv.id = 'portal';
      document.body.appendChild(mockPortalDiv);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('sets theme to system', () => {
      window.portalConfig = { theme: 'dark', portalColor: '#FF5733' };
      switchTheme('dark');
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('sets theme to dark', () => {
      window.portalConfig = { theme: 'dark', portalColor: '#FF5733' };
      switchTheme('dark');
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('sets theme to light', () => {
      window.portalConfig = { theme: 'light', portalColor: '#FF5733' };
      switchTheme('light');
      expect(mockPortalDiv.classList.contains('light')).toBe(true);
    });
  });

  describe('#updateThemeSelectionInHeader', () => {
    let mockThemeSelectionInHeaderContainer;

    beforeEach(() => {
      mockThemeSelectionInHeaderContainer = document.createElement('div');
      mockThemeSelectionInHeaderContainer.id = 'toggle-appearance';
      document.body.appendChild(mockThemeSelectionInHeaderContainer);

      const themes = ['dark', 'light', 'system'];
      themes.forEach(theme => {
        const button = document.createElement('button');
        button.classList.add('theme-button', `${theme}-theme`);
        mockThemeSelectionInHeaderContainer.appendChild(button);
      });
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('updates theme selection in header', () => {
      window.portalConfig = { theme: 'dark', portalColor: '#FF5733' };
      updateThemeSelectionInHeader('dark');
      const darkThemeButton = document.querySelector(
        '.theme-button.dark-theme'
      );
      expect(darkThemeButton.classList.contains('flex')).toBe(true);
    });

    it('does nothing if theme selection in header container is not present', () => {
      document.body.innerHTML = ``;
      expect(() => updateThemeSelectionInHeader('dark')).not.toThrow();
    });
  });

  describe('#setActiveThemeIconInDropdown', () => {
    let mockThemeSwitchButtonsContainer;

    beforeEach(() => {
      mockThemeSwitchButtonsContainer = document.createElement('div');
      mockThemeSwitchButtonsContainer.id = 'appearance-dropdown';
      document.body.appendChild(mockThemeSwitchButtonsContainer);

      const themes = ['dark', 'light', 'system'];
      themes.forEach(theme => {
        const button = document.createElement('button');
        button.classList.add('check-mark-icon', `${theme}-theme`);
        mockThemeSwitchButtonsContainer.appendChild(button);
      });
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('updates active theme icon in dropdown', () => {
      window.portalConfig = { theme: 'dark', portalColor: '#FF5733' };
      setActiveThemeIconInDropdown('dark');
      const darkThemeIcon = document.querySelector(
        '.check-mark-icon.dark-theme'
      );
      expect(darkThemeIcon.classList.contains('flex')).toBe(true);
    });

    it('does nothing if theme switch buttons container is not present', () => {
      document.body.innerHTML = ``;
      expect(() => setActiveThemeIconInDropdown('dark')).not.toThrow();
    });
  });

  describe('#updateTheme', () => {
    it('updates system_theme cookie and styles', () => {
      const mockCookie = 'system_theme';
      const mockTheme = 'light';
      updateTheme(mockTheme, mockCookie);
      expect(Cookies.set).toBeCalledWith(mockCookie, mockTheme, {
        expires: 365,
      });
    });

    it('updates selected_theme cookie and styles', () => {
      const mockCookie = 'selected_theme';
      const mockTheme = 'dark';
      updateTheme(mockTheme, mockCookie);
      expect(Cookies.set).toBeCalledWith(mockCookie, mockTheme, {
        expires: 365,
      });
    });
  });

  describe('#updateThemeBasedOnSystem', () => {
    let mockPortalDiv;

    beforeEach(() => {
      mockPortalDiv = document.createElement('div');
      mockPortalDiv.id = 'portal';
      document.body.appendChild(mockPortalDiv);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('updates theme based on system preferences', () => {
      const mediaQueryList = {
        matches: true,
        addEventListener: jest.fn(),
      };
      window.matchMedia = jest.fn().mockReturnValue(mediaQueryList);

      mediaQueryList.addEventListener('change', e => {
        updateThemeBasedOnSystem(e, 'system_theme');
      });

      expect(mediaQueryList.addEventListener).toBeCalledWith(
        'change',
        expect.any(Function)
      );
    });

    it('if selected_theme cookie is not system, does nothing', () => {
      const mediaQueryList = {
        matches: true,
        addEventListener: jest.fn(),
      };
      window.matchMedia = jest.fn().mockReturnValue(mediaQueryList);
      window.portalConfig = { theme: 'system', portalColor: '#FFFFFF' };
      Cookies.get = jest.fn().mockReturnValue('dark');

      updateThemeBasedOnSystem(mediaQueryList, 'system_theme');

      expect(mediaQueryList.addEventListener).not.toBeCalledWith(
        'change',
        expect.any(Function)
      );
      expect(mockPortalDiv.classList.contains('dark')).toBe(false);
    });

    it('does nothing if selected theme is not system', () => {
      const mediaQueryList = {
        matches: true,
        addEventListener: jest.fn(),
      };
      window.matchMedia = jest.fn().mockReturnValue(mediaQueryList);
      window.portalConfig = { theme: 'dark', portalColor: '#FFFFFF' };

      updateThemeBasedOnSystem(mediaQueryList, 'system_theme');

      expect(mediaQueryList.addEventListener).not.toBeCalledWith(
        'change',
        expect.any(Function)
      );
      expect(mockPortalDiv.classList.contains('dark')).toBe(false);
    });
  });

  describe('#initializeTheme', () => {
    let mockPortalDiv;
    let mockThemeSelectionInHeaderContainer;
    let mockThemeSwitchButtonsContainer;

    beforeEach(() => {
      mockPortalDiv = document.createElement('div');
      mockPortalDiv.id = 'portal';
      document.body.appendChild(mockPortalDiv);

      mockThemeSelectionInHeaderContainer = document.createElement('div');
      mockThemeSelectionInHeaderContainer.id = 'toggle-appearance';
      document.body.appendChild(mockThemeSelectionInHeaderContainer);

      mockThemeSwitchButtonsContainer = document.createElement('div');
      mockThemeSwitchButtonsContainer.id = 'appearance-dropdown';
      document.body.appendChild(mockThemeSwitchButtonsContainer);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('updates theme based on system preferences', () => {
      const mediaQueryList = {
        matches: true,
        addEventListener: jest.fn(),
      };
      window.matchMedia = jest.fn().mockReturnValue(mediaQueryList);
      window.portalConfig = { theme: 'system', portalColor: '#FFFFFF' };

      initializeTheme();

      expect(mediaQueryList.addEventListener).toBeCalledWith(
        'change',
        expect.any(Function)
      );
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('updates theme based on portal theme dark', () => {
      window.portalConfig = { theme: 'dark', portalColor: '#F93443' };

      initializeTheme();

      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('updates theme based on portal theme light', () => {
      window.portalConfig = { theme: 'light', portalColor: '#023223' };

      initializeTheme();

      expect(mockPortalDiv.classList.contains('light')).toBe(true);
    });
  });

  describe('initializeToggleButton', () => {
    it('adds a click listener to the toggle button', () => {
      document.body.innerHTML = `<button id="toggle-appearance"></button>`;
      initializeToggleButton();
      const toggleButton = document.getElementById('toggle-appearance');
      expect(toggleButton.onclick).toBeDefined();
    });

    it('does nothing if the toggle button is not present', () => {
      document.body.innerHTML = ``;
      expect(() => initializeToggleButton()).not.toThrow();
    });
  });

  describe('initializeThemeSwitchButtons', () => {
    it('adds click listeners to theme switch buttons', () => {
      document.body.innerHTML = `<div id="appearance-dropdown"><button data-theme="dark"></button><button data-theme="light"></button></div>`;
      initializeThemeSwitchButtons();
      const buttons = document.querySelectorAll('button[data-theme]');
      buttons.forEach(button => expect(button.onclick).toBeDefined());
    });

    it('does nothing if theme switch buttons are not present', () => {
      document.body.innerHTML = ``;
      expect(() => initializeThemeSwitchButtons()).not.toThrow();
    });

    it('does nothing if appearance-dropdown is not present', () => {
      document.body.innerHTML = ``;
      expect(() => initializeThemeSwitchButtons()).not.toThrow();
    });
  });
});
