const {
  LOGO_THUMBNAIL: logoThumbnail,
  LOGO: logo,
  INSTALLATION_NAME: installationName,
  WIDGET_BRAND_URL: widgetBrandURL,
  TERMS_URL: termsURL,
  PRIVACY_URL: privacyURL,
} = window.globalConfig;

const state = {
  logoThumbnail,
  logo,
  installationName,
  widgetBrandURL,
  termsURL,
  privacyURL,
};

export const getters = {
  get: $state => $state,
};

export const actions = {};

export const mutations = {};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
