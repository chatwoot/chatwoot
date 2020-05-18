import Cookies from 'js-cookie';
import { wootOn, loadCSS } from './DOMHelpers';
import {
  body,
  widgetHolder,
  createBubbleHolder,
  disableScroll,
  enableScroll,
  createBubbleIcon,
  bubbleImg,
  chatBubble,
  closeBubble,
  bubbleHolder,
  createNotificationBubble,
  onClickChatBubble,
  onBubbleClick,
} from './bubbleHelpers';

export const IFrameHelper = {
  getUrl({ baseUrl, websiteToken }) {
    return `${baseUrl}/widget?website_token=${websiteToken}`;
  },
  createFrame: ({ baseUrl, websiteToken, shareLink }) => {
    const iframe = document.createElement('iframe');
    const cwGroupCookie = IFrameHelper.getCwGroupCookie();
    const cwCookie = Cookies.get('cw_conversation');
    let widgetUrl = IFrameHelper.getUrl({ baseUrl, websiteToken });
    if (cwGroupCookie) {
      widgetUrl = `${widgetUrl}&cw_group_conversation=${cwGroupCookie}`;
    } else if (shareLink) {
      widgetUrl = `${widgetUrl}&chatwoot_share_link=${shareLink}`;
    } else if (cwCookie) {
      widgetUrl = `${widgetUrl}&cw_conversation=${cwCookie}`;
    }
    iframe.src = widgetUrl;

    iframe.id = 'chatwoot_live_chat_widget';
    iframe.style.visibility = 'hidden';
    widgetHolder.className = `woot-widget-holder ${IFrameHelper.wootHide()} woot-elements--${
      window.$chatwoot.position
    }`;
    widgetHolder.appendChild(iframe);
    body.appendChild(widgetHolder);
    IFrameHelper.initPostMessageCommunication();
    IFrameHelper.initLocationListener();
    IFrameHelper.initWindowSizeListener();
  },
  getAppFrame: () => document.getElementById('chatwoot_live_chat_widget'),
  sendMessage: (key, value) => {
    const element = IFrameHelper.getAppFrame();
    element.contentWindow.postMessage(
      `chatwoot-widget:${JSON.stringify({ event: key, ...value })}`,
      '*'
    );
  },
  initLocationListener: () => {
    window.onhashchange = () => {
      IFrameHelper.setCurrentUrl();
    };
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
    wootOn(window, 'resize', () => {
      IFrameHelper.toggleCloseButton();
    });
  },
  events: {
    loaded: message => {
      if (message.config.shareLink) {
        let group_cookie = IFrameHelper.getCwGroupCookie();
        if (!group_cookie) {
          let value = message.config.authToken;
          let key = 'cw_group_conversation' + Date.now();
          Cookies.set(key, value, {
            expires: 365,
            conversation: IFrameHelper.getShareLink(),
          });
        }
      } else {
        Cookies.set('cw_conversation', message.config.authToken, {
          expires: 365,
        });
      }
      window.$chatwoot.hasLoaded = true;
      IFrameHelper.sendMessage('config-set', {
        locale: window.$chatwoot.locale,
      });
      IFrameHelper.onLoad(message.config.channelConfig);
      IFrameHelper.setCurrentUrl();
      IFrameHelper.toggleCloseButton();

      if (window.$chatwoot.user) {
        IFrameHelper.sendMessage('set-user', window.$chatwoot.user);
      }
    },

    toggleBubble: () => {
      onBubbleClick();
    },
  },
  pushEvent: eventName => {
    IFrameHelper.sendMessage('push-event', { eventName });
  },
  onLoad: ({ widgetColor }) => {
    const iframe = IFrameHelper.getAppFrame();
    iframe.style.visibility = '';
    iframe.setAttribute('id', `chatwoot_live_chat_widget`);
    iframe.onmouseenter = disableScroll;
    iframe.onmouseleave = enableScroll;

    loadCSS();
    createBubbleHolder();

    if (!window.$chatwoot.hideMessageBubble) {
      const chatIcon = createBubbleIcon({
        className: `woot-widget-bubble ${IFrameHelper.wootShow()}`,
        src: bubbleImg,
        target: chatBubble,
      });

      const closeIcon = closeBubble;
      closeIcon.className = `woot-elements--${window.$chatwoot.position}
      woot-widget-bubble woot--close ${IFrameHelper.wootHide()}`;
      chatIcon.style.background = widgetColor;
      closeIcon.style.background = widgetColor;

      bubbleHolder.appendChild(chatIcon);
      bubbleHolder.appendChild(closeIcon);
      bubbleHolder.appendChild(createNotificationBubble());
      onClickChatBubble();
    }
  },
  setCurrentUrl: () => {
    IFrameHelper.sendMessage('set-current-url', {
      refererURL: window.location.href,
    });
  },
  toggleCloseButton: () => {
    if (window.matchMedia('(max-width: 668px)').matches) {
      IFrameHelper.sendMessage('toggle-close-button', { showClose: true });
    } else {
      IFrameHelper.sendMessage('toggle-close-button', { showClose: false });
    }
  },
  wootHide: () => {
    return window.$chatwoot.isOpen ? '' : 'woot--hide';
  },
  wootShow: () => {
    return window.$chatwoot.isOpen ? 'woot--hide' : '';
  },
  getShareLink: () => {
    let url = new URL(window.document.location);
    return url.searchParams.get('chatwoot_share_link');
  },
  getCwGroupCookie: () => {
    let cookies = Cookies.get();
    let shareLink = IFrameHelper.getShareLink();
    let target_cookie;

    // eslint-disable-next-line no-restricted-syntax
    for (const cookie in cookies) {
      if (cookies[cookie] === shareLink) {
        target_cookie = Cookies.get(cookie);
        break;
      }
    }

    return target_cookie;
  },
};
