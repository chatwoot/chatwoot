import Cookies from 'js-cookie';
import { IFrameHelper } from '../sdk/IFrameHelper';
import { getBubbleView } from '../sdk/bubbleHelpers';

const runSDK = ({ baseUrl, websiteToken }) => {
  const chatwootSettings = window.chatwootSettings || {};
  window.$chatwoot = {
    baseUrl,
    hasLoaded: false,
    hideMessageBubble: chatwootSettings.hideMessageBubble || false,
    isOpen: false,
    position: chatwootSettings.position === 'left' ? 'left' : 'right',
    websiteToken,
    locale: chatwootSettings.locale,
    type: getBubbleView(chatwootSettings.type),
    launcherTitle: chatwootSettings.launcherTitle || '',

    toggle() {
      IFrameHelper.events.toggleBubble();
    },

    setUser(identifier, user) {
      if (typeof identifier === 'string' || typeof identifier === 'number') {
        window.$chatwoot.identifier = identifier;
        window.$chatwoot.user = user || {};
        IFrameHelper.sendMessage('set-user', {
          identifier,
          user: window.$chatwoot.user,
        });
      } else {
        throw new Error('Identifier should be a string or a number');
      }
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

    setLabel(label = '') {
      IFrameHelper.sendMessage('set-label', { label });
    },

    removeLabel(label = '') {
      IFrameHelper.sendMessage('remove-label', { label });
    },

    setLocale(localeToBeUsed = 'en') {
      IFrameHelper.sendMessage('set-locale', { locale: localeToBeUsed });
    },

    reset() {
      if (window.$chatwoot.isOpen) {
        IFrameHelper.events.toggleBubble();
      }

      Cookies.remove('cw_conversation');
      const iframe = IFrameHelper.getAppFrame();
      iframe.src = IFrameHelper.getUrl({
        baseUrl: window.$chatwoot.baseUrl,
        websiteToken: window.$chatwoot.websiteToken,
      });
    },
  };

  IFrameHelper.createFrame({
    baseUrl,
    websiteToken,
  });
};

window.chatwootSDK = {
  run: runSDK,
};
