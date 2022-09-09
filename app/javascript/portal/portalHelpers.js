export const navigateToLocalePage = () => {
  const allLocaleSwitcher = document.querySelector('.locale-switcher');

  const { portalSlug } = allLocaleSwitcher.dataset;
  allLocaleSwitcher.addEventListener('change', event => {
    window.location = `/public/api/v1/portals/${portalSlug}/${event.target.value}/dashboard`;
  });
};
