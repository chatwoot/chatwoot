// On small screens sdk.css opens the widget full screen (`max-width: 667px`),
// sized to the layout viewport. The on-screen keyboard only shrinks the visual
// viewport, so the browser pans the page to the input and the messages end up
// above the visible area. While the widget is open full screen, the holder is
// sized to the visual viewport instead.
//
// At exactly 667px the `min-width: 667px` desktop rules win in sdk.css, so the
// query stops just short of it.
const FULL_SCREEN_MEDIA_QUERY = '(max-width: 666.98px)';
const UNREAD_VIEW_CLASS = 'has-unread-view';

let onViewportChange = null;

export const getHolderStyleForViewport = ({ height, offsetTop }) => ({
  height: `${height}px`,
  top: `${offsetTop}px`,
});

const clearHolderStyle = holder => {
  holder.style.removeProperty('height');
  holder.style.removeProperty('top');
};

export const fitHolderToViewport = holder => {
  const { visualViewport } = window;
  if (!visualViewport) return;

  const isFullScreen =
    window.$chatwoot.isOpen &&
    !holder.classList.contains(UNREAD_VIEW_CLASS) &&
    window.matchMedia(FULL_SCREEN_MEDIA_QUERY).matches;

  if (isFullScreen) {
    Object.assign(holder.style, getHolderStyleForViewport(visualViewport));
  } else {
    clearHolderStyle(holder);
  }
};

export const startFittingHolderToViewport = holder => {
  const { visualViewport } = window;
  if (!visualViewport || onViewportChange) return;

  onViewportChange = () => fitHolderToViewport(holder);
  visualViewport.addEventListener('resize', onViewportChange);
  visualViewport.addEventListener('scroll', onViewportChange);
  onViewportChange();
};

export const stopFittingHolderToViewport = holder => {
  if (!onViewportChange) return;

  window.visualViewport.removeEventListener('resize', onViewportChange);
  window.visualViewport.removeEventListener('scroll', onViewportChange);
  onViewportChange = null;
  clearHolderStyle(holder);
};
