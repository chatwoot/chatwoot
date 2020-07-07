import Vue from 'vue';
export const buildSearchParamsWithLocale = search => {
  const locale = Vue.config.lang;
  if (search) {
    search = `${search}&locale=${locale}`;
  } else {
    search = `?locale=${locale}`;
  }
  return search;
};
