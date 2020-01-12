import Cookies from 'js-cookie';

import { SDK_CSS } from '../widget/assets/scss/sdk';
/* eslint-disable no-param-reassign */
const bubbleImg =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Am1AAAAUVBMVEUAAAD///////////////////////////////////////////////////////////////////////////////////////////////////////8IN+deAAAAGnRSTlMAAwgJEBk0TVheY2R5eo+ut8jb5OXs8fX2+cjRDTIAAADsSURBVHgBldZbkoMgFIThRgQv8SKKgGf/C51UnJqaRI30/9zfe+NQUQ3TvG7bOk9DVeCmshmj/CuOTYnrdBfkUOg0zlOtl9OWVuEk4+QyZ3DIevmSt/ioTvK1VH/s5bY3YdM9SBZ/mUUyWgx+U06ycgp7D8msxSvtc4HXL9BLdj2elSEfhBJAI0QNgJEBI1BEBsQClVBVGDgwYOLAhJkDM1YOrNg4sLFAsLJgZsHEgoEFFQt0JAFGFjQsKAMJ0LFAexKgZYFyJIDxJIBNJEDNAtSJBLCeBDCOBFAPzwFA94ED+zmhwDO9358r8ANtIsMXi7qVAwAAAABJRU5ErkJggg==';

const body = document.getElementsByTagName('body')[0];
const holder = document.createElement('div');

const bubbleHolder = document.createElement('div');
const chatBubble = document.createElement('div');
const closeBubble = document.createElement('div');

const notification_bubble = document.createElement('span');
const bodyOverFlowStyle = document.body.style.overflow;

function loadCSS() {
  const css = document.createElement('style');
  css.type = 'text/css';
  css.innerHTML = `${SDK_CSS}`;
  document.body.appendChild(css);
}

function wootOn(elm, event, fn) {
  if (document.addEventListener) {
    elm.addEventListener(event, fn, false);
  } else if (document.attachEvent) {
    // <= IE 8 loses scope so need to apply, we add this to object so we
    // can detach later (can't detach anonymous functions)
    // eslint-disable-next-line
    elm[event + fn] = function() {
      // eslint-disable-next-line
      return fn.apply(elm, arguments);
    };
    elm.attachEvent(`on${event}`, elm[event + fn]);
  }
}

function classHelper(classes, action, elm) {
  let search;
  let replace;
  let i;
  let has = false;
  if (classes) {
    // Trim any whitespace
    const classarray = classes.split(/\s+/);
    for (i = 0; i < classarray.length; i += 1) {
      search = new RegExp(`\\b${classarray[i]}\\b`, 'g');
      replace = new RegExp(` *${classarray[i]}\\b`, 'g');
      if (action === 'remove') {
        // eslint-disable-next-line
        elm.className = elm.className.replace(replace, '');
      } else if (action === 'toggle') {
        // eslint-disable-next-line
        elm.className = elm.className.match(search)
          ? elm.className.replace(replace, '')
          : `${elm.className} ${classarray[i]}`;
      } else if (action === 'has') {
        if (elm.className.match(search)) {
          has = true;
          break;
        }
      }
    }
  }
  return has;
}

function addClass(elm, classes) {
  if (classes) {
    elm.className += ` ${classes}`;
  }
}

// Toggle class
function toggleClass(elm, classes) {
  classHelper(classes, 'toggle', elm);
}

const createBubbleIcon = ({ className, src, target }) => {
  target.className = className;
  const bubbleIcon = document.createElement('img');
  bubbleIcon.src = src;
  target.appendChild(bubbleIcon);
  return target;
};

function createBubbleHolder() {
  addClass(bubbleHolder, 'woot--bubble-holder');
  body.appendChild(bubbleHolder);
}

function createNotificationBubble() {
  addClass(notification_bubble, 'woot--notification');
  return notification_bubble;
}

function bubbleClickCallback() {
  toggleClass(chatBubble, 'woot--hide');
  toggleClass(closeBubble, 'woot--hide');
  toggleClass(holder, 'woot--hide');
}

function onClickChatBubble() {
  wootOn(bubbleHolder, 'click', bubbleClickCallback);
}

function disableScroll() {
  document.body.style.overflow = 'hidden';
}

function enableScroll() {
  document.body.style.overflow = bodyOverFlowStyle;
}

const IFrameHelper = {
  createFrame: ({ baseUrl, websiteToken }) => {
    const iframe = document.createElement('iframe');
    const cwCookie = Cookies.get('cw_conversation');
    let widgetUrl = `${baseUrl}/widget?website_token=${websiteToken}`;
    if (cwCookie) {
      widgetUrl = `${widgetUrl}&cw_conversation=${cwCookie}`;
    }
    iframe.src = widgetUrl;

    iframe.id = 'chatwoot_live_chat_widget';
    iframe.style.visibility = 'hidden';
    holder.className = 'woot-widget-holder woot--hide';
    holder.appendChild(iframe);
    body.appendChild(holder);
    IFrameHelper.initPostMessageCommunication();
    IFrameHelper.initLocationListener();
  },
  getAppFrame: () => document.getElementById('chatwoot_live_chat_widget'),
  sendMessage: (key, value) => {
    const element = IFrameHelper.getAppFrame();
    element.contentWindow.postMessage(
      `chatwoot-widget:${JSON.stringify({ event: key, ...value })}`,
      '*'
    );
  },
  initPostMessageCommunication: () => {
    const events = {
      loaded: message => {
        Cookies.set('cw_conversation', message.config.authToken);
        IFrameHelper.sendMessage('config-set', {});
        IFrameHelper.onLoad(message.config.channelConfig);
        IFrameHelper.setCurrentUrl();
      },
      set_auth_token: message => {
        Cookies.set('cw_conversation', message.authToken);
      },
    };

    window.onmessage = e => {
      if (
        typeof e.data !== 'string' ||
        e.data.indexOf('chatwoot-widget:') !== 0
      ) {
        return;
      }
      const message = JSON.parse(e.data.replace('chatwoot-widget:', ''));
      if (typeof events[message.event] === 'function') {
        events[message.event](message);
      }
    };
  },
  initLocationListener: () => {
    window.onhashchange = () => {
      IFrameHelper.setCurrentUrl();
    };
  },
  onLoad: ({ widget_color: widgetColor }) => {
    const iframe = IFrameHelper.getAppFrame();
    iframe.style.visibility = '';
    iframe.setAttribute('id', `chatwoot_live_chat_widget`);
    iframe.onmouseenter = disableScroll;
    iframe.onmouseleave = enableScroll;

    loadCSS();
    createBubbleHolder();

    const chatIcon = createBubbleIcon({
      className: 'woot-widget-bubble',
      src: bubbleImg,
      target: chatBubble,
    });

    const closeIcon = closeBubble;
    closeIcon.className = 'woot-widget-bubble woot--close woot--hide';

    chatIcon.style.background = widgetColor;
    closeIcon.style.background = widgetColor;

    bubbleHolder.appendChild(chatIcon);
    bubbleHolder.appendChild(closeIcon);
    bubbleHolder.appendChild(createNotificationBubble());
    onClickChatBubble();
  },
  setCurrentUrl: () => {
    IFrameHelper.sendMessage('set-current-url', {
      refererURL: window.location.href,
    });
  },
};

function loadIframe({ baseUrl, websiteToken }) {
  IFrameHelper.createFrame({
    baseUrl,
    websiteToken,
  });
}

window.chatwootSDK = {
  run: loadIframe,
};
