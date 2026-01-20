import { parseBoolean } from '@chatwoot/utils';
import { resolveMaximumFileUploadSize } from 'shared/helpers/FileHelper';

const {
  API_CHANNEL_NAME: apiChannelName,
  API_CHANNEL_THUMBNAIL: apiChannelThumbnail,
  APP_VERSION: appVersion,
  AZURE_APP_ID: azureAppId,
  BRAND_NAME: brandName,
  CHATWOOT_INBOX_TOKEN: chatwootInboxToken,
  CREATE_NEW_ACCOUNT_FROM_DASHBOARD: createNewAccountFromDashboard,
  DIRECT_UPLOADS_ENABLED: directUploadsEnabled,
  DISPLAY_MANIFEST: displayManifest,
  GIT_SHA: gitSha,
  MAXIMUM_FILE_UPLOAD_SIZE: maximumFileUploadSize,
  HCAPTCHA_SITE_KEY: hCaptchaSiteKey,
  INSTALLATION_NAME: installationName,
  LOGO_THUMBNAIL: logoThumbnail,
  LOGO: logo,
  LOGO_DARK: logoDark,
  PRIVACY_URL: privacyURL,
  IS_ENTERPRISE: isEnterprise,
  TERMS_URL: termsURL,
  WIDGET_BRAND_URL: widgetBrandURL,
  DISABLE_USER_PROFILE_UPDATE: disableUserProfileUpdate,
  DEPLOYMENT_ENV: deploymentEnv,
} = window.globalConfig || {};

const state = {
  apiChannelName,
  apiChannelThumbnail,
  appVersion,
  azureAppId,
  brandName,
  chatwootInboxToken,
  deploymentEnv,
  createNewAccountFromDashboard,
  directUploadsEnabled: parseBoolean(directUploadsEnabled),
  disableUserProfileUpdate: parseBoolean(disableUserProfileUpdate),
  displayManifest,
  gitSha,
  maximumFileUploadSize: resolveMaximumFileUploadSize(maximumFileUploadSize),
  hCaptchaSiteKey,
  installationName,
  logo,
  logoDark,
  logoThumbnail,
  privacyURL,
  termsURL,
  widgetBrandURL,
  isEnterprise: parseBoolean(isEnterprise),
};

export const getters = {
  get: $state => $state,
  isOnChatwootCloud: $state => $state.deploymentEnv === 'cloud',
  isACustomBrandedInstance: $state => $state.installationName !== 'Chatwoot',
  isAChatwootInstance: $state => $state.installationName === 'Chatwoot',
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
