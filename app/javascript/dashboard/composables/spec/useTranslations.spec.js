import { selectTranslation } from '../useTranslations';

describe('selectTranslation', () => {
  it('returns null when translations is null', () => {
    expect(selectTranslation(null, 'en', 'en')).toBeNull();
  });

  it('returns null when translations is empty', () => {
    expect(selectTranslation({}, 'en', 'en')).toBeNull();
  });

  it('returns first translation when no locale matches', () => {
    const translations = { en: 'Hello', es: 'Hola' };
    expect(selectTranslation(translations, 'fr', 'de')).toBe('Hello');
  });

  it('returns translation matching agent locale', () => {
    const translations = { en: 'Hello', es: 'Hola', zh_CN: '你好' };
    expect(selectTranslation(translations, 'es', 'en')).toBe('Hola');
  });

  it('falls back to account locale when agent locale not found', () => {
    const translations = { en: 'Hello', zh_CN: '你好' };
    expect(selectTranslation(translations, 'fr', 'zh_CN')).toBe('你好');
  });

  it('returns first translation when both locales are undefined', () => {
    const translations = { en: 'Hello', es: 'Hola' };
    expect(selectTranslation(translations, undefined, undefined)).toBe('Hello');
  });
});
