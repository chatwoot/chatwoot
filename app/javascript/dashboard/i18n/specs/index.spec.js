import { createI18n } from 'vue-i18n';
import languagesConfig from '../../../../../config/initializers/languages.rb?raw';
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

const FALLBACK_KEY = 'AUDIT_LOGS.LIST.TABLE_HEADER.LOCATION';

describe('dashboard i18n', () => {
  it('bundles exactly the dashboard locales enabled by the backend', () => {
    const enabledLocales = Array.from(
      languagesConfig.matchAll(/iso_639_1_code: '([^']+)', enabled: true/g),
      match => match[1]
    );

    expect(sortStrings(SUPPORTED_DASHBOARD_LOCALES)).toEqual(
      sortStrings(enabledLocales)
    );
  });

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

  it('has translation files for every enabled dashboard locale', () => {
    const localeFolders = new Set(
      Object.keys(localeFiles)
        .map(filePath => filePath.match(/^\.\.\/locale\/([^/]+)\//)?.[1])
        .filter(Boolean)
    );

    SUPPORTED_DASHBOARD_LOCALES.forEach(locale => {
      expect(localeFolders.has(locale)).toBe(true);
    });
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

  it('falls back to english for a missing key in a loaded locale', () => {
    const portugueseMessages = structuredClone(messages.pt_BR);
    delete portugueseMessages.AUDIT_LOGS.LIST.TABLE_HEADER.LOCATION;

    const i18n = createI18n({
      legacy: false,
      locale: 'pt_BR',
      fallbackLocale: 'en',
      missingWarn: false,
      fallbackWarn: false,
      messages: { en: messages.en, pt_BR: portugueseMessages },
    });

    expect(i18n.global.t(FALLBACK_KEY)).toBe(
      messages.en.AUDIT_LOGS.LIST.TABLE_HEADER.LOCATION
    );
  });

  it('falls back to english for a missing locale module', () => {
    const portugueseMessages = { ...messages.pt_BR };
    delete portugueseMessages.AUDIT_LOGS;

    const i18n = createI18n({
      legacy: false,
      locale: 'pt_BR',
      fallbackLocale: 'en',
      missingWarn: false,
      fallbackWarn: false,
      messages: { en: messages.en, pt_BR: portugueseMessages },
    });

    expect(i18n.global.t(FALLBACK_KEY)).toBe(
      messages.en.AUDIT_LOGS.LIST.TABLE_HEADER.LOCATION
    );
  });
});
