import { SDK_CSS } from './sdk.js';
import { IFrameHelper } from './IFrameHelper';

export const loadCSS = () => {
  const css = document.createElement('style');
  css.innerHTML = `${SDK_CSS}`;
  css.id = 'cw-widget-styles';
  css.dataset.turboPermanent = true;
  document.body.appendChild(css);
};

// This is a method specific to Turbo
// The body replacing strategy removes Chatwoot styles
// as well as the widget, this help us get it back
export const restoreElement = (id, newBody) => {
  const element = document.getElementById(id);
  const newElement = newBody.querySelector(`#${id}`);

  if (element && !newElement) {
    newBody.appendChild(element);
  }
};

export const restoreWidgetInDOM = newBody => {
  restoreElement('cw-bubble-holder', newBody);
  restoreElement('cw-widget-holder', newBody);
  restoreElement('cw-widget-styles', newBody);
};

export const addClasses = (elm, classes) => {
  elm.classList.add(...classes.split(' '));
};

export const toggleClass = (elm, classes) => {
  elm.classList.toggle(classes);
};

export const removeClasses = (elm, classes) => {
  elm.classList.remove(...classes.split(' '));
};

export const onLocationChange = ({ referrerURL, referrerHost }) => {
  IFrameHelper.events.onLocationChange({
    referrerURL,
    referrerHost,
  });
};

export const onLocationChangeListener = () => {
  let oldHref = document.location.href;
  const referrerHost = document.location.host;
  const config = {
    childList: true,
    subtree: true,
  };
  onLocationChange({
    referrerURL: oldHref,
    referrerHost,
  });

  const bodyList = document.querySelector('body');
  const observer = new MutationObserver(mutations => {
    mutations.forEach(() => {
      if (oldHref !== document.location.href) {
        oldHref = document.location.href;
        onLocationChange({
          referrerURL: oldHref,
          referrerHost,
        });
      }
    });
  });

  observer.observe(bodyList, config);
};
