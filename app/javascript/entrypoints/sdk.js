import Cookies from 'js-cookie';
import { IFrameHelper } from '../sdk/IFrameHelper';
import {
  getBubbleView,
  getDarkMode,
  getWidgetStyle,
} from '../sdk/settingsHelper';
import {
  computeHashForUserData,
  getUserCookieName,
  hasUserKeys,
} from '../sdk/cookieHelpers';
import {
  addClasses,
  removeClasses,
  restoreWidgetInDOM,
} from '../sdk/DOMHelpers';
import { setCookieWithDomain } from '../sdk/cookieHelpers';
import { SDK_SET_BUBBLE_VISIBILITY } from 'shared/constants/sharedFrameEvents';

const DA_GTAG = 'G-0TZXQ9VF8N';
const DA_DATALAYER = 'daDataLayer';

const initializeGoogleAnalytics = () => {
  // Only load the google analytics script once to avoid double counting
  if (!document.querySelector('script[src*="gtag/js?id=' + DA_GTAG + '"]')) {
    const script = document.createElement('script');
    script.async = true;
    script.src = 'https://www.googletagmanager.com/gtag/js?id=' + DA_GTAG + '&l=' + DA_DATALAYER;
    document.head.appendChild(script);
  }

  window.daDataLayer = window.daDataLayer || [];
  function daGtag() { daDataLayer.push(arguments); }
  window.daGtag = daGtag;

  window.daGtag('js', new Date());
  window.daGtag('config', DA_GTAG, { name: DA_DATALAYER });

  window.trackGAEvent = (name, params = {}) => {
    if (window.daGtag) {
      window.daGtag('event', name, params);
    } else {
      console.warn('daGtag is not available.');
    }
  };
};

const runSDK = ({ baseUrl, websiteToken }) => {
  // Capture the start time
  const startTime = performance.now();

  // Check for mini-cart form
  const miniCart = document.querySelector('form.mini-cart');
  if (miniCart) {
    console.log('Mini cart found, setting up visibility observer');
    
    // Function to check if element is visible
    const isElementVisible = (element) => {
      const isHidden = element.getAttribute('aria-hidden') === 'true';
      console.log('Mini cart visibility check:', {
        ariaHidden: element.getAttribute('aria-hidden'),
        isHidden
      });
      return !isHidden;
    };

    // Function to check if we're on mobile
    const isMobileScreen = () => {
      return window.matchMedia('(max-width: 768px)').matches;
    };

    // Function to update chat bubble visibility
    const updateChatVisibility = () => {
      console.log('Checking mini-cart visibility...');
      const isVisible = isElementVisible(miniCart);
      const isMobile = isMobileScreen();
      
      if (isVisible && isMobile) {
        console.log('Hiding chat bubble - mini-cart is visible on mobile');
        window.$chatwoot?.toggleBubbleVisibility('hide');
      } else {
        console.log('Showing chat bubble - mini-cart is hidden or not on mobile');
        window.$chatwoot?.toggleBubbleVisibility('show');
      }
    };

    // Initial check
    updateChatVisibility();

    // Set up mutation observer to watch for aria-hidden changes
    const observer = new MutationObserver((mutations) => {
      console.log('Mutation detected:', mutations);
      // Wait for the next animation frame to let the DOM update complete
      requestAnimationFrame(() => {
        // Small additional delay to ensure all updates are applied
        setTimeout(updateChatVisibility, 50);
      });
    });

    // Observe the mini-cart form for changes
    observer.observe(miniCart, {
      attributes: true,
      attributeFilter: ['aria-hidden']
    });

    // Also check on window resize
    window.addEventListener('resize', () => {
      requestAnimationFrame(updateChatVisibility);
    });
  } else {
    console.log('No mini cart found on the page');
  }

  // Initialize Google Analytics
  initializeGoogleAnalytics();

  if (window.Turbo) {
    // if this is a Rails Turbo app
    document.addEventListener('turbo:before-render', event =>
      restoreWidgetInDOM(event.detail.newBody)
    );
  }

  if (window.Turbolinks) {
    document.addEventListener('turbolinks:before-render', event => {
      restoreWidgetInDOM(event.data.newBody);
    });
  }

  // if this is an astro app
  document.addEventListener('astro:before-swap', event =>
    restoreWidgetInDOM(event.newDocument.body)
  );

  const chatwootSettings = window.chatwootSettings || {};
  let locale = chatwootSettings.locale;
  let baseDomain = chatwootSettings.baseDomain;

  if (chatwootSettings.useBrowserLanguage) {
    locale = window.navigator.language.replace('-', '_');
  }

  window.$chatwoot = {
    baseUrl,
    baseDomain,
    hasLoaded: false,
    hideMessageBubble: chatwootSettings.hideMessageBubble || false,
    isOpen: false,
    position: chatwootSettings.position === 'left' ? 'left' : 'right',
    websiteToken,
    locale,
    useBrowserLanguage: chatwootSettings.useBrowserLanguage || false,
    type: getBubbleView(chatwootSettings.type),
    launcherTitle: chatwootSettings.launcherTitle || '',
    showPopoutButton: chatwootSettings.showPopoutButton || false,
    showUnreadMessagesDialog: chatwootSettings.showUnreadMessagesDialog ?? true,
    widgetStyle: getWidgetStyle(chatwootSettings.widgetStyle) || 'standard',
    resetTriggered: false,
    darkMode: getDarkMode(chatwootSettings.darkMode),
    customBubbleIcon: chatwootSettings.customBubbleIcon || (window.globalConfig?.LOGO_THUMBNAIL ?? baseUrl + '/brand-assets/chat_icon_only.svg'),

    toggle(state) {
      IFrameHelper.events.toggleBubble(state);
    },

    toggleBubbleVisibility(visibility) {
      let widgetElm = document.querySelector('.woot--bubble-holder');
      let widgetHolder = document.querySelector('.woot-widget-holder');
      if (visibility === 'hide') {
        addClasses(widgetHolder, 'woot-widget--without-bubble');
        addClasses(widgetElm, 'woot-hidden');
        window.$chatwoot.hideMessageBubble = true;
      } else if (visibility === 'show') {
        removeClasses(widgetElm, 'woot-hidden');
        removeClasses(widgetHolder, 'woot-widget--without-bubble');
        window.$chatwoot.hideMessageBubble = false;
      }
      IFrameHelper.sendMessage(SDK_SET_BUBBLE_VISIBILITY, {
        hideMessageBubble: window.$chatwoot.hideMessageBubble,
      });
    },

    popoutChatWindow() {
      IFrameHelper.events.popoutChatWindow({
        baseUrl: window.$chatwoot.baseUrl,
        websiteToken: window.$chatwoot.websiteToken,
        locale,
      });
    },

    setUser(identifier, user) {
      if (typeof identifier !== 'string' && typeof identifier !== 'number') {
        throw new Error('Identifier should be a string or a number');
      }

      if (!hasUserKeys(user)) {
        throw new Error(
          'User object should have one of the keys [avatar_url, email, name]'
        );
      }

      const userCookieName = getUserCookieName();
      const existingCookieValue = Cookies.get(userCookieName);
      const hashToBeStored = computeHashForUserData({ identifier, user });
      if (hashToBeStored === existingCookieValue) {
        return;
      }

      window.$chatwoot.identifier = identifier;
      window.$chatwoot.user = user;
      IFrameHelper.sendMessage('set-user', { identifier, user });

      setCookieWithDomain(userCookieName, hashToBeStored, {
        baseDomain,
      });
    },

    setCustomAttributes(customAttributes = {}) {
      if (!customAttributes || !Object.keys(customAttributes).length) {
        throw new Error('Custom attributes should have atleast one key');
      } else {
        IFrameHelper.sendMessage('set-custom-attributes', { customAttributes });
      }
    },

    deleteCustomAttribute(customAttribute = '') {
      if (!customAttribute) {
        throw new Error('Custom attribute is required');
      } else {
        IFrameHelper.sendMessage('delete-custom-attribute', {
          customAttribute,
        });
      }
    },

    setConversationCustomAttributes(customAttributes = {}) {
      if (!customAttributes || !Object.keys(customAttributes).length) {
        throw new Error('Custom attributes should have atleast one key');
      } else {
        IFrameHelper.sendMessage('set-conversation-custom-attributes', {
          customAttributes,
        });
      }
    },

    deleteConversationCustomAttribute(customAttribute = '') {
      if (!customAttribute) {
        throw new Error('Custom attribute is required');
      } else {
        IFrameHelper.sendMessage('delete-conversation-custom-attribute', {
          customAttribute,
        });
      }
    },

    setLabel(label = '') {
      IFrameHelper.sendMessage('set-label', { label });
    },

    removeLabel(label = '') {
      IFrameHelper.sendMessage('remove-label', { label });
    },

    setLocale(localeToBeUsed = 'en') {
      IFrameHelper.sendMessage('set-locale', { locale: localeToBeUsed });
    },

    setColorScheme(darkMode = 'light') {
      IFrameHelper.sendMessage('set-color-scheme', {
        darkMode: getDarkMode(darkMode),
      });
    },

    reset() {
      if (window.$chatwoot.isOpen) {
        IFrameHelper.events.toggleBubble();
      }

      Cookies.remove('cw_conversation');
      Cookies.remove(getUserCookieName());

      const iframe = IFrameHelper.getAppFrame();
      iframe.src = IFrameHelper.getUrl({
        baseUrl: window.$chatwoot.baseUrl,
        websiteToken: window.$chatwoot.websiteToken,
      });

      window.$chatwoot.resetTriggered = true;
    },
  };

  IFrameHelper.createFrame({
    baseUrl,
    websiteToken,
  });

  // Compute time taken for entire runSDK function to run and page url
  const loadTimeMs = Math.round(performance.now() - startTime);
  const pageUrl = window.location.href;

  const payload = {
    load_time_ms: loadTimeMs,
    page_url: pageUrl,
  };
  // TODO: remove console.log after verification
  console.log('chat_sdk_loaded', payload);
  window.trackGAEvent('chat_sdk_loaded', payload);
};

window.dashassistSDK = {
  run: runSDK,
};
