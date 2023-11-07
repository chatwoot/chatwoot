import {
  InitializationHelpers,
  generatePortalBgColor,
  generatePortalBg,
  generateGradientToBottom,
  setPortalStyles,
  setPortalClass,
  updateThemeStyles,
  openExternalLinksInNewTab,
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
        'background: url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)'
      );
    });

    it('returns background for light theme', () => {
      const result = generatePortalBg('#FF5733', 'light');
      expect(result).toBe(
        'background: url(/assets/images/hc/hexagon-light.svg) color-mix(in srgb, #FF5733 20%, white)'
      );
    });
  });

  describe('#generateGradientToBottom', () => {
    it('returns gradient for dark theme', () => {
      const result = generateGradientToBottom('dark');
      expect(result).toBe(
        'background-image: linear-gradient(to bottom, transparent, #151718)'
      );
    });

    it('returns gradient for light theme', () => {
      const result = generateGradientToBottom('light');
      expect(result).toBe(
        'background-image: linear-gradient(to bottom, transparent, white)'
      );
    });
  });

  describe('#setPortalStyles', () => {
    let mockPortalBgDiv;
    let mockPortalBgGradientDiv;

    beforeEach(() => {
      // Mocking portal background div
      mockPortalBgDiv = document.createElement('div');
      mockPortalBgDiv.id = 'portal-bg';
      document.body.appendChild(mockPortalBgDiv);

      // Mocking portal background gradient div
      mockPortalBgGradientDiv = document.createElement('div');
      mockPortalBgGradientDiv.id = 'portal-bg-gradient';
      document.body.appendChild(mockPortalBgGradientDiv);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('sets styles for portal background based on theme', () => {
      window.portalConfig = { portalColor: '#FF5733' };

      setPortalStyles('dark');
      const expectedPortalBgStyle =
        'background: url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)';
      const expectedGradientStyle =
        'background-image: linear-gradient(to bottom, transparent, #151718)';

      expect(mockPortalBgDiv.getAttribute('style')).toBe(expectedPortalBgStyle);
      expect(mockPortalBgGradientDiv.getAttribute('style')).toBe(
        expectedGradientStyle
      );
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

    it('sets portal class based on theme', () => {
      setPortalClass('dark');

      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
      expect(mockPortalDiv.classList.contains('light')).toBe(false);
    });
  });

  describe('#updateThemeStyles', () => {
    let mockPortalDiv;
    let mockPortalBgDiv;
    let mockPortalBgGradientDiv;

    beforeEach(() => {
      // Mocking portal div
      mockPortalDiv = document.createElement('div');
      mockPortalDiv.id = 'portal';
      document.body.appendChild(mockPortalDiv);

      // Mocking portal background div
      mockPortalBgDiv = document.createElement('div');
      mockPortalBgDiv.id = 'portal-bg';
      document.body.appendChild(mockPortalBgDiv);

      // Mocking portal background gradient div
      mockPortalBgGradientDiv = document.createElement('div');
      mockPortalBgGradientDiv.id = 'portal-bg-gradient';
      document.body.appendChild(mockPortalBgGradientDiv);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('updates theme styles based on theme', () => {
      window.portalConfig = { portalColor: '#FF5733' };

      updateThemeStyles('dark');

      const expectedPortalBgStyle =
        'background: url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #FF5733 20%, black)';
      const expectedGradientStyle =
        'background-image: linear-gradient(to bottom, transparent, #151718)';

      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
      expect(mockPortalBgDiv.getAttribute('style')).toBe(expectedPortalBgStyle);
      expect(mockPortalBgGradientDiv.getAttribute('style')).toBe(
        expectedGradientStyle
      );
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
      window.portalConfig = { theme: 'system' };

      InitializationHelpers.initializeTheme();

      expect(mediaQueryList.addEventListener).toBeCalledWith(
        'change',
        expect.any(Function)
      );
      expect(mockPortalDiv.classList.contains('dark')).toBe(true);
    });

    it('does not update theme if themeFromServer is not "system"', () => {
      const mediaQueryList = {
        matches: true,
        addEventListener: jest.fn(),
      };
      window.matchMedia = jest.fn().mockReturnValue(mediaQueryList);
      window.portalConfig = { theme: 'dark' };

      InitializationHelpers.initializeTheme();

      expect(mediaQueryList.addEventListener).not.toBeCalled();
      expect(mockPortalDiv.classList.contains('dark')).toBe(false);
      expect(mockPortalDiv.classList.contains('light')).toBe(false);
    });
  });

  describe('openExternalLinksInNewTab', () => {
    beforeAll(() => {
      delete window.location;
      delete global.window.location;

      global.window.portalConfig = {
        customDomain: 'chatwoot.help',
        hostURL: 'https://chatwoot.help',
      };
    });

    beforeEach(() => {
      // Mock the page not being an article page
      global.window.location = new URL('https://chatwoot.help');
    });

    // Helper function to create a sample link element
    function createLinkElement(href, id) {
      const link = document.createElement('a');
      link.href = href;
      link.id = id;
      document.body.appendChild(link);
      return link;
    }

    it('should not modify links when not on an article page', () => {
      global.window.location.pathname = '/hc/handbook/en/categories/company';

      // Create a sample link element
      createLinkElement('https://example.com/external-link', 'test-link-1');

      // Run the function
      openExternalLinksInNewTab();

      const link = document.querySelector('#test-link-1');

      // Expect that the link's target attribute is not changed
      expect(link.target).toBe('');
    });

    it('should modify external links when on an article page', () => {
      // Mock the page being an article page
      global.window.location.pathname = '/hc/handbook/articles/investors-27';

      createLinkElement('https://external-website.com', 'externalLink');
      openExternalLinksInNewTab();
      const externalLink = document.querySelector('#externalLink');

      // Expect that the external link's target attribute is set to '_blank'
      expect(externalLink.target).toBe('_blank');
    });

    it('should not modify relative links when on an article page', () => {
      // Mock the page being an article page
      global.window.location.pathname = '/hc/handbook/articles/investors-42';

      createLinkElement(
        'https://chatwoot.help/hc/handbook/articles/history-of-chatwoot-22',
        'internalLink'
      );
      openExternalLinksInNewTab();
      const internalLink = document.querySelector('#internalLink');

      // Expect that the external link's target attribute is set to '_blank'
      expect(internalLink.target).toBe('');
    });

    it('should correctly handle links with complex URLs', () => {
      // Mock the page being an article page
      global.window.location.pathname = '/hc/handbook/articles/investors-27';

      // Create a sample external link element with complex URL
      const complexExternalLink = createLinkElement(
        'https://sub.example.com/path?query=param'
      );

      // Create a sample internal link element with complex URL
      const complexInternalLink = createLinkElement(
        'https://chatwoot.help/hc/handbook/articles/history-of-chatwoot-39?theme=dark'
      );

      // Run the function
      openExternalLinksInNewTab();

      // Expect that the complex external link's target attribute is set to '_blank'
      expect(complexExternalLink.target).toBe('_blank');

      // Expect that the complex internal link's target attribute is not changed
      expect(complexInternalLink.target).toBe('');
    });
  });
});
