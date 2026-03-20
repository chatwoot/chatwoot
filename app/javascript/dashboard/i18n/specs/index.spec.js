import { createI18n } from 'vue-i18n';
import messages, {
  LOCALE_MODULES,
  SUPPORTED_DASHBOARD_LOCALES,
} from '../index';

const localeFiles = import.meta.glob('../locale/*/*.json', {
  eager: true,
  import: 'default',
});

const sortStrings = values =>
  [...values].sort((left, right) => left.localeCompare(right));

const FALLBACK_KEY = 'HELP_CENTER.PORTAL.DRAFT_LOCALE.API.SUCCESS_MESSAGE';

const flattenLeafTranslations = (value, prefix = '', out = new Map()) => {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    Object.entries(value).forEach(([key, child]) => {
      flattenLeafTranslations(child, prefix ? `${prefix}.${key}` : key, out);
    });
    return out;
  }

  out.set(prefix, value);
  return out;
};

describe('dashboard i18n', () => {
  it('keeps the english module allowlist in sync with locale files', () => {
    const englishModules = Object.keys(localeFiles)
      .filter(filePath => filePath.startsWith('../locale/en/'))
      .map(filePath => filePath.match(/^\.\.\/locale\/en\/([^/]+)\.json$/)?.[1])
      .filter(Boolean);

    expect(sortStrings(englishModules)).toEqual(sortStrings(LOCALE_MODULES));
  });

  it('exposes a message object for every supported locale', () => {
    expect(sortStrings(Object.keys(messages))).toEqual(
      sortStrings(SUPPORTED_DASHBOARD_LOCALES)
    );

    SUPPORTED_DASHBOARD_LOCALES.forEach(locale => {
      expect(messages[locale]).toEqual(expect.any(Object));
    });
  });

  it('keeps the locale allowlist in sync with locale folders on disk', () => {
    const localeFolders = new Set(
      Object.keys(localeFiles)
        .map(filePath => filePath.match(/^\.\.\/locale\/([^/]+)\//)?.[1])
        .filter(Boolean)
    );

    expect(sortStrings([...localeFolders])).toEqual(
      sortStrings(SUPPORTED_DASHBOARD_LOCALES)
    );
  });

  it('loads every allowed locale file that exists on disk', () => {
    const allowedLocales = new Set(SUPPORTED_DASHBOARD_LOCALES);
    const allowedModules = new Set(LOCALE_MODULES);

    Object.entries(localeFiles).forEach(([filePath, translations]) => {
      const match = filePath.match(/^\.\.\/locale\/([^/]+)\/([^/]+)\.json$/);

      if (!match) {
        return;
      }

      const [, locale, moduleName] = match;

      if (!allowedLocales.has(locale) || !allowedModules.has(moduleName)) {
        return;
      }

      Object.entries(translations).forEach(([key, value]) => {
        expect(messages[locale][key]).toEqual(value);
      });
    });
  });

  it('does not define duplicate top-level keys across split locale files', () => {
    const allowedLocales = new Set(SUPPORTED_DASHBOARD_LOCALES);
    const allowedModules = new Set(LOCALE_MODULES);
    const seenKeys = new Map();
    const duplicates = [];

    Object.entries(localeFiles).forEach(([filePath, translations]) => {
      const match = filePath.match(/^\.\.\/locale\/([^/]+)\/([^/]+)\.json$/);

      if (!match) {
        return;
      }

      const [, locale, moduleName] = match;

      if (!allowedLocales.has(locale) || !allowedModules.has(moduleName)) {
        return;
      }

      const localeKeys = seenKeys.get(locale) || new Map();

      Object.keys(translations).forEach(key => {
        const existingModule = localeKeys.get(key);

        if (existingModule) {
          duplicates.push({
            locale,
            key,
            modules: [existingModule, moduleName],
          });
          return;
        }

        localeKeys.set(key, moduleName);
      });

      seenKeys.set(locale, localeKeys);
    });

    expect(duplicates).toEqual([]);
  });

  it('falls back to english for missing keys in real locale data', () => {
    const englishLeaves = flattenLeafTranslations(messages.en);
    const fallbackLocales = SUPPORTED_DASHBOARD_LOCALES.filter(
      locale => locale !== 'en'
    ).filter(
      locale => !flattenLeafTranslations(messages[locale]).has(FALLBACK_KEY)
    );

    expect(fallbackLocales.length).toBeGreaterThan(0);
    expect(englishLeaves.get(FALLBACK_KEY)).toBeDefined();

    fallbackLocales.forEach(locale => {
      const i18n = createI18n({
        legacy: false,
        locale,
        fallbackLocale: 'en',
        missingWarn: false,
        fallbackWarn: false,
        messages,
      });

      expect(
        i18n.global.t('HELP_CENTER.PORTAL.DRAFT_LOCALE.API.SUCCESS_MESSAGE')
      ).toBe(englishLeaves.get(FALLBACK_KEY));
    });
  });
});
