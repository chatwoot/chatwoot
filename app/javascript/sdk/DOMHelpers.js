import SDK_CSS from './sdk.css?inline';
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

export const PAGE_TITLE_MAX_LENGTH = 256;
export const TAB_ID_MAX_LENGTH = 64;
const TAB_ID_STORAGE_KEY = 'chatwoot-widget-tab-id';

const normalizePageURL = value => {
  if (typeof value !== 'string') return null;

  try {
    const pageURL = new URL(value);
    if (!['http:', 'https:'].includes(pageURL.protocol)) return null;
    if (pageURL.username || pageURL.password) return null;

    pageURL.search = '';
    pageURL.hash = '';
    return pageURL.toString();
  } catch (error) {
    return null;
  }
};

const getTabId = () => {
  let tabId;
  try {
    tabId = window.sessionStorage.getItem(TAB_ID_STORAGE_KEY);
  } catch (error) {
    // Storage can be unavailable for privacy-restricted documents.
  }

  if (!tabId) {
    const randomId =
      typeof window.crypto?.randomUUID === 'function'
        ? window.crypto.randomUUID()
        : `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
    tabId = randomId.slice(0, TAB_ID_MAX_LENGTH);
    try {
      window.sessionStorage.setItem(TAB_ID_STORAGE_KEY, tabId);
    } catch (error) {
      // Storage can be unavailable for privacy-restricted documents.
    }
  }

  return String(tabId).slice(0, TAB_ID_MAX_LENGTH);
};

const normalizeSequence = sequence =>
  Number.isSafeInteger(sequence) && sequence >= 0 ? sequence : 0;

export const normalizePageContext = pageContext => {
  if (!pageContext || typeof pageContext !== 'object') return null;

  const url = normalizePageURL(pageContext.url);
  if (!url) return null;

  const rawTabId = pageContext.tabId ?? pageContext.tab_id;
  const tabId =
    typeof rawTabId === 'string' ? rawTabId.slice(0, TAB_ID_MAX_LENGTH) : '';
  const title = String(pageContext.title || '').slice(0, PAGE_TITLE_MAX_LENGTH);

  return {
    url,
    title,
    tabId,
    sequence: normalizeSequence(pageContext.sequence),
  };
};

export const getPageContext = ({ tabId = getTabId(), sequence = 0 } = {}) =>
  normalizePageContext({
    url: document.location.href,
    title: document.title,
    tabId,
    sequence,
  });

const haveSamePageContext = (first, second) =>
  first?.url === second?.url &&
  first?.title === second?.title &&
  first?.tabId === second?.tabId;

export const onLocationChange = ({
  referrerURL,
  referrerHost,
  pageContext,
} = {}) => {
  const locationChange = { referrerURL, referrerHost };
  if (pageContext) locationChange.pageContext = pageContext;
  IFrameHelper.events.onLocationChange(locationChange);
};

export const onLocationChangeListener = () => {
  let oldHref = document.location.href;
  const referrerHost = document.location.host;
  const tabId = getTabId();
  let sequence = 0;
  let previousPageContext;

  const emitLocationChange = ({ initial = false } = {}) => {
    const referrerURL = document.location.href;
    let pageContext = getPageContext({ tabId, sequence });
    const pageContextChanged = !haveSamePageContext(
      previousPageContext,
      pageContext
    );

    if (pageContextChanged && previousPageContext) {
      sequence = Math.min(
        previousPageContext.sequence + 1,
        Number.MAX_SAFE_INTEGER
      );
      pageContext = getPageContext({ tabId, sequence });
    }

    const urlChanged = oldHref !== referrerURL;
    if (!initial && !urlChanged && !pageContextChanged) return;

    oldHref = referrerURL;
    if (pageContextChanged) previousPageContext = pageContext;
    onLocationChange({
      referrerURL,
      referrerHost,
      pageContext: pageContextChanged ? pageContext : undefined,
    });
  };

  emitLocationChange({ initial: true });

  ['pushState', 'replaceState'].forEach(method => {
    const originalMethod = window.history?.[method];
    if (typeof originalMethod !== 'function') return;

    window.history[method] = (...args) => {
      const result = originalMethod.apply(window.history, args);
      emitLocationChange();
      return result;
    };
  });

  window.addEventListener('popstate', emitLocationChange);
  window.addEventListener('hashchange', emitLocationChange);

  const config = {
    childList: true,
    subtree: true,
    characterData: true,
  };
  const observerTarget = document.documentElement || document.body;
  if (!observerTarget) return;

  const observer = new MutationObserver(() => emitLocationChange());
  observer.observe(observerTarget, config);
};
