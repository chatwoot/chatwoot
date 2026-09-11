export const stripConversationToken = (search = '') => {
  const params = new URLSearchParams(search);
  params.delete('cw_conversation');
  const qs = params.toString();
  return qs ? `?${qs}` : '';
};

export const buildSearchParamsWithLocale = search => {
  // [TODO] for now this works, but we will need to find a way to get the locale from the root component
  const locale = window.WOOT_WIDGET.$root.$i18n.locale;
  const params = new URLSearchParams(search);
  params.delete('cw_conversation');
  params.append('locale', locale);

  return `?${params}`;
};

export const getLocale = (search = '') => {
  return new URLSearchParams(search).get('locale');
};

export const buildPopoutURL = ({ origin, websiteToken, locale }) => {
  const popoutUrl = new URL('/widget', origin);
  popoutUrl.searchParams.append('website_token', websiteToken);
  popoutUrl.searchParams.append('locale', locale);

  return popoutUrl.toString();
};
