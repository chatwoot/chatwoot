export const buildSearchParamsWithLocale = search => {
  const locale = window.WOOT_WIDGET.$root.$i18n.locale;
  if (search) {
    search = `${search}&locale=${locale}`;
  } else {
    search = `?locale=${locale}`;
  }
  return search;
};

export const getLocale = (search = '') => {
  const searchParamKeyValuePairs = search.split('&');
  return searchParamKeyValuePairs.reduce((acc, keyValuePair) => {
    const [key, value] = keyValuePair.split('=');
    if (key === 'locale') {
      return value;
    }
    return acc;
  }, undefined);
};

export const buildPopoutURL = ({
  origin,
  conversationCookie,
  websiteToken,
  locale,
}) => {
  return `${origin}/widget?cw_conversation=${conversationCookie}&website_token=${websiteToken}&locale=${locale}`;
};
