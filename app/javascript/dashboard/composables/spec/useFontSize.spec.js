import { ref } from 'vue';
import { useFontSize } from '../useFontSize';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

// Mock dependencies
vi.mock('dashboard/composables/useUISettings');
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(message => message),
}));
vi.mock('vue-i18n');

// Mock requestAnimationFrame
global.requestAnimationFrame = vi.fn(cb => cb());

describe('useFontSize', () => {
  const mockUISettings = ref({
    font_size: '16px',
  });
  const mockUpdateUISettings = vi.fn().mockResolvedValue(undefined);
  const mockTranslate = vi.fn(key => key);

  beforeEach(() => {
    vi.clearAllMocks();

    // Setup mocks
    useUISettings.mockReturnValue({
      uiSettings: mockUISettings,
      updateUISettings: mockUpdateUISettings,
    });

    useI18n.mockReturnValue({
      t: mockTranslate,
    });

    // Reset DOM state
    document.documentElement.style.removeProperty('font-size');

    // Reset mockUISettings to default
    mockUISettings.value = { font_size: '16px' };
  });

  it('returns fontSizeOptions with correct structure', () => {
    const { fontSizeOptions } = useFontSize();
    expect(fontSizeOptions).toHaveLength(6);
    expect(fontSizeOptions[0]).toHaveProperty('value');
    expect(fontSizeOptions[0]).toHaveProperty('label');

    // Check specific options
    expect(fontSizeOptions.find(option => option.value === '16px')).toEqual({
      value: '16px',
      label:
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.DEFAULT',
    });

    expect(fontSizeOptions.find(option => option.value === '14px')).toEqual({
      value: '14px',
      label:
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.SMALLER',
    });

    expect(fontSizeOptions.find(option => option.value === '22px')).toEqual({
      value: '22px',
      label:
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.EXTRA_LARGE',
    });
  });

  it('returns currentFontSize from UI settings', () => {
    const { currentFontSize } = useFontSize();
    expect(currentFontSize.value).toBe('16px');

    mockUISettings.value.font_size = '18px';
    expect(currentFontSize.value).toBe('18px');
  });

  it('applies font size to document root correctly based on pixel values', () => {
    const { applyFontSize } = useFontSize();

    applyFontSize('18px');
    expect(document.documentElement.style.fontSize).toBe('18px');

    applyFontSize('14px');
    expect(document.documentElement.style.fontSize).toBe('14px');

    applyFontSize('22px');
    expect(document.documentElement.style.fontSize).toBe('22px');

    applyFontSize('16px');
    expect(document.documentElement.style.fontSize).toBe('16px');
  });

  it('updates UI settings and applies font size', async () => {
    const { updateFontSize } = useFontSize();

    await updateFontSize('20px');

    expect(mockUpdateUISettings).toHaveBeenCalledWith({ font_size: '20px' });
    expect(document.documentElement.style.fontSize).toBe('20px');
    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.UPDATE_SUCCESS'
    );
  });

  it('shows error alert when update fails', async () => {
    mockUpdateUISettings.mockRejectedValueOnce(new Error('Update failed'));

    const { updateFontSize } = useFontSize();
    await updateFontSize('20px');

    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.UPDATE_ERROR'
    );
  });

  it('handles unknown font size values gracefully', () => {
    const { applyFontSize } = useFontSize();

    // Should not throw an error and should apply the default font size
    applyFontSize('unknown-size');
    expect(document.documentElement.style.fontSize).toBe('16px');
  });

  it('watches for UI settings changes and applies font size', async () => {
    useFontSize();

    // Initial font size should now be 16px instead of empty
    expect(document.documentElement.style.fontSize).toBe('16px');

    // Update UI settings
    mockUISettings.value = { font_size: '18px' };

    // Wait for next tick to let watchers fire
    await Promise.resolve();

    expect(document.documentElement.style.fontSize).toBe('18px');
  });

  it('translates font size option labels correctly', () => {
    // Set up specific translation mapping
    mockTranslate.mockImplementation(key => {
      const translations = {
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.SMALLER':
          'Smaller',
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.DEFAULT':
          'Default',
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.EXTRA_LARGE':
          'Extra Large',
      };
      return translations[key] || key;
    });

    const { fontSizeOptions } = useFontSize();

    // Check that translation is applied
    expect(fontSizeOptions.find(option => option.value === '14px').label).toBe(
      'Smaller'
    );
    expect(fontSizeOptions.find(option => option.value === '16px').label).toBe(
      'Default'
    );
    expect(fontSizeOptions.find(option => option.value === '22px').label).toBe(
      'Extra Large'
    );

    // Verify translation function was called with correct keys
    expect(mockTranslate).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.SMALLER'
    );
    expect(mockTranslate).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.DEFAULT'
    );
  });
});
