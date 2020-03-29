import { IFrameHelper } from '../sdk/IFrameHelper';
import { onBubbleClick } from '../sdk/bubbleHelpers';

const runSDK = ({ baseUrl, websiteToken }) => {
  const chatwootSettings = window.chatwootSettings || {};
  window.$chatwoot = {
    hideMessageBubble: chatwootSettings.hideMessageBubble || false,
    position: chatwootSettings.position || 'right',
    hasLoaded: false,

    toggle() {
      onBubbleClick();
    },

    setUser(user) {
      window.$chatwoot.user = user || {};
      IFrameHelper.sendMessage('set-user', window.$chatwoot.user);
    },

    setLabel(label = '') {
      IFrameHelper.sendMessage('set-label', label);
    },

    removeLabel(label = '') {
      IFrameHelper.sendMessage('remove-label', label);
    },

    reset() {},
  };
  IFrameHelper.createFrame({
    baseUrl,
    websiteToken,
  });
};

window.chatwootSDK = {
  run: runSDK,
};
