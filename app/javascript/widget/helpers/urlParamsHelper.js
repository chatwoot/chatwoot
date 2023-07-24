export const buildSearchParamsWithLocale = search => {
  const locale = window.WOOT_WIDGET.$root.$i18n.locale;
  const params = new URLSearchParams(search);
  params.append('locale', locale);

  return `?${params}`;
};

export const getLocale = (search = '') => {
  return new URLSearchParams(search).get('locale');
};

export const buildPopoutURL = ({
  origin,
  conversationCookie,
  websiteToken,
  locale,
}) => {
  const popoutUrl = new URL('/widget', origin);
  popoutUrl.searchParams.append('cw_conversation', conversationCookie);
  popoutUrl.searchParams.append('website_token', websiteToken);
  popoutUrl.searchParams.append('locale', locale);

  return popoutUrl.toString();
};
