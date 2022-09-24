export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    favicon.href = `/favicon-badge-${favicon.sizes[[0]]}.png`;
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        favicon.href = `/favicon-${favicon.sizes[[0]]}.png`;
      });
    }
  });
};
