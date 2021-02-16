const {
  APP_VERSION: appVersion,
  BRAND_NAME: brandName,
  CHATWOOT_INBOX_TOKEN: chatwootInboxToken,
  CREATE_NEW_ACCOUNT_FROM_DASHBOARD: createNewAccountFromDashboard,
  DISPLAY_MANIFEST: displayManifest,
  INSTALLATION_NAME: installationName,
  LOGO_THUMBNAIL: logoThumbnail,
  LOGO: logo,
  PRIVACY_URL: privacyURL,
  TERMS_URL: termsURL,
  WIDGET_BRAND_URL: widgetBrandURL,
} = window.globalConfig;

const state = {
  appVersion,
  brandName,
  chatwootInboxToken,
  createNewAccountFromDashboard,
  displayManifest,
  installationName,
  logo,
  logoThumbnail,
  privacyURL,
  termsURL,
  widgetBrandURL,
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
