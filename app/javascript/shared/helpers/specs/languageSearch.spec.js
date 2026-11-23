import { languageOption, matchesOptionSearch } from '../languageSearch';
import helpCenterLocales from 'shared/constants/locales';
import csatLanguages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

describe('language search aliases', () => {
  it('keeps the original display label and locale without trimming or canonicalizing either', () => {
    const option = languageOption(' Nederlands (nl) ', 'nl');

    expect(option.label).toBe(' Nederlands (nl) ');
    expect(option.value).toBe('nl');
    expect(matchesOptionSearch(option, 'dutch')).toBe(true);
  });

  it('does not collapse regional variants into the base language', () => {
    const base = languageOption('Português (pt)', 'pt');
    const regional = languageOption('Português Brasileiro (pt-BR)', 'pt_BR');

    expect(regional.value).toBe('pt_BR');
    ['brazilian portuguese', 'pt_br', 'pt-br'].forEach(query => {
      expect(matchesOptionSearch(regional, query)).toBe(true);
      expect(matchesOptionSearch(base, query)).toBe(false);
    });
  });

  it('adds a native-language alias to the Help Center catalogue without altering its labels or values', () => {
    const option = languageOption(helpCenterLocales.ja, 'ja');

    expect(option).toMatchObject({ label: 'Japanese', value: 'ja' });
    expect(matchesOptionSearch(option, '日本語')).toBe(true);
    expect(matchesOptionSearch(option, 'japanese')).toBe(true);
    expect(matchesOptionSearch(option, 'ja')).toBe(true);
  });

  it('keeps the CSAT provider codes and leaves non-language options alone', () => {
    const japanese = csatLanguages.find(l => l.id === 'ja');
    const option = languageOption(japanese.name, japanese.id);

    expect(option.value).toBe('ja');
    expect(matchesOptionSearch(option, '日本語')).toBe(true);
    expect(
      matchesOptionSearch({ label: 'Use account default' }, 'default')
    ).toBe(true);
    expect(
      matchesOptionSearch({ label: 'Use account default' }, 'japanese')
    ).toBe(false);
  });

  it('leaves unknown provider codes discoverable without rejecting the catalogue', () => {
    const option = languageOption('Custom provider label', 'custom_locale_1');

    expect(option.value).toBe('custom_locale_1');
    expect(matchesOptionSearch(option, 'custom-locale-1')).toBe(true);
  });
});
