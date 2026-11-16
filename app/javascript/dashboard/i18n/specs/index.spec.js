import languagesConfig from '../../../../../config/initializers/languages.rb?raw';
import messages from '../index';

const localeFiles = import.meta.glob('../locale/*/*.json', {
  eager: true,
  import: 'default',
});

describe('dashboard i18n', () => {
  it('bundles exactly the locales enabled in the backend', () => {
    const enabledLocales = Array.from(
      languagesConfig.matchAll(/iso_639_1_code: '([^']+)', enabled: true/g),
      match => match[1]
    );

    expect(Object.keys(messages).sort()).toEqual(enabledLocales.sort());
  });

  it('merges every file of a bundled locale without overwriting a key', () => {
    Object.entries(localeFiles).forEach(([path, translations]) => {
      const locale = path.split('/')[2];
      if (!messages[locale]) return;

      Object.entries(translations).forEach(([key, value]) => {
        expect(messages[locale][key], `${path} ${key}`).toEqual(value);
      });
    });
  });
});
