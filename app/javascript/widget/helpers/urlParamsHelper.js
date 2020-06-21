import i18n from '../i18n';

export const buildSearchParamsWithLocale = search => {
  const locale = i18n.locale;
  if (search) {
    search = `${search}&locale=${locale}`;
  } else {
    search = `?locale=${locale}`;
  }
  return search;
};
