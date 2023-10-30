import {
  InitializationHelpers,
  generatePortalBgColor,
  generatePortalBg,
  generateGradientToBottom,
  setPortalBackgroundStyles,
  setPortalHoverStyles,
  setPortalClass,
  updateThemeStyles,
  toggleAppearanceDropdown,
  updateURLParameter,
  removeURLParameter,
  switchTheme,
} from '../portalHelpers';

describe('#navigateToLocalePage', () => {
  it('returns correct cookie name', () => {
    const elemDiv = document.createElement('div');
    elemDiv.classList.add('locale-switcher');
    document.body.appendChild(elemDiv);

    const allLocaleSwitcher = document.querySelector('.locale-switcher');

    allLocaleSwitcher.addEventListener = jest
      .fn()
      .mockImplementationOnce((event, callback) => {
        callback({ target: { value: 1 } });
      });

    InitializationHelpers.navigateToLocalePage();
    expect(allLocaleSwitcher.addEventListener).toBeCalledWith(
      'change',
      expect.any(Function)
    );
  });
});

describe('Theme Functions', () => {
  describe('#generatePortalBgColor', () => {
    it('returns mixed color for dark theme', () => {
      const result = generatePortalBgColor('#FF5733', 'dark');
      expect(result).toBe('color-mix(in srgb, #FF5733 20%, black)');
    });

    it('returns mixed color for light theme', () => {
      const result = generatePortalBgColor('#FF5733', 'light');
      expect(result).toBe('color-mix(in srgb, #FF5733 20%, white)');
    });
  });

  describe('#generatePortalBg', () => {
    it('returns background for dark theme', () => {
      const result = generatePortalBg('#FF5733', 'dark');
      expect(result).toBe(
        'url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)'
      );
    });

    it('returns background for light theme', () => {
      const result = generatePortalBg('#FF5733', 'light');
      expect(result).toBe(
        'url(/assets/images/hc/hexagon-light.svg) color-mix(in srgb, #FF5733 20%, white)'
      );
    });
  });

  describe('#generateGradientToBottom', () => {
    it('returns gradient for dark theme', () => {
      const result = generateGradientToBottom('dark');
      expect(result).toBe('linear-gradient(to bottom, transparent, #151718)');
    });

    it('returns gradient for light theme', () => {
      const result = generateGradientToBottom('light');
      expect(result).toBe('linear-gradient(to bottom, transparent, white)');
    });
  });

  describe('#setPortalBackgroundStyles', () => {
    beforeEach(() => {
      window.portalConfig = { portalColor: '#FF5733' };
    });

    afterEach(() => {
      document.documentElement.style.removeProperty('--dynamic-portal-bg');
      document.documentElement.style.removeProperty(
        '--dynamic-portal-bg-gradient'
      );
    });

    it('sets styles for portal background based on theme', () => {
      setPortalBackgroundStyles('dark');

      const portalBgStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-portal-bg');
      const portalBgGradientStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-portal-bg-gradient');

      const expectedPortalBgStyle =
        'url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)';
      const expectedGradientStyle =
        'linear-gradient(to bottom, transparent, #151718)';

      expect(portalBgStyle.trim()).toBe(expectedPortalBgStyle);
      expect(portalBgGradientStyle.trim()).toBe(expectedGradientStyle);
    });
  });

  describe('#setPortalHoverStyles', () => {
    beforeEach(() => {
      window.portalConfig = { portalColor: '#ff5733' };
    });

    afterEach(() => {
      document.documentElement.style.removeProperty('--dynamic-hover-bg-color');
      document.documentElement.style.removeProperty('--dynamic-hover-color');
    });

    it('sets styles for portal hover based on theme', () => {
      setPortalHoverStyles('dark');

      const hoverBgColorStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-hover-bg-color');
      const hoverColorStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-hover-color');

      const expectedHoverBgColorStyle =
        'color-mix(in srgb, #ff5733 5%, #1B1B1B)';
      const expectedHoverColorStyle = '#ff5733';

      expect(hoverBgColorStyle.trim()).toBe(expectedHoverBgColorStyle);
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

  describe('updateURLParameter', () => {
    it('updates a given parameter with a new value', () => {
      const originalUrl = 'http://example.com?param=oldValue';
      delete window.location;
      window.location = new URL(originalUrl);

      const updatedUrl = updateURLParameter('param', 'newValue');
      expect(updatedUrl).toContain('param=newValue');
    });

    it('adds a new parameter if it does not exist', () => {
      const originalUrl = 'http://example.com';
      delete window.location;
      window.location = new URL(originalUrl);

      const updatedUrl = updateURLParameter('newParam', 'value');
      expect(updatedUrl).toContain('newParam=value');
    });
  });

  describe('removeURLParameter', () => {
    it('removes an existing parameter', () => {
      const originalUrl = 'http://example.com?param=value';
      delete window.location;
      window.location = new URL(originalUrl);

      const updatedUrl = removeURLParameter('param');
      expect(updatedUrl).not.toContain('param=value');
    });

    it('does nothing if the parameter does not exist', () => {
      const originalUrl = 'http://example.com/';
      delete window.location;
      window.location = new URL(originalUrl);

      const updatedUrl = removeURLParameter('param');
      expect(updatedUrl).toBe(originalUrl);
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

    it('updates theme based on theme', () => {
      window.portalConfig = { portalColor: '#FF5733' };
      switchTheme('dark');

      const portalBgStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-portal-bg');
      const portalBgGradientStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-portal-bg-gradient');

      const expectedPortalBgStyle =
        'url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)';
      const expectedGradientStyle =
        'linear-gradient(to bottom, transparent, #151718)';
      expect(portalBgStyle.trim()).toBe(expectedPortalBgStyle);
      expect(portalBgGradientStyle.trim()).toBe(expectedGradientStyle);
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
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

      const portalBgStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-portal-bg');
      const portalBgGradientStyle = getComputedStyle(
        document.documentElement
      ).getPropertyValue('--dynamic-portal-bg-gradient');

      const expectedPortalBgStyle =
        'url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)';
      const expectedGradientStyle =
        'linear-gradient(to bottom, transparent, #151718)';

      expect(portalBgStyle.trim()).toBe(expectedPortalBgStyle);
      expect(portalBgGradientStyle.trim()).toBe(expectedGradientStyle);
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });
  });

  describe('#initializeTheme', () => {
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
      window.portalConfig = { theme: 'system', portalColor: '#FFFFFF' };

      InitializationHelpers.initializeTheme();

      expect(mediaQueryList.addEventListener).toBeCalledWith(
        'change',
        expect.any(Function)
      );
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('updates theme based on portal theme dark', () => {
      window.portalConfig = { theme: 'dark', portalColor: '#F93443' };

      InitializationHelpers.initializeTheme();

      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('updates theme based on portal theme light', () => {
      window.portalConfig = { theme: 'light', portalColor: '#023223' };

      InitializationHelpers.initializeTheme();

      expect(mockPortalDiv.classList.contains('light')).toBe(true);
    });
  });

  describe('initializeToggleButton', () => {
    it('adds a click listener to the toggle button', () => {
      document.body.innerHTML = `<button id="toggle-appearance"></button>`;
      InitializationHelpers.initializeToggleButton();
      const toggleButton = document.getElementById('toggle-appearance');
      expect(toggleButton.onclick).toBeDefined();
    });

    it('does nothing if the toggle button is not present', () => {
      document.body.innerHTML = ``;
      expect(() =>
        InitializationHelpers.initializeToggleButton()
      ).not.toThrow();
    });
  });

  describe('initializeThemeSwitchButtons', () => {
    it('adds click listeners to theme switch buttons', () => {
      document.body.innerHTML = `<div id="appearance-dropdown"><button data-theme="dark"></button><button data-theme="light"></button></div>`;
      InitializationHelpers.initializeThemeSwitchButtons();
      const buttons = document.querySelectorAll('button[data-theme]');
      buttons.forEach(button => expect(button.onclick).toBeDefined());
    });

    it('does nothing if theme switch buttons are not present', () => {
      document.body.innerHTML = ``;
      expect(() =>
        InitializationHelpers.initializeThemeSwitchButtons()
      ).not.toThrow();
    });

    it('does nothing if appearance-dropdown is not present', () => {
      document.body.innerHTML = ``;
      expect(() =>
        InitializationHelpers.initializeThemeSwitchButtons()
      ).not.toThrow();
    });
  });
});
