export const TRANSLATION_PROVIDERS = {
  CAPTAIN: 'captain',
  GOOGLE: 'google_translate',
};

// Accounts that connected Google Translate before the setting existed keep using it.
export const translationProvider = (settings, googleConnected) =>
  settings?.translation_provider ||
  (googleConnected
    ? TRANSLATION_PROVIDERS.GOOGLE
    : TRANSLATION_PROVIDERS.CAPTAIN);
