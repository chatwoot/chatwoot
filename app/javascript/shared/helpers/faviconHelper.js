export const showBadgeOnFavicon = () => {
  const icon = document.querySelectorAll('.favicon');

  icon.forEach(favicon => {
    const newFileName = `/favicon-badge-${favicon.sizes[[0]]}.png`;
    favicon.href = newFileName;
  });
};

export const initFaviconSwitcher = () => {
  const originalHref = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      originalHref.forEach(favicon => {
        const oldFileName = `/favicon-${favicon.sizes[[0]]}.png`;
        favicon.href = oldFileName;
      });
    }
  });
};
