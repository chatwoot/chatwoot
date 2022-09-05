export const navigateToLocalePage = () => {
  const allLocaleSwitcher = document.querySelector('.locale-switcher');
  const { portalSlug } = allLocaleSwitcher.dataset;
  allLocaleSwitcher.onchange = event => {
    window.location = `/public/api/v1/portals/${portalSlug}/${event.target.value}/dashboard`;
  };
};
