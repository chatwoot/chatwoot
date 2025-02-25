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
    font_size: 'default',
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
    mockUISettings.value = { font_size: 'default' };
  });

  it('returns fontSizeOptions with correct structure', () => {
    const { fontSizeOptions } = useFontSize();
    expect(fontSizeOptions).toHaveLength(6);
    expect(fontSizeOptions[0]).toHaveProperty('value');
    expect(fontSizeOptions[0]).toHaveProperty('label');
    expect(fontSizeOptions).toContainEqual({
      value: 'default',
      label: 'Default',
    });
    expect(fontSizeOptions).toContainEqual({
      value: 'smaller',
      label: 'Smaller',
    });
    expect(fontSizeOptions).toContainEqual({
      value: 'extra-large',
      label: 'Extra Large',
    });
  });

  it('returns currentFontSize from UI settings', () => {
    const { currentFontSize } = useFontSize();
    expect(currentFontSize.value).toBe('default');

    mockUISettings.value.font_size = 'large';
    expect(currentFontSize.value).toBe('large');
  });

  it('applies font size to document root correctly based on semantic values', () => {
    const { applyFontSize } = useFontSize();

    applyFontSize('large');
    expect(document.documentElement.style.fontSize).toBe('18px');

    applyFontSize('smaller');
    expect(document.documentElement.style.fontSize).toBe('14px');

    applyFontSize('extra-large');
    expect(document.documentElement.style.fontSize).toBe('22px');

    applyFontSize('default');
    expect(document.documentElement.style.fontSize).toBe('');
  });

  it('does not re-apply the same font size for performance', () => {
    const { applyFontSize } = useFontSize();

    applyFontSize('large');
    global.requestAnimationFrame.mockClear();

    applyFontSize('large');
    expect(global.requestAnimationFrame).not.toHaveBeenCalled();
  });

  it('updates UI settings and applies font size', async () => {
    const { updateFontSize } = useFontSize();

    await updateFontSize('larger');

    expect(mockUpdateUISettings).toHaveBeenCalledWith({ font_size: 'larger' });
    expect(document.documentElement.style.fontSize).toBe('20px');
    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.UPDATE_SUCCESS'
    );
  });

  it('shows error alert when update fails', async () => {
    mockUpdateUISettings.mockRejectedValueOnce(new Error('Update failed'));

    const { updateFontSize } = useFontSize();
    await updateFontSize('larger');

    expect(useAlert).toHaveBeenCalledWith(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.UPDATE_ERROR'
    );
  });

  it('handles unknown font size values gracefully', () => {
    const { applyFontSize } = useFontSize();

    // Should not throw an error and should not apply any font size
    applyFontSize('unknown-size');
    expect(document.documentElement.style.fontSize).toBe('');
  });

  it('watches for UI settings changes and applies font size', async () => {
    useFontSize();

    // Initial font size should be default (no style)
    expect(document.documentElement.style.fontSize).toBe('');

    // Update UI settings
    mockUISettings.value = { font_size: 'large' };

    // Wait for next tick to let watchers fire
    await Promise.resolve();

    expect(document.documentElement.style.fontSize).toBe('18px');
  });
});
