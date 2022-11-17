export const navigateToLocalePage = () => {
  const allLocaleSwitcher = document.querySelector('.locale-switcher');

  if (!allLocaleSwitcher) {
    return false;
  }

  const { portalSlug } = allLocaleSwitcher.dataset;
  allLocaleSwitcher.addEventListener('change', event => {
    window.location = `/hc/${portalSlug}/${event.target.value}/`;
  });
  return false;
};
