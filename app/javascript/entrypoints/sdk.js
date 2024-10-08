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

const runSDK = ({ baseUrl, websiteToken }) => {
  console.log('runSDK called with:', { baseUrl, websiteToken });

  if (window.$chatwoot) {
    console.log('Chatwoot already initialized.');
    return;
  }

  if (window.Turbo) {
    console.log('Turbo detected.');
    document.addEventListener('turbo:before-render', event => {
      console.log('Turbo before render triggered.');
      restoreWidgetInDOM(event.detail.newBody);
    });
  }

  if (window.Turbolinks) {
    console.log('Turbolinks detected.');
    document.addEventListener('turbolinks:before-render', event => {
      console.log('Turbolinks before render triggered.');
      restoreWidgetInDOM(event.data.newBody);
    });
  }

  console.log('Checking for Astro app...');
  document.addEventListener('astro:before-swap', event => {
    console.log('Astro before swap triggered.');
    restoreWidgetInDOM(event.newDocument.body);
  });

  const chatwootSettings = window.chatwootSettings || {};
  console.log('Chatwoot settings:', chatwootSettings);

  let locale = chatwootSettings.locale;
  let baseDomain = chatwootSettings.baseDomain;
  console.log('Initial locale and baseDomain:', { locale, baseDomain });

  if (chatwootSettings.useBrowserLanguage) {
    locale = window.navigator.language.replace('-', '_');
    console.log('Using browser language:', locale);
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

    toggle(state) {
      console.log('Toggling bubble state:', state);
      IFrameHelper.events.toggleBubble(state);
    },

    toggleBubbleVisibility(visibility) {
      console.log('Toggling bubble visibility:', visibility);
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
      console.log('Popout chat window triggered.');
      IFrameHelper.events.popoutChatWindow({
        baseUrl: window.$chatwoot.baseUrl,
        websiteToken: window.$chatwoot.websiteToken,
        locale,
      });
    },

    setUser(identifier, user) {
      console.log('Setting user:', { identifier, user });
      if (typeof identifier !== 'string' && typeof identifier !== 'number') {
        console.error('Invalid identifier type:', identifier);
        throw new Error('Identifier should be a string or a number');
      }

      if (!hasUserKeys(user)) {
        console.error('User object is missing required keys:', user);
        throw new Error(
          'User object should have one of the keys [avatar_url, email, name]'
        );
      }

      const userCookieName = getUserCookieName();
      const existingCookieValue = Cookies.get(userCookieName);
      const hashToBeStored = computeHashForUserData({ identifier, user });
      console.log('User cookie name and hash:', {
        userCookieName,
        hashToBeStored,
      });

      if (hashToBeStored === existingCookieValue) {
        console.log('User hash matches existing cookie. No update needed.');
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
      console.log('Setting custom attributes:', customAttributes);
      if (!customAttributes || !Object.keys(customAttributes).length) {
        console.error('Invalid custom attributes:', customAttributes);
        throw new Error('Custom attributes should have at least one key');
      } else {
        IFrameHelper.sendMessage('set-custom-attributes', { customAttributes });
      }
    },

    deleteCustomAttribute(customAttribute = '') {
      console.log('Deleting custom attribute:', customAttribute);
      if (!customAttribute) {
        console.error('Custom attribute is missing.');
        throw new Error('Custom attribute is required');
      } else {
        IFrameHelper.sendMessage('delete-custom-attribute', {
          customAttribute,
        });
      }
    },

    setConversationCustomAttributes(customAttributes = {}) {
      console.log('Setting conversation custom attributes:', customAttributes);
      if (!customAttributes || !Object.keys(customAttributes).length) {
        console.error(
          'Invalid conversation custom attributes:',
          customAttributes
        );
        throw new Error('Custom attributes should have at least one key');
      } else {
        IFrameHelper.sendMessage('set-conversation-custom-attributes', {
          customAttributes,
        });
      }
    },

    deleteConversationCustomAttribute(customAttribute = '') {
      console.log('Deleting conversation custom attribute:', customAttribute);
      if (!customAttribute) {
        console.error('Conversation custom attribute is missing.');
        throw new Error('Custom attribute is required');
      } else {
        IFrameHelper.sendMessage('delete-conversation-custom-attribute', {
          customAttribute,
        });
      }
    },

    setLabel(label = '') {
      console.log('Setting label:', label);
      IFrameHelper.sendMessage('set-label', { label });
    },

    removeLabel(label = '') {
      console.log('Removing label:', label);
      IFrameHelper.sendMessage('remove-label', { label });
    },

    setLocale(localeToBeUsed = 'en') {
      console.log('Setting locale:', localeToBeUsed);
      IFrameHelper.sendMessage('set-locale', { locale: localeToBeUsed });
    },

    setColorScheme(darkMode = 'light') {
      console.log('Setting color scheme to:', darkMode);
      IFrameHelper.sendMessage('set-color-scheme', {
        darkMode: getDarkMode(darkMode),
      });
    },

    reset() {
      console.log('Resetting Chatwoot.');
      if (window.$chatwoot.isOpen) {
        IFrameHelper.events.toggleBubble();
      }

      Cookies.remove('cw_conversation');
      Cookies.remove(getUserCookieName());

      const iframe = IFrameHelper.getAppFrame();
      console.log('Reloading iframe with new URL.');
      iframe.src = IFrameHelper.getUrl({
        baseUrl: window.$chatwoot.baseUrl,
        websiteToken: window.$chatwoot.websiteToken,
      });

      window.$chatwoot.resetTriggered = true;
    },
  };

  console.log('Creating iframe for Chatwoot...');
  IFrameHelper.createFrame({
    baseUrl,
    websiteToken,
  });
};

window.chatwootSDK = {
  run: runSDK,
};
