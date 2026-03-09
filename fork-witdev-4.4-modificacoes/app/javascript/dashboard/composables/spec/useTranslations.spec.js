import { ref } from 'vue';
import { useTranslations } from '../useTranslations';

describe('useTranslations', () => {
  it('returns false and null when contentAttributes is null', () => {
    const contentAttributes = ref(null);
    const { hasTranslations, translationContent } =
      useTranslations(contentAttributes);
    expect(hasTranslations.value).toBe(false);
    expect(translationContent.value).toBeNull();
  });

  it('returns false and null when translations are missing', () => {
    const contentAttributes = ref({});
    const { hasTranslations, translationContent } =
      useTranslations(contentAttributes);
    expect(hasTranslations.value).toBe(false);
    expect(translationContent.value).toBeNull();
  });

  it('returns false and null when translations is an empty object', () => {
    const contentAttributes = ref({ translations: {} });
    const { hasTranslations, translationContent } =
      useTranslations(contentAttributes);
    expect(hasTranslations.value).toBe(false);
    expect(translationContent.value).toBeNull();
  });

  it('returns true and correct translation content when translations exist', () => {
    const contentAttributes = ref({
      translations: { en: 'Hello' },
    });
    const { hasTranslations, translationContent } =
      useTranslations(contentAttributes);
    expect(hasTranslations.value).toBe(true);
    // Should return the first translation (en: 'Hello')
    expect(translationContent.value).toBe('Hello');
  });
});
