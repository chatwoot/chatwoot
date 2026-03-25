// Keep bundled dashboard locales explicit so adding a language stays deliberate.
export const SUPPORTED_DASHBOARD_LOCALES = Object.freeze([
  'am',
  'ar',
  'az',
  'bg',
  'bn',
  'ca',
  'cs',
  'da',
  'de',
  'el',
  'en',
  'es',
  'et',
  'fa',
  'fi',
  'fr',
  'he',
  'hi',
  'hr',
  'hu',
  'hy',
  'id',
  'is',
  'it',
  'ja',
  'ka',
  'ko',
  'lt',
  'lv',
  'ml',
  'ms',
  'ne',
  'nl',
  'no',
  'pl',
  'pt',
  'pt_BR',
  'ro',
  'ru',
  'sh',
  'sk',
  'sl',
  'sq',
  'sr',
  'sv',
  'ta',
  'th',
  'tl',
  'tr',
  'uk',
  'ur',
  'ur_IN',
  'vi',
  'zh',
  'zh_CN',
  'zh_TW',
]);

export const LOCALE_MODULES = Object.freeze([
  'advancedFilters',
  'agentBots',
  'agentMgmt',
  'attributesMgmt',
  'auditLogs',
  'automation',
  'bulkActions',
  'campaign',
  'cannedMgmt',
  'chatlist',
  'companies',
  'components',
  'contact',
  'contactFilters',
  'contentTemplates',
  'conversation',
  'csatMgmt',
  'customRole',
  'datePicker',
  'emoji',
  'general',
  'generalSettings',
  'helpCenter',
  'inbox',
  'inboxMgmt',
  'integrationApps',
  'integrations',
  'labelsMgmt',
  'login',
  'macros',
  'mfa',
  'report',
  'resetPassword',
  'search',
  'setNewPassword',
  'settings',
  'signup',
  'sla',
  'snooze',
  'teamsSettings',
  'webhooks',
  'whatsappTemplates',
  'yearInReview',
]);

const localeFiles = import.meta.glob('./locale/*/*.json', {
  eager: true,
  import: 'default',
});

const allowedLocales = new Set(SUPPORTED_DASHBOARD_LOCALES);
const allowedModules = new Set(LOCALE_MODULES);

const messages = Object.fromEntries(
  SUPPORTED_DASHBOARD_LOCALES.map(locale => [locale, {}])
);

Object.entries(localeFiles)
  // Keep merges deterministic if two files ever define the same top-level key.
  .sort(([leftPath], [rightPath]) => leftPath.localeCompare(rightPath))
  .forEach(([filePath, translations]) => {
    const match = filePath.match(/^\.\/locale\/([^/]+)\/([^/]+)\.json$/);

    if (!match) {
      return;
    }

    const [, locale, moduleName] = match;

    if (!allowedLocales.has(locale) || !allowedModules.has(moduleName)) {
      return;
    }

    Object.assign(messages[locale], translations);
  });

export default messages;
