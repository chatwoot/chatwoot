import { useAssetUrl } from 'shared/composables/useAssetUrl';

export const showBadgeOnFavicon = () => {
  const assetUrl = useAssetUrl();
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    favicon.href = assetUrl(`/favicon-badge-${favicon.sizes[[0]]}.png`);
  });
};

export const initFaviconSwitcher = () => {
  const assetUrl = useAssetUrl();
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        favicon.href = assetUrl(`/favicon-${favicon.sizes[[0]]}.png`);
      });
    }
  });
};
