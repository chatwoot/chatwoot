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
