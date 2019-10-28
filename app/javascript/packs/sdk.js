const body = document.getElementsByTagName('body')[0];
const iframe = document.createElement('iframe');
const holder = document.createElement('div');

const bubbleHolder = document.createElement('div');
const chatBubble = document.createElement('div');
const closeBubble = document.createElement('div');

const notification_bubble = document.createElement('span');
const bodyOverFlowStyle = document.body.style.overflow;

function addClass(elm, classes) {
  if (classes) {
    // eslint-disable-next-line
    elm.className += ` ${classes}`;
  }
}

function loadCSS() {
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
    'background: #1f93ff;' +
    'position: fixed;' +
    'cursor: pointer;' +
    'right: 20px;' +
    'bottom: 20px;' +
    'width: 64px!important;' +
    'height: 64px!important; }' +
    '.woot-widget-bubble:hover { ' +
    'background: #1f93ff;' +
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

// Toggle class
function toggleClass(elm, classes) {
  classHelper(classes, 'toggle', elm);
}

function createChatBubble() {
  chatBubble.className = 'woot-widget-bubble';
  const icon_bubble = document.createElement('img');
  icon_bubble.src =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Am1AAAAUVBMVEUAAAD///////////////////////////////////////////////////////////////////////////////////////////////////////8IN+deAAAAGnRSTlMAAwgJEBk0TVheY2R5eo+ut8jb5OXs8fX2+cjRDTIAAADsSURBVHgBldZbkoMgFIThRgQv8SKKgGf/C51UnJqaRI30/9zfe+NQUQ3TvG7bOk9DVeCmshmj/CuOTYnrdBfkUOg0zlOtl9OWVuEk4+QyZ3DIevmSt/ioTvK1VH/s5bY3YdM9SBZ/mUUyWgx+U06ycgp7D8msxSvtc4HXL9BLdj2elSEfhBJAI0QNgJEBI1BEBsQClVBVGDgwYOLAhJkDM1YOrNg4sLFAsLJgZsHEgoEFFQt0JAFGFjQsKAMJ0LFAexKgZYFyJIDxJIBNJEDNAtSJBLCeBDCOBFAPzwFA94ED+zmhwDO9358r8ANtIsMXi7qVAwAAAABJRU5ErkJggg==';
  chatBubble.appendChild(icon_bubble);
  return chatBubble;
}

function createCloseBubble() {
  closeBubble.className = 'woot-widget-bubble woot--close woot--hide';
  const icon_bubble = document.createElement('img');
  icon_bubble.src =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAP1BMVEUAAAD///////////////////////////////////////////////////////////////////////////////9Du/pqAAAAFHRSTlMACBstLi8wMVB+mcbT2err7O3w8n+sjtQAAAEuSURBVHgBtNLdcoMgGITh1SCGH9DId//X2mnTg7hYxj0oh8w8r+MqgDnmlsIE6UwhtRxnAHge9n2KV7wvP+h4AvPbm73W+359/aJjRjQTCuTNIrJJBfKW0UwqkLeGZJ8Ff2O/T28JwZQCewuYilJgX6buavdDv188br1RIE+jc2H5yy+9VwrXXij0nsflwth7YFRw7N3Y88BcYL+z7wubO/lt6AcFwQMLF9irP8r2eF8/ei8VLrxUkDzguMDejX03WK3dsGJB9lxgrxd0T8PTRxUL5OUCealQz76KXg/or/CvI36VXgcEAAAgCMP6t16IZVDg3zPuI+0rb5g2zlsoW2lbqlvrOyw7bTuuO+8LGIs4C1mLeQuai7oL2437LRytPC1drX0tnq2+Ld+r/wDPIIIJkfdlbQAAAABJRU5ErkJggg==';
  closeBubble.appendChild(icon_bubble);
  return closeBubble;
}

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
  wootOn(chatBubble, 'click', bubbleClickCallback);
  wootOn(closeBubble, 'click', bubbleClickCallback);
}

function disableScroll() {
  document.body.style.overflow = 'hidden';
}

function enableScroll() {
  document.body.style.overflow = bodyOverFlowStyle;
}

function loadCallback() {
  iframe.style.display = 'block';
  iframe.setAttribute('id', `chatwoot_live_chat_widget`);
  iframe.onmouseenter = disableScroll;
  iframe.onmouseleave = enableScroll;

  loadCSS();
  createBubbleHolder();

  bubbleHolder.appendChild(createChatBubble());
  bubbleHolder.appendChild(createCloseBubble());
  bubbleHolder.appendChild(createNotificationBubble());

  onClickChatBubble();
}

function loadIframe({ websiteToken }) {
  iframe.style.display = 'none';
  iframe.src = `/widgets?website_token=${websiteToken}`;
  iframe.onload = loadCallback;

  holder.className = 'woot-widget-holder woot--hide';
  holder.appendChild(iframe);

  body.appendChild(holder);
}

window.chatwootSDK = {
  run: loadIframe,
};
