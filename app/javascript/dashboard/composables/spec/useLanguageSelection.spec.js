import { ref } from 'vue';
import { useLanguageSelection } from '../useLanguageSelection';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

// Mock dependencies
vi.mock('dashboard/composables/useUISettings');
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(message => message),
}));
vi.mock('vue-i18n');

describe('useLanguageSelection', () => {
  const mockUISettings = ref({
    locale: 'en',
  });
  const mockUpdateUISettings = vi.fn().mockResolvedValue(undefined);
  const mockTranslate = vi.fn(key => key);
  const mockLocale = ref('en'); // Mocked locale
  const mockLanguages = [
    { name: 'English (en)', iso_639_1_code: 'en' },
    { name: 'Français (fr)', iso_639_1_code: 'fr' },
    { name: 'Español (es)', iso_639_1_code: 'es' },
  ];

  beforeEach(() => {
    vi.clearAllMocks();

    // Setup mocks
    useUISettings.mockReturnValue({
      uiSettings: mockUISettings,
      updateUISettings: mockUpdateUISettings,
    });

    useI18n.mockReturnValue({
      t: mockTranslate,
      locale: mockLocale,
    });

    mockUISettings.value.locale = 'en';
    mockLocale.value = 'en';
  });

  it('returns languageOptions with correct structure', () => {
    const { languageOptions } = useLanguageSelection(mockLanguages);
    expect(languageOptions.value).toHaveLength(4);
    expect(languageOptions.value[0]).toHaveProperty('iso_639_1_code');
    expect(languageOptions.value[0]).toHaveProperty('name');

    // Check specific options
    expect(
      languageOptions.value.find(option => option.iso_639_1_code === 'en')
    ).toEqual({
      name: 'English (en)',
      iso_639_1_code: 'en',
    });
    expect(
      languageOptions.value.find(option => option.iso_639_1_code === 'fr')
    ).toEqual({
      name: 'Français (fr)',
      iso_639_1_code: 'fr',
    });
  });

  it('returns currentLanguage from UI settings', () => {
    const { currentLanguage } = useLanguageSelection(mockLanguages);
    expect(currentLanguage.value).toBe('en');

    mockUISettings.value.locale = 'fr';
    expect(currentLanguage.value).toBe('fr');
  });

  it('updates language in UI settings and applies it to i18n instance', async () => {
    const { updateLanguage } = useLanguageSelection(mockLanguages);

    await updateLanguage('fr');

    // Verify that updateUISettings was called with the correct arguments
    expect(mockUpdateUISettings).toHaveBeenCalledWith({ locale: 'fr' });

    // Verify that the locale was updated
    expect(mockLocale.value).toBe('fr');

    // Verify that a success alert was shown
    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_SUCCESS'
    );
  });

  it('shows error alert when update fails', async () => {
    // Mock the updateUISettings function to reject with an error
    mockUpdateUISettings.mockRejectedValueOnce(new Error('Update failed'));

    const { updateLanguage } = useLanguageSelection(mockLanguages);

    // Expect the updateLanguage function to throw an error
    await expect(updateLanguage('fr')).rejects.toThrow('Update failed');

    // Verify that the error alert was shown
    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_ERROR'
    );

    // Verify that updateUISettings was called with the correct arguments
    expect(mockUpdateUISettings).toHaveBeenCalledWith({ locale: 'fr' });
  });

  it('handles invalid language codes gracefully', async () => {
    const { updateLanguage } = useLanguageSelection(mockLanguages);

    await expect(updateLanguage('invalid-code')).rejects.toThrow(
      'Invalid language code: invalid-code'
    );

    expect(mockUpdateUISettings).not.toHaveBeenCalled();
    expect(mockLocale.value).toBe('en'); // Locale should remain unchanged
  });
});
