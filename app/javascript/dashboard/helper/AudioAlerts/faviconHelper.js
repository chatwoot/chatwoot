export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    // Sử dụng mooly-icon.png cho tất cả các kích thước
    favicon.href = '/mooly-icon.png';
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        // Sử dụng mooly-icon.png cho tất cả các kích thước
        favicon.href = '/mooly-icon.png';
      });
    }
  });
};
