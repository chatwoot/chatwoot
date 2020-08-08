import { SDK_CSS } from './sdk.js';

export const loadCSS = () => {
  const css = document.createElement('style');
  css.type = 'text/css';
  css.innerHTML = `${SDK_CSS}`;
  document.body.appendChild(css);
};

export const wootOn = (elm, event, fn) => {
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
};

export const classHelper = (classes, action, elm) => {
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
};

export const addClass = (elm, classes) => {
  if (classes) {
    elm.className += ` ${classes}`;
  }
};

export const toggleClass = (elm, classes) => {
  classHelper(classes, 'toggle', elm);
};

export const removeClass = (elm, classes) => {
  classHelper(classes, 'remove', elm);
};
