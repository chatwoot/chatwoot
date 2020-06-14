import Cookies from 'js-cookie';
import { wootOn, loadCSS } from './DOMHelpers';
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
} from './bubbleHelpers';

export const IFrameHelper = {
  getUrl({ baseUrl, websiteToken, shareLink }) {
    let url = `${baseUrl}/widget?website_token=${websiteToken}`;

    return IFrameHelper.addParameters(url, shareLink);
  },
  addParameters(url, shareLink) {
    const cwGroupCookie = IFrameHelper.getCwGroupCookie();
    const cwCookie = Cookies.get('cw_conversation');

    if (cwGroupCookie) {
      url = `${url}&cw_group_conversation=${cwGroupCookie}`;
    }

    if (shareLink) {
      const isOwnChat = cwCookie === shareLink;
      const param = isOwnChat ? '&cw_conversation=' : '&chatwoot_share_link=';

      url = `${url}${param}${shareLink}`;
    } else if (cwCookie) {
      url = `${url}&cw_conversation=${cwCookie}`;
    }

    return url;
  },
  createFrame: ({ baseUrl, websiteToken, shareLink }) => {
    const iframe = document.createElement('iframe');
    const widgetUrl = IFrameHelper.getUrl({ baseUrl, websiteToken, shareLink });

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
    IFrameHelper.preventDefaultScroll();
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
      if (message.config.shareLink) {
        let group_cookie = IFrameHelper.getCwGroupCookie();
        if (!group_cookie) {
          let shareLink = IFrameHelper.getShareLink();
          let value = message.config.participantToken;
          let key = 'cw_group_conversation' + shareLink.slice(-10);
          Cookies.set(key, value, {
            expires: 365,
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
    if (shareLink) {
      shareLink = shareLink.slice(-10);
    }
    let target_cookie;

    /* eslint-disable guard-for-in */
    // eslint-disable-next-line no-restricted-syntax
    for (const cookie in cookies) {
      let cookie_token = cookie.split('cw_group_conversation')[1];
      if (cookie_token === shareLink) {
        target_cookie = Cookies.get(cookie);
        break;
      }
    }
    /* eslint-enable guard-for-in */

    return target_cookie;
  },
};
