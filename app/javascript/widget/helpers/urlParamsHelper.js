import { i18n } from '../../packs/widget';

export const buildSearchParamsWithLocale = search => {
  const locale = i18n.locale;
  if (search) {
    search = `${search}&locale=${locale}`;
  } else {
    search = `?locale=${locale}`;
  }
  return search;
};
