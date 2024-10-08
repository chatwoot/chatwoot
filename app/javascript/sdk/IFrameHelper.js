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
} from './bubbleHelpers';
import { isWidgetColorLighter } from 'shared/helpers/colorHelper';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';
import { CHATWOOT_ERROR, CHATWOOT_READY } from '../widget/constants/sdkEvents';
import { SET_USER_ERROR } from '../widget/constants/errorTypes';
import { getUserCookieName, setCookieWithDomain } from './cookieHelpers';
import {
  getAlertAudio,
  initOnEvents,
} from 'shared/helpers/AudioNotificationHelper';
import { isFlatWidgetStyle } from './settingsHelper';
import { popoutChatWindow } from '../widget/helpers/popoutHelper';
import addHours from 'date-fns/addHours';

const updateAuthCookie = (cookieContent, baseDomain = '') => {
  console.log('Updating auth cookie:', { cookieContent, baseDomain });
  setCookieWithDomain('cw_conversation', cookieContent, {
    baseDomain,
  });
};

const updateCampaignReadStatus = baseDomain => {
  console.log('Updating campaign read status:', { baseDomain });
  const expireBy = addHours(new Date(), 1);
  setCookieWithDomain('cw_snooze_campaigns_till', Number(expireBy), {
    expires: expireBy,
    baseDomain,
  });
};

export const IFrameHelper = {
  getUrl({ baseUrl, websiteToken }) {
    const url = `${baseUrl}/widget?website_token=${websiteToken}`;
    console.log('Generated widget URL:', url);
    return url;
  },
  createFrame: ({ baseUrl, websiteToken }) => {
    console.log('Creating iframe with:', { baseUrl, websiteToken });

    if (IFrameHelper.getAppFrame()) {
      console.log('Iframe already exists.');
      return;
    }

    loadCSS();
    const iframe = document.createElement('iframe');
    const cwCookie = Cookies.get('cw_conversation');
    let widgetUrl = IFrameHelper.getUrl({ baseUrl, websiteToken });
    if (cwCookie) {
      widgetUrl = `${widgetUrl}&cw_conversation=${cwCookie}`;
      console.log('Appending conversation cookie to widget URL:', widgetUrl);
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

    console.log('Holder class name:', holderClassName);

    addClasses(widgetHolder, holderClassName);
    widgetHolder.id = 'cw-widget-holder';
    widgetHolder.appendChild(iframe);
    body.appendChild(widgetHolder);
    IFrameHelper.initPostMessageCommunication();
    IFrameHelper.initWindowSizeListener();
    IFrameHelper.preventDefaultScroll();
  },
  getAppFrame: () => {
    const frame = document.getElementById('chatwoot_live_chat_widget');
    console.log('Retrieved app frame:', frame);
    return frame;
  },
  getBubbleHolder: () => {
    const holder = document.getElementsByClassName('woot--bubble-holder');
    console.log('Retrieved bubble holder:', holder);
    return holder;
  },
  sendMessage: (key, value) => {
    console.log('Sending message:', { key, value });
    const element = IFrameHelper.getAppFrame();
    element.contentWindow.postMessage(
      `chatwoot-widget:${JSON.stringify({ event: key, ...value })}`,
      '*'
    );
  },
  initPostMessageCommunication: () => {
    console.log('Initializing post message communication...');
    window.onmessage = e => {
      console.log('Message received:', e.data);
      if (
        typeof e.data !== 'string' ||
        e.data.indexOf('chatwoot-widget:') !== 0
      ) {
        return;
      }
      const message = JSON.parse(e.data.replace('chatwoot-widget:', ''));
      console.log('Parsed message:', message);
      if (typeof IFrameHelper.events[message.event] === 'function') {
        IFrameHelper.events[message.event](message);
      }
    };
  },
  initWindowSizeListener: () => {
    console.log('Initializing window size listener...');
    window.addEventListener('resize', () => IFrameHelper.toggleCloseButton());
  },
  preventDefaultScroll: () => {
    console.log('Adding scroll prevention on widget holder...');
    widgetHolder.addEventListener('wheel', event => {
      const deltaY = event.deltaY;
      const contentHeight = widgetHolder.scrollHeight;
      const visibleHeight = widgetHolder.offsetHeight;
      const scrollTop = widgetHolder.scrollTop;

      console.log('Scroll event:', {
        deltaY,
        contentHeight,
        visibleHeight,
        scrollTop,
      });

      if (
        (scrollTop === 0 && deltaY < 0) ||
        (visibleHeight + scrollTop === contentHeight && deltaY > 0)
      ) {
        event.preventDefault();
      }
    });
  },

  setFrameHeightToFitContent: (extraHeight, isFixedHeight) => {
    console.log('Setting iframe height:', { extraHeight, isFixedHeight });
    const iframe = IFrameHelper.getAppFrame();
    const updatedIframeHeight = isFixedHeight ? `${extraHeight}px` : '100%';

    if (iframe)
      iframe.setAttribute('style', `height: ${updatedIframeHeight} !important`);
  },

  setupAudioListeners: () => {
    console.log('Setting up audio listeners...');
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
      console.log('Widget loaded event:', message);
      updateAuthCookie(message.config.authToken, window.$chatwoot.baseDomain);
      window.$chatwoot.hasLoaded = true;
      const campaignsSnoozedTill = Cookies.get('cw_snooze_campaigns_till');
      console.log('Campaigns snoozed till:', campaignsSnoozedTill);
      IFrameHelper.sendMessage('config-set', {
        locale: window.$chatwoot.locale,
        position: window.$chatwoot.position,
        hideMessageBubble: window.$chatwoot.hideMessageBubble,
        showPopoutButton: window.$chatwoot.showPopoutButton,
        widgetStyle: window.$chatwoot.widgetStyle,
        darkMode: window.$chatwoot.darkMode,
        showUnreadMessagesDialog: window.$chatwoot.showUnreadMessagesDialog,
        campaignsSnoozedTill,
      });
      IFrameHelper.onLoad({
        widgetColor: message.config.channelConfig.widgetColor,
      });
      IFrameHelper.toggleCloseButton();

      if (window.$chatwoot.user) {
        console.log('Setting user on load:', window.$chatwoot.user);
        IFrameHelper.sendMessage('set-user', window.$chatwoot.user);
      }

      window.playAudioAlert = () => {};

      initOnEvents.forEach(e => {
        document.addEventListener(e, IFrameHelper.setupAudioListeners, false);
      });

      if (!window.$chatwoot.resetTriggered) {
        console.log('Dispatching CHATWOOT_READY event...');
        dispatchWindowEvent({ eventName: CHATWOOT_READY });
      }
    },
    error: ({ errorType, data }) => {
      console.error('Widget error:', { errorType, data });
      dispatchWindowEvent({ eventName: CHATWOOT_ERROR, data: data });

      if (errorType === SET_USER_ERROR) {
        console.log('Removing user cookie due to error.');
        Cookies.remove(getUserCookieName());
      }
    },
    onEvent({ eventIdentifier: eventName, data }) {
      console.log('Custom event triggered:', { eventName, data });
      dispatchWindowEvent({ eventName, data });
    },
    setBubbleLabel(message) {
      console.log('Setting bubble label:', message);
      setBubbleText(window.$chatwoot.launcherTitle || message.label);
    },
    setAuthCookie({ data: { widgetAuthToken } }) {
      console.log('Setting auth cookie with token:', widgetAuthToken);
      updateAuthCookie(widgetAuthToken, window.$chatwoot.baseDomain);
    },
    setCampaignReadOn() {
      console.log('Setting campaign read status.');
      updateCampaignReadStatus(window.$chatwoot.baseDomain);
    },
    toggleBubble: state => {
      console.log('Toggling bubble state:', state);
      let bubbleState = {};
      if (state === 'open') {
        bubbleState.toggleValue = true;
      } else if (state === 'close') {
        bubbleState.toggleValue = false;
      }

      onBubbleClick(bubbleState);
    },
    popoutChatWindow: ({ baseUrl, websiteToken, locale }) => {
      console.log('Popping out chat window:', {
        baseUrl,
        websiteToken,
        locale,
      });
      const cwCookie = Cookies.get('cw_conversation');
      window.$chatwoot.toggle('close');
      popoutChatWindow(baseUrl, websiteToken, locale, cwCookie);
    },
    closeWindow: () => {
      console.log('Closing chat window.');
      onBubbleClick({ toggleValue: false });
      removeUnreadClass();
    },
    onBubbleToggle: isOpen => {
      console.log('Bubble toggle event:', isOpen);
      IFrameHelper.sendMessage('toggle-open', { isOpen });
      if (isOpen) {
        IFrameHelper.pushEvent('webwidget.triggered');
      }
    },
    onLocationChange: ({ referrerURL, referrerHost }) => {
      console.log('Location change detected:', { referrerURL, referrerHost });
      IFrameHelper.sendMessage('change-url', {
        referrerURL,
        referrerHost,
      });
    },
    updateIframeHeight: message => {
      console.log('Updating iframe height:', message);
      const { extraHeight = 0, isFixedHeight } = message;

      IFrameHelper.setFrameHeightToFitContent(extraHeight, isFixedHeight);
    },
    setUnreadMode: () => {
      console.log('Setting unread mode.');
      addUnreadClass();
      onBubbleClick({ toggleValue: true });
    },
    resetUnreadMode: () => {
      console.log('Resetting unread mode.');
      removeUnreadClass();
    },
    handleNotificationDot: event => {
      console.log('Handling notification dot:', event);
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
      console.log('Closing chat.');
      onBubbleClick({ toggleValue: false });
    },
    playAudio: () => {
      console.log('Playing audio alert.');
      window.playAudioAlert();
    },
  },
  pushEvent: eventName => {
    console.log('Pushing event:', eventName);
    IFrameHelper.sendMessage('push-event', { eventName });
  },
  onLoad: ({ widgetColor }) => {
    console.log('On load with widget color:', widgetColor);
    const iframe = IFrameHelper.getAppFrame();
    iframe.style.visibility = '';
    iframe.setAttribute('id', `chatwoot_live_chat_widget`);

    if (IFrameHelper.getBubbleHolder().length) {
      console.log('Bubble holder already exists.');
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
    });

    addClasses(closeBubble, closeBtnClassName);

    chatIcon.style.background = widgetColor;
    closeBubble.style.background = widgetColor;

    bubbleHolder.appendChild(chatIcon);
    bubbleHolder.appendChild(closeBubble);
    onClickChatBubble();
  },
  toggleCloseButton: () => {
    const isMobile = window.matchMedia('(max-width: 668px)').matches;
    console.log('Toggling close button for mobile:', isMobile);
    IFrameHelper.sendMessage('toggle-close-button', { isMobile });
  },
};
