import Cookies from 'js-cookie';
import {
  wootOn,
  addClass,
  loadCSS,
  removeClass,
  onLocationChangeListener,
} from './DOMHelpers';
import {
  body,
  widgetHolder,
  createBubbleHolder,
  createBubbleIcon,
  bubbleImg,
  chatBubble,
  closeBubble,
  bubbleHolder,
  createNotificationBubble,
  onClickChatBubble,
  onBubbleClick,
  setBubbleText,
} from './bubbleHelpers';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';

const EVENT_NAME = 'chatwoot:ready';

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

    iframe.id = 'chatwoot_live_chat_widget';
    iframe.style.visibility = 'hidden';

    let holderClassName = `woot-widget-holder woot--hide woot-elements--${window.$chatwoot.position}`;
    if (window.$chatwoot.hideMessageBubble) {
      holderClassName += ` woot-widget--without-bubble`;
    }
    addClass(widgetHolder, holderClassName);
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
    wootOn(window, 'resize', () => IFrameHelper.toggleCloseButton());
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
  events: {
    loaded: message => {
      Cookies.set('cw_conversation', message.config.authToken, {
        expires: 365,
        sameSite: 'Lax',
      });
      window.$chatwoot.hasLoaded = true;
      IFrameHelper.sendMessage('config-set', {
        locale: window.$chatwoot.locale,
        position: window.$chatwoot.position,
        hideMessageBubble: window.$chatwoot.hideMessageBubble,
        showPopoutButton: window.$chatwoot.showPopoutButton,
      });
      IFrameHelper.onLoad({
        widgetColor: message.config.channelConfig.widgetColor,
      });
      IFrameHelper.toggleCloseButton();

      if (window.$chatwoot.user) {
        IFrameHelper.sendMessage('set-user', window.$chatwoot.user);
      }
      dispatchWindowEvent(EVENT_NAME);
    },

    setBubbleLabel(message) {
      if (window.$chatwoot.hideMessageBubble) {
        return;
      }
      setBubbleText(window.$chatwoot.launcherTitle || message.label);
    },

    toggleBubble: () => {
      onBubbleClick();
    },

    onBubbleToggle: isOpen => {
      if (!isOpen) {
        IFrameHelper.events.resetUnreadMode();
      } else {
        IFrameHelper.pushEvent('webwidget.triggered');
      }
    },
    onLocationChange: ({ referrerURL, referrerHost }) => {
      IFrameHelper.sendMessage('change-url', {
        referrerURL,
        referrerHost,
      });
    },

    setUnreadMode: message => {
      const { unreadMessageCount } = message;
      const { isOpen } = window.$chatwoot;
      const toggleValue = true;

      if (!isOpen && unreadMessageCount > 0) {
        IFrameHelper.sendMessage('set-unread-view');
        onBubbleClick({ toggleValue });
        const holderEl = document.querySelector('.woot-widget-holder');
        addClass(holderEl, 'has-unread-view');
      }
    },

    setCampaignMode: () => {
      const { isOpen } = window.$chatwoot;
      const toggleValue = true;
      if (!isOpen) {
        onBubbleClick({ toggleValue });
        const holderEl = document.querySelector('.woot-widget-holder');
        addClass(holderEl, 'has-unread-view');
      }
    },

    resetUnreadMode: () => {
      IFrameHelper.sendMessage('unset-unread-view');
      IFrameHelper.events.removeUnreadClass();
    },

    removeUnreadClass: () => {
      const holderEl = document.querySelector('.woot-widget-holder');
      removeClass(holderEl, 'has-unread-view');
    },

    updateIframeHeight: message => {
      setTimeout(() => {
        const iframe = IFrameHelper.getAppFrame();
        const scrollableMessageHeight =
          iframe.contentWindow.document.querySelector('.unread-messages')
            .scrollHeight + 40;
        const updatedIframeHeight = message.isFixedHeight
          ? `${scrollableMessageHeight}px`
          : '100%';
        iframe.setAttribute(
          'style',
          `height: ${updatedIframeHeight} !important`
        );
      }, 100);
    },
  },
  pushEvent: eventName => {
    IFrameHelper.sendMessage('push-event', { eventName });
  },

  onLoad: ({ widgetColor }) => {
    const iframe = IFrameHelper.getAppFrame();
    iframe.style.visibility = '';
    iframe.setAttribute('id', `chatwoot_live_chat_widget`);

    if (IFrameHelper.getBubbleHolder().length) {
      return;
    }
    createBubbleHolder();
    onLocationChangeListener();
    if (!window.$chatwoot.hideMessageBubble) {
      const chatIcon = createBubbleIcon({
        className: 'woot-widget-bubble',
        src: bubbleImg,
        target: chatBubble,
      });

      const closeIcon = closeBubble;
      const closeIconclassName = `woot-elements--${window.$chatwoot.position} woot-widget-bubble woot--close woot--hide`;
      addClass(closeIcon, closeIconclassName);

      chatIcon.style.background = widgetColor;
      closeIcon.style.background = widgetColor;

      bubbleHolder.appendChild(chatIcon);
      bubbleHolder.appendChild(closeIcon);
      bubbleHolder.appendChild(createNotificationBubble());
      onClickChatBubble();
    }
  },
  toggleCloseButton: () => {
    if (window.matchMedia('(max-width: 668px)').matches) {
      IFrameHelper.sendMessage('toggle-close-button', {
        showClose: true,
      });
    } else {
      IFrameHelper.sendMessage('toggle-close-button', {
        showClose: false,
      });
    }
  },
};
