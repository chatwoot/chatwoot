import {
  showDotOnFavicon,
  clearDotOnFavicon,
} from 'dashboard/helper/unreadBadgeHelper';

let isFaviconSwitcherInitialized = false;

export const showBadgeOnFavicon = () => {
  // The unread badge helper owns the favicon. When there is an unread count it
  // already renders a numbered badge, so the plain dot is only a fallback for
  // alerts that don't create a notification record.
  showDotOnFavicon();
};

export const initFaviconSwitcher = () => {
  // `set` on the audio helper runs on every profile update, the listener should
  // still be registered only once.
  if (isFaviconSwitcherInitialized) return;
  isFaviconSwitcherInitialized = true;

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      clearDotOnFavicon();
    }
  });
};
