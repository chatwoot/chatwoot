import Cookies from 'js-cookie';
import {
  addClasses,
  loadCSS,
  removeClasses,
  onLocationChangeListener,
} from './DOMHelpers';
import {
  body,
  widgetHolder,
  createBubbleHolder,
  createBubbleIcon,
  bubbleSVG,
  chatBubble,
  closeBubble,
  bubbleHolder,
  onClickChatBubble,
  onBubbleClick,
  setBubbleText,
  addUnreadClass,
  removeUnreadClass,
  createGreetingPreview,
  showGreetingPreview,
  hideGreetingPreview,
  attachGreetingPreviewHandlers,
  createGreetingInputBox,
  showGreetingInputBox,
  hideGreetingInputBox,
  updateWidgetPosition,
  updateWidgetType,
} from './bubbleHelpers';
import { isWidgetColorLighter } from 'shared/helpers/colorHelper';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';
import {
  CHATWOOT_ERROR,
  CHATWOOT_POSTBACK,
  CHATWOOT_READY,
} from '../widget/constants/sdkEvents';
import { SET_USER_ERROR } from '../widget/constants/errorTypes';
import { getUserCookieName, setCookieWithDomain } from './cookieHelpers';
import {
  getAlertAudio,
  initOnEvents,
} from 'shared/helpers/AudioNotificationHelper';
import { isFlatWidgetStyle } from './settingsHelper';
import { popoutChatWindow } from '../widget/helpers/popoutHelper';
import addHours from 'date-fns/addHours';

const updateAuthCookie = (cookieContent, baseDomain = '') =>
  setCookieWithDomain('cw_conversation', cookieContent, {
    baseDomain,
  });

export const setWebWidgetMessageSentCookie = (baseDomain = '') => {
  setCookieWithDomain('cw_web_widget_message_sent', 'true', {
    baseDomain,
    expires: 365, // 1 year
  });
};

const updateCampaignReadStatus = baseDomain => {
  const expireBy = addHours(new Date(), 1);
  setCookieWithDomain('cw_snooze_campaigns_till', Number(expireBy), {
    expires: expireBy,
    baseDomain,
  });
};

export const IFrameHelper = {
  getUrl({ baseUrl, websiteToken }) {
    return `${baseUrl}/widget?website_token=${websiteToken}`;
  },
  createFrame: ({ baseUrl, websiteToken }) => {
    if (IFrameHelper.getAppFrame()) {
      return;
    }

    loadCSS();
    const iframe = document.createElement('iframe');
    const cwCookie = Cookies.get('cw_conversation');
    let widgetUrl = IFrameHelper.getUrl({ baseUrl, websiteToken });
    if (cwCookie) {
      widgetUrl = `${widgetUrl}&cw_conversation=${cwCookie}`;
    }
    iframe.src = widgetUrl;
    iframe.allow =
      'camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;';
    iframe.id = 'chatwoot_live_chat_widget';
    iframe.style.visibility = 'hidden';

    let holderClassName = `woot-widget-holder woot--hide woot-elements--${window.$chatwoot.position}`;
    if (window.$chatwoot.hideMessageBubble) {
      holderClassName += ` woot-widget--without-bubble`;
    }
    if (isFlatWidgetStyle(window.$chatwoot.widgetStyle)) {
      holderClassName += ` woot-widget-holder--flat`;
    }

    addClasses(widgetHolder, holderClassName);
    widgetHolder.id = 'cw-widget-holder';
    widgetHolder.dataset.turboPermanent = true;
    widgetHolder.appendChild(iframe);
    body.appendChild(widgetHolder);
    IFrameHelper.initPostMessageCommunication();
    IFrameHelper.initWindowSizeListener();
    IFrameHelper.preventDefaultScroll();
  },
  getAppFrame: () => document.getElementById('chatwoot_live_chat_widget'),
  getBubbleHolder: () => document.getElementsByClassName('woot--bubble-holder'),
  sendMessage: (key, value) => {
    const element = IFrameHelper.getAppFrame();
    element.contentWindow.postMessage(
      `chatwoot-widget:${JSON.stringify({ event: key, ...value })}`,
      '*'
    );
  },
  initPostMessageCommunication: () => {
    window.onmessage = e => {
      if (
        typeof e.data !== 'string' ||
        e.data.indexOf('chatwoot-widget:') !== 0
      ) {
        return;
      }

      const message = JSON.parse(e.data.replace('chatwoot-widget:', ''));
      if (typeof IFrameHelper.events[message.event] === 'function') {
        IFrameHelper.events[message.event](message);
      }
    };
  },
  initWindowSizeListener: () => {
    window.addEventListener('resize', () => IFrameHelper.toggleCloseButton());
  },
  preventDefaultScroll: () => {
    widgetHolder.addEventListener('wheel', event => {
      const deltaY = event.deltaY;
      const contentHeight = widgetHolder.scrollHeight;
      const visibleHeight = widgetHolder.offsetHeight;
      const scrollTop = widgetHolder.scrollTop;

      if (
        (scrollTop === 0 && deltaY < 0) ||
        (visibleHeight + scrollTop === contentHeight && deltaY > 0)
      ) {
        event.preventDefault();
      }
    });
  },

  setFrameHeightToFitContent: (extraHeight, isFixedHeight) => {
    const iframe = IFrameHelper.getAppFrame();
    const updatedIframeHeight = isFixedHeight ? `${extraHeight}px` : '100%';

    if (iframe)
      iframe.setAttribute('style', `height: ${updatedIframeHeight} !important`);
  },

  setupAudioListeners: () => {
    const { baseUrl = '' } = window.$chatwoot;
    getAlertAudio(baseUrl, { type: 'widget', alertTone: 'ding' }).then(() =>
      initOnEvents.forEach(event => {
        document.removeEventListener(
          event,
          IFrameHelper.setupAudioListeners,
          false
        );
      })
    );
  },

  events: {
    loaded: message => {
      updateAuthCookie(message.config.authToken, window.$chatwoot.baseDomain);
      window.$chatwoot.hasLoaded = true;
      const campaignsSnoozedTill = Cookies.get('cw_snooze_campaigns_till');

      const {
        channelConfig: {
          position: configPosition,
          widget_position: widgetPosition,
          widgetPosition: widgetPositionCamel,
          widget_type: widgetType,
          widgetType: widgetTypeAlt,
          avatarUrl,
          avatarName,
          welcomeTitle,
          welcome_title: welcomeTitleAlt,
          welcomeTagline,
          welcome_tagline: welcomeTaglineAlt,
          greetingMessage,
          greeting_message: greetingMessageAlt,
          launcherTitle,
          launcher_title: launcherTitleAlt,
        },
      } = message.config;

      // Update position BEFORE onLoad so bubble is created with correct position
      const position =
        configPosition ||
        widgetPosition ||
        widgetPositionCamel ||
        window.$chatwoot.position;
      // Normalize position to 'left' or 'right'
      window.$chatwoot.position = position === 'left' ? 'left' : 'right';

      IFrameHelper.sendMessage('config-set', {
        locale: window.$chatwoot.locale,
        position: window.$chatwoot.position,
        hideMessageBubble: window.$chatwoot.hideMessageBubble,
        showPopoutButton: window.$chatwoot.showPopoutButton,
        widgetStyle: window.$chatwoot.widgetStyle,
        darkMode: window.$chatwoot.darkMode,
        showUnreadMessagesDialog: window.$chatwoot.showUnreadMessagesDialog,
        campaignsSnoozedTill,
        welcomeTitle: window.$chatwoot.welcomeTitle,
        welcomeDescription: window.$chatwoot.welcomeDescription,
        welcomeTagline: window.$chatwoot.welcomeTagline,
        greetingMessage: window.$chatwoot.greetingMessage,
        dealerName: window.$chatwoot.dealerName,
        avatarName: window.$chatwoot.avatarName,
        availableMessage: window.$chatwoot.availableMessage,
        unavailableMessage: window.$chatwoot.unavailableMessage,
        enableFileUpload: window.$chatwoot.enableFileUpload,
        enableEmojiPicker: window.$chatwoot.enableEmojiPicker,
        enableEndConversation: window.$chatwoot.enableEndConversation,
      });
      IFrameHelper.onLoad({
        widgetColor: message.config.channelConfig.widgetColor,
        channelConfig: message.config.channelConfig,
      });
      IFrameHelper.toggleCloseButton();

      window.$chatwoot.avatarUrl = avatarUrl || window.$chatwoot.avatarUrl;
      window.$chatwoot.avatarName = avatarName || window.$chatwoot.avatarName;
      window.$chatwoot.welcomeTitle =
        welcomeTitle || welcomeTitleAlt || window.$chatwoot.welcomeTitle;
      window.$chatwoot.welcomeDescription =
        welcomeTagline ||
        welcomeTaglineAlt ||
        window.$chatwoot.welcomeDescription;
      window.$chatwoot.greetingMessage =
        greetingMessage ||
        greetingMessageAlt ||
        window.$chatwoot.greetingMessage;

      const newLauncherTitle =
        launcherTitle || launcherTitleAlt || window.$chatwoot.launcherTitle;
      if (newLauncherTitle !== window.$chatwoot.launcherTitle) {
        window.$chatwoot.launcherTitle = newLauncherTitle;
        setBubbleText(newLauncherTitle);
      }

      const newWidgetType = widgetType || widgetTypeAlt;
      if (newWidgetType && newWidgetType !== window.$chatwoot.type) {
        updateWidgetType(newWidgetType);
      }

      // Update position classes - always call to ensure position is applied
      // This handles cases where bubble was created before position was updated
      updateWidgetPosition(window.$chatwoot.position);

      if (window.$chatwoot.user) {
        IFrameHelper.sendMessage('set-user', window.$chatwoot.user);
      }

      window.playAudioAlert = () => {};

      initOnEvents.forEach(e => {
        document.addEventListener(e, IFrameHelper.setupAudioListeners, false);
      });

      if (!window.$chatwoot.resetTriggered) {
        dispatchWindowEvent({ eventName: CHATWOOT_READY });
      }
    },
    error: ({ errorType, data }) => {
      dispatchWindowEvent({ eventName: CHATWOOT_ERROR, data: data });

      if (errorType === SET_USER_ERROR) {
        Cookies.remove(getUserCookieName());
      }
    },
    onEvent({ eventIdentifier: eventName, data }) {
      dispatchWindowEvent({ eventName, data });
    },
    setBubbleLabel(message) {
      setBubbleText(window.$chatwoot.launcherTitle || message.label);
    },

    setAuthCookie({ data: { widgetAuthToken } }) {
      updateAuthCookie(widgetAuthToken, window.$chatwoot.baseDomain);
    },

    setCampaignReadOn() {
      updateCampaignReadStatus(window.$chatwoot.baseDomain);
    },

    postback(data) {
      dispatchWindowEvent({
        eventName: CHATWOOT_POSTBACK,
        data,
      });
    },

    toggleBubble: state => {
      let bubbleState = {};
      if (state === 'open') {
        bubbleState.toggleValue = true;
      } else if (state === 'close') {
        bubbleState.toggleValue = false;
      }

      onBubbleClick(bubbleState);
    },

    popoutChatWindow: ({ baseUrl, websiteToken, locale }) => {
      const cwCookie = Cookies.get('cw_conversation');
      window.$chatwoot.toggle('close');
      popoutChatWindow(baseUrl, websiteToken, locale, cwCookie);
    },

    closeWindow: () => {
      onBubbleClick({ toggleValue: false });
      removeUnreadClass();
    },

    onBubbleToggle: isOpen => {
      IFrameHelper.sendMessage('toggle-open', { isOpen });
      if (isOpen) {
        IFrameHelper.pushEvent('webwidget.triggered');
      }
    },
    onLocationChange: ({ referrerURL, referrerHost }) => {
      IFrameHelper.sendMessage('change-url', {
        referrerURL,
        referrerHost,
      });
    },
    updateIframeHeight: message => {
      const { extraHeight = 0, isFixedHeight } = message;

      IFrameHelper.setFrameHeightToFitContent(extraHeight, isFixedHeight);
    },

    setUnreadMode: () => {
      addUnreadClass();
      if (!window.$chatwoot?.openingForSms) {
        onBubbleClick({ toggleValue: true });
      }
    },

    resetUnreadMode: () => removeUnreadClass(),
    handleNotificationDot: event => {
      if (window.$chatwoot.hideMessageBubble) {
        return;
      }

      const bubbleElement = document.querySelector('.woot-widget-bubble');
      if (
        event.unreadMessageCount > 0 &&
        !bubbleElement.classList.contains('unread-notification')
      ) {
        addClasses(bubbleElement, 'unread-notification');
      } else if (event.unreadMessageCount === 0) {
        removeClasses(bubbleElement, 'unread-notification');
      }
    },

    closeChat: () => {
      onBubbleClick({ toggleValue: false });
    },

    playAudio: () => {
      window.playAudioAlert();
    },
    'has-conversations': message => {
      window.$chatwoot.hasConversations = message.hasConversations || false;
      window.$chatwoot.conversationStateConfirmed = true;

      const storedSmsState = localStorage.getItem('chatwoot_sms_state');
      let smsWasSent = false;
      if (storedSmsState) {
        try {
          const smsState = JSON.parse(storedSmsState);
          if (smsState.sent) {
            const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
            if (smsState.timestamp && smsState.timestamp >= oneDayAgo) {
              smsWasSent = true;
            }
          }
        } catch (e) {
          // Ignore parse errors
        }
      }

      if (message.hasConversations) {
        hideGreetingPreview();
        hideGreetingInputBox();
      }

      if (
        (smsWasSent || message.hasConversations) &&
        !window.$chatwoot.isOpen
      ) {
        hideGreetingPreview();
        hideGreetingInputBox();
        if (smsWasSent) {
          window.$chatwoot.openingForSms = true;
        }
        onBubbleClick({ toggleValue: true });
      } else if (!message.hasConversations && !smsWasSent) {
        if (
          !window.$chatwoot.isOpen &&
          !window.$chatwoot.greetingPreviewShown
        ) {
          showGreetingPreview();
          showGreetingInputBox();
          window.$chatwoot.greetingPreviewShown = true;
        }
      }
    },
  },
  pushEvent: eventName => {
    IFrameHelper.sendMessage('push-event', { eventName });
  },

  onLoad: ({ widgetColor, channelConfig = {} }) => {
    const iframe = IFrameHelper.getAppFrame();
    iframe.style.visibility = '';
    iframe.setAttribute('id', `chatwoot_live_chat_widget`);

    if (IFrameHelper.getBubbleHolder().length) {
      return;
    }
    createBubbleHolder(window.$chatwoot.hideMessageBubble);
    onLocationChangeListener();

    let className = 'woot-widget-bubble';
    let closeBtnClassName = `woot-elements--${window.$chatwoot.position} woot-widget-bubble woot--close woot--hide`;

    if (isFlatWidgetStyle(window.$chatwoot.widgetStyle)) {
      className += ' woot-widget-bubble--flat';
      closeBtnClassName += ' woot-widget-bubble--flat';
    }

    if (isWidgetColorLighter(widgetColor)) {
      className += ' woot-widget-bubble-color--lighter';
      closeBtnClassName += ' woot-widget-bubble-color--lighter';
    }

    const chatIcon = createBubbleIcon({
      className,
      path: bubbleSVG,
      target: chatBubble,
      widgetColor,
    });

    addClasses(closeBubble, closeBtnClassName);

    const avatarUrl = window.$chatwoot.avatarUrl;
    if (!avatarUrl) {
      chatIcon.style.background = widgetColor;
    }
    closeBubble.style.background = widgetColor;

    bubbleHolder.appendChild(chatIcon);
    bubbleHolder.appendChild(closeBubble);
    onClickChatBubble();

    // Create and show greeting preview after 3 seconds
    // Get data from channelConfig (passed from widget) or window.$chatwoot or chatwootSettings
    const chatwootSettings = window.chatwootSettings || {};

    // Try to get from widget config first, then window.$chatwoot, then chatwootSettings
    const previewAvatarUrl =
      channelConfig.avatarUrl ||
      window.$chatwoot.avatarUrl ||
      chatwootSettings.avatarUrl ||
      '';
    const previewAgentName =
      channelConfig.avatarName ||
      window.$chatwoot.avatarName ||
      chatwootSettings.avatarName ||
      window.$chatwoot.websiteName ||
      channelConfig.websiteName ||
      '';
    const previewDealerName =
      channelConfig.dealerName ||
      window.$chatwoot.dealerName ||
      chatwootSettings.dealerName ||
      window.$chatwoot.websiteName ||
      channelConfig.websiteName ||
      '';
    // Get greeting message based on greeting_enabled flag
    const defaultGreetingMessage =
      'Hi there! 👋 How can I help? Send me a message!';

    const getGreetingMessage = () => {
      // Check if greeting is enabled (from inbox settings)
      let isGreetingEnabled = true; // Default to enabled if not specified
      if (channelConfig.greetingEnabled !== undefined) {
        isGreetingEnabled = channelConfig.greetingEnabled;
      } else if (channelConfig.greeting_enabled !== undefined) {
        isGreetingEnabled = channelConfig.greeting_enabled;
      } else if (window.$chatwoot.greetingEnabled !== undefined) {
        isGreetingEnabled = window.$chatwoot.greetingEnabled;
      }

      // If disabled, show default message
      if (!isGreetingEnabled) {
        return defaultGreetingMessage;
      }

      // If enabled, get the greeting message from config
      const greetingMsg =
        channelConfig.greetingMessage ||
        channelConfig.greeting_message ||
        window.$chatwoot.greetingMessage ||
        chatwootSettings.greetingMessage;

      // If message exists and is not empty, use it; otherwise use default
      return greetingMsg && greetingMsg.trim()
        ? greetingMsg
        : defaultGreetingMessage;
    };

    const previewGreetingMessage = getGreetingMessage();

    // Always create greeting preview (it will always have a message now)
    createGreetingPreview({
      avatarUrl: previewAvatarUrl,
      agentName: previewAgentName,
      dealerName: previewDealerName,
      greetingMessage: previewGreetingMessage,
      widgetColor,
    });
    // Attach event handlers
    attachGreetingPreviewHandlers();

    // Create input box (conditionally shows "Text Us" button)
    createGreetingInputBox({
      widgetColor,
      hasSmsInbox: channelConfig.hasSmsInbox || false,
    });

    const webWidgetMessageSent =
      Cookies.get('cw_web_widget_message_sent') === 'true';
    window.$chatwoot.hasConversations = webWidgetMessageSent;
    window.$chatwoot.conversationStateConfirmed = false;
    window.$chatwoot.greetingPreviewShown = false;

    const storedSmsState = localStorage.getItem('chatwoot_sms_state');
    let smsWasSent = false;
    if (storedSmsState) {
      try {
        const smsState = JSON.parse(storedSmsState);
        if (smsState.sent) {
          const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
          if (smsState.timestamp && smsState.timestamp >= oneDayAgo) {
            smsWasSent = true;
          }
        }
      } catch (e) {
        // Ignore parse errors
      }
    }

    if ((smsWasSent || webWidgetMessageSent) && !window.$chatwoot.isOpen) {
      hideGreetingPreview();
      hideGreetingInputBox();
      if (smsWasSent) {
        window.$chatwoot.openingForSms = true;
      }
      setTimeout(() => {
        if (!window.$chatwoot.isOpen) {
          onBubbleClick({ toggleValue: true });
        }
      }, 500);
    } else if (!webWidgetMessageSent) {
      setTimeout(() => {
        if (
          !window.$chatwoot.isOpen &&
          !window.$chatwoot.greetingPreviewShown &&
          (!window.$chatwoot.conversationStateConfirmed ||
            !window.$chatwoot.hasConversations)
        ) {
          showGreetingPreview();
          showGreetingInputBox();
          window.$chatwoot.greetingPreviewShown = true;
        }
      }, 3000);
    }
  },
  toggleCloseButton: () => {
    let isMobile = false;
    if (window.matchMedia('(max-width: 668px)').matches) {
      isMobile = true;
    }
    IFrameHelper.sendMessage('toggle-close-button', { isMobile });
  },
};
