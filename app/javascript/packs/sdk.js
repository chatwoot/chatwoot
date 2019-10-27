/* eslint-disable */
const hostName = window.location.origin;
const _id = `${hostName}_account_id`;
const _inbox = `${hostName}_inbox_id`;
const _conversation = `${hostName}_last_conversation`;
const _user = `${hostName}_user_id`;
const _channel = `${hostName}_channel_id`;

const body = document.getElementsByTagName('body')[0];

const iframe = document.createElement('iframe');
const holder = document.createElement('div');

const bubble_holder = document.createElement('div');
const bubble_chat = document.createElement('div');
const bubble_close = document.createElement('div');

const notification_bubble = document.createElement('span');
const bodyOverFlowStyle = document.body.style.overflow;

const wootCookie = {
  write(name, value, days, domain, path) {
    const date = new Date();
    days = days || 730; // two years
    path = path || '/';
    date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
    const expires = `; expires=${date.toGMTString()}`;
    let cookieValue = `${name}=${value}${expires}; path=${path}`;
    !!domain && (cookieValue += `; domain=${domain}`);
    document.cookie = cookieValue;
  },
  read(name) {
    const allCookie = `${document.cookie}`;
    const index = allCookie.indexOf(name);
    if (name === undefined || name === '' || index === -1) return '';
    let ind1 = allCookie.indexOf(';', index);
    if (ind1 == -1) ind1 = allCookie.length;
    return unescape(allCookie.substring(index + name.length + 1, ind1));
  },
  remove(name) {
    if (this.read(name)) {
      this.write(name, '', -1, '/');
    }
  },
};

function createChatBubble() {
  bubble_chat.className = 'woot-widget-bubble';
  const icon_bubble = document.createElement('img');
  icon_bubble.src =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Am1AAAAUVBMVEUAAAD///////////////////////////////////////////////////////////////////////////////////////////////////////8IN+deAAAAGnRSTlMAAwgJEBk0TVheY2R5eo+ut8jb5OXs8fX2+cjRDTIAAADsSURBVHgBldZbkoMgFIThRgQv8SKKgGf/C51UnJqaRI30/9zfe+NQUQ3TvG7bOk9DVeCmshmj/CuOTYnrdBfkUOg0zlOtl9OWVuEk4+QyZ3DIevmSt/ioTvK1VH/s5bY3YdM9SBZ/mUUyWgx+U06ycgp7D8msxSvtc4HXL9BLdj2elSEfhBJAI0QNgJEBI1BEBsQClVBVGDgwYOLAhJkDM1YOrNg4sLFAsLJgZsHEgoEFFQt0JAFGFjQsKAMJ0LFAexKgZYFyJIDxJIBNJEDNAtSJBLCeBDCOBFAPzwFA94ED+zmhwDO9358r8ANtIsMXi7qVAwAAAABJRU5ErkJggg==';
  bubble_chat.appendChild(icon_bubble);
  return bubble_chat;
}

function createCloseBubble() {
  bubble_close.className = 'woot-widget-bubble woot--close woot--hide';
  const icon_bubble = document.createElement('img');
  icon_bubble.src =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAP1BMVEUAAAD///////////////////////////////////////////////////////////////////////////////9Du/pqAAAAFHRSTlMACBstLi8wMVB+mcbT2err7O3w8n+sjtQAAAEuSURBVHgBtNLdcoMgGITh1SCGH9DId//X2mnTg7hYxj0oh8w8r+MqgDnmlsIE6UwhtRxnAHge9n2KV7wvP+h4AvPbm73W+359/aJjRjQTCuTNIrJJBfKW0UwqkLeGZJ8Ff2O/T28JwZQCewuYilJgX6buavdDv188br1RIE+jc2H5yy+9VwrXXij0nsflwth7YFRw7N3Y88BcYL+z7wubO/lt6AcFwQMLF9irP8r2eF8/ei8VLrxUkDzguMDejX03WK3dsGJB9lxgrxd0T8PTRxUL5OUCealQz76KXg/or/CvI36VXgcEAAAgCMP6t16IZVDg3zPuI+0rb5g2zlsoW2lbqlvrOyw7bTuuO+8LGIs4C1mLeQuai7oL2437LRytPC1drX0tnq2+Ld+r/wDPIIIJkfdlbQAAAABJRU5ErkJggg==';
  bubble_close.appendChild(icon_bubble);
  return bubble_close;
}

function createBubbleHolder() {
  addClass(bubble_holder, 'woot--bubble-holder');
  body.appendChild(bubble_holder);
}

function createNotificationBubble() {
  addClass(notification_bubble, 'woot--notification');
  return notification_bubble;
}

function chat_bubble_click(argument) {
  woot_on(bubble_chat, 'click', bubbleClickCallback);
  woot_on(bubble_close, 'click', bubbleClickCallback);
}

// function toggleClass(classes) {
//   classHelper(classes, 'toggle', nodes);
//   return cb;
// }

function bubbleClickCallback() {
  toggleClass(bubble_chat, 'woot--hide');
  toggleClass(bubble_close, 'woot--hide');
  toggleClass(holder, 'woot--hide');
}

function disable_scroll() {
  document.body.style.overflow = 'hidden';
}

function enable_scroll() {
  document.body.style.overflow = bodyOverFlowStyle;
}

function createWootCookies() {
  if (!wootCookie.read(_id)) {
    wootCookie.write(_id, WOOT_ACCOUNT_ID);
    wootCookie.write(_inbox, WOOT_INBOX_ID);
  }
}

function createContactCookies(data) {
  if (!wootCookie.read(_id)) {
    wootCookie.write(_user, data);
  }
}

function sendContactDataToIframe() {
  const iframeEl = document.getElementById(_id);
  const data = {
    accountId: WOOT_ACCOUNT_ID,
    inboxId: WOOT_INBOX_ID,
    lastConversation: wootCookie.read(_conversation),
    contact: wootCookie.read(_user),
  };
  const message = {
    event: 'initIframe',
    data,
  };
  iframeEl.contentWindow.postMessage(JSON.stringify(message), '*');
  console.log(' Iframe message sent');
}

function loadCallback() {
  iframe.style.display = 'block';
  iframe.setAttribute('id', _id);
  // iframe.setAttribute('src', 'javascript:;');
  iframe.onmouseenter = disable_scroll;
  iframe.onmouseleave = enable_scroll;

  load_css();
  createBubbleHolder();

  bubble_holder.appendChild(createChatBubble());
  bubble_holder.appendChild(createCloseBubble());
  bubble_holder.appendChild(createNotificationBubble());

  chat_bubble_click();
  sendContactDataToIframe();
}

function loadIframe({ websiteToken }) {
  iframe.style.display = 'none';
  iframe.src = `/widgets?website_token=${websiteToken}`;

  iframe.onreadystatechange = function() {
    if (iframe.readyState !== 'complete') {
    }
  };
  iframe.onload = loadCallback;

  holder.className = 'woot-widget-holder woot--hide';
  holder.appendChild(iframe);

  body.appendChild(holder);
}

function load_css() {
  const css = document.createElement('style');
  css.type = 'text/css';
  css.innerHTML =
    '.woot-widget-holder { z-index: 2147483000!important;' +
    'position: fixed!important;' +
    'bottom: 104px;' +
    'right: 20px;' +
    'height: calc(85% - 64px - 20px);' +
    'width: 370px!important;' +
    'min-height: 250px!important;' +
    'max-height: 590px!important;' +
    '-moz-box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;' +
    '-o-box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;' +
    '-webkit-box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;' +
    'box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;' +
    '-o-border-radius: 8px!important;' +
    '-moz-border-radius: 8px!important;' +
    '-webkit-border-radius: 8px!important;' +
    'border-radius: 8px!important;' +
    'overflow: hidden!important;' +
    'opacity: 1!important; }' +
    '.woot-widget-holder iframe { width: 100% !important; height: 100% !important; border: 0; }' +
    '.woot-widget-bubble { ' +
    'z-index: 2147483000!important;' +
    '-moz-box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;' +
    '-o-box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;' +
    '-webkit-box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;' +
    'box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;' +
    '-o-border-radius: 100px!important;' +
    '-moz-border-radius: 100px!important;' +
    '-webkit-border-radius: 100px!important;' +
    'border-radius: 100px!important;' +
    'background: #005BEA;' +
    'position: fixed;' +
    'cursor: pointer;' +
    'right: 20px;' +
    'bottom: 20px;' +
    'width: 64px!important;' +
    'height: 64px!important; }' +
    '.woot-widget-bubble:hover { ' +
    'background: #297cff;' +
    '-moz-box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;' +
    '-o-box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;' +
    '-webkit-box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;' +
    'box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;' +
    ' }' +
    '.woot-widget-bubble img { ' +
    'width: 24px;' +
    'height: 24px;' +
    'margin: 20px;' +
    ' }' +
    '.woot-widget-bubble.woot--close img { ' +
    'width: 16px;' +
    'height: 16px;' +
    'margin: 24px; }' +
    '.woot--hide {' +
    'display: none !important;' +
    ' }';
  document.body.appendChild(css);
}

function woot_on(elm, event, fn) {
  if (document.addEventListener) {
    elm.addEventListener(event, fn, false);
  } else if (document.attachEvent) {
    // <= IE 8 loses scope so need to apply, we add this to object so we can detach later (can't detach anonymous functions)
    elm[event + fn] = function() {
      return fn.apply(elm, arguments);
    };
    elm.attachEvent(`on${event}`, elm[event + fn]);
  }
}

function classHelper(classes, action, elm) {
  let classarray;
  let search;
  let replace;
  let i;
  let has = false;
  if (classes) {
    // Trim any whitespace
    classarray = classes.split(/\s+/);
    for (i = 0; i < classarray.length; i += 1) {
      search = new RegExp(`\\b${classarray[i]}\\b`, 'g');
      replace = new RegExp(` *${classarray[i]}\\b`, 'g');
      if (action === 'remove') {
        elm.className = elm.className.replace(replace, '');
      } else if (action === 'toggle') {
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
// Remove class
function removeClass(elm, classes) {
  classHelper(classes, 'remove', elm);
}
// Toggle class
function toggleClass(elm, classes) {
  classHelper(classes, 'toggle', elm);
}

// createWootCookies();

window.chatwootSDK = {
  run: loadIframe,
};

window.addEventListener(
  'message',
  function(event) {
    if (
      event.origin.indexOf('http://localhost:8080') !== -1 &&
      typeof event.data === 'string'
    ) {
      if (event.data.includes('setContact')) {
        const { data } = JSON.parse(event.data);
        wootCookie.write(_user, JSON.stringify(data));
      } else if (event.data.includes('setLastConversation')) {
        const { data } = JSON.parse(event.data);
        const lastConversation = data || '';
        wootCookie.write(_conversation, lastConversation);
      }
    }
  },
  false
);
