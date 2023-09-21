import { SDK_CSS } from './sdk.js';
import { IFrameHelper } from './IFrameHelper';

export const loadCSS = () => {
  const css = document.createElement('style');
  css.innerHTML = `${SDK_CSS}`;
  document.body.appendChild(css);
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
