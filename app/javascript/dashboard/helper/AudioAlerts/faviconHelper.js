const resolveFaviconSize = favicon => {
  const size = favicon?.sizes?.[0];
  if (!size || size === 'any') {
    return '32x32';
  }
  return size;
};

export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    const size = resolveFaviconSize(favicon);
    const newFileName = `/favicon-badge-${size}.png`;
    favicon.href = newFileName;
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        const size = resolveFaviconSize(favicon);
        const oldFileName = `/favicon-${size}.png`;
        favicon.href = oldFileName;
      });
    }
  });
};
