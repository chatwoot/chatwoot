export const TRANSLATION_PROVIDERS = {
  CAPTAIN: 'captain',
  GOOGLE: 'google_translate',
};

export const translationProvider = settings =>
  settings?.translation_provider || TRANSLATION_PROVIDERS.CAPTAIN;
