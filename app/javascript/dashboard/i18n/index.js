// Keep this list aligned with enabled languages in config/initializers/languages.rb.
export const SUPPORTED_DASHBOARD_LOCALES = Object.freeze([
  'ar',
  'bg',
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
  'hu',
  'id',
  'is',
  'it',
  'ja',
  'ko',
  'lt',
  'lv',
  'ml',
  'nl',
  'no',
  'pl',
  'pt',
  'pt_BR',
  'ro',
  'ru',
  'sk',
  'sl',
  'sr',
  'sv',
  'ta',
  'th',
  'tr',
  'uk',
  'uz',
  'vi',
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
  'calls',
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
  'onboarding',
  'report',
  'resetPassword',
  'search',
  'sessionLimit',
  'setNewPassword',
  'settings',
  'signup',
  'sla',
  'snooze',
  'teamsSettings',
  'webhooks',
  'whatsappTemplateMgmt',
  'whatsappTemplates',
  'yearInReview',
]);

const localeFiles = import.meta.glob(
  [
    './locale/{ar,bg,ca,cs,da,de,el,en,es,et}/*.json',
    './locale/{fa,fi,fr,he,hu,id,is,it,ja,ko}/*.json',
    './locale/{lt,lv,ml,nl,no,pl,pt,pt_BR,ro,ru}/*.json',
    './locale/{sk,sl,sr,sv,ta,th,tr,uk,uz,vi}/*.json',
    './locale/{zh_CN,zh_TW}/*.json',
  ],
  { eager: true, import: 'default' }
);

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

    if (!allowedModules.has(moduleName)) {
      return;
    }

    Object.assign(messages[locale], translations);
  });

export default messages;
