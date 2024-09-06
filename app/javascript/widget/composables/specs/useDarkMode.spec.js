import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useDarkMode } from '../useDarkMode';
import { useMapGetter } from 'dashboard/composables/store';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: vi.fn(),
}));

describe('useDarkMode', () => {
  let mockDarkMode;

  beforeEach(() => {
    mockDarkMode = { value: 'light' };
    vi.mocked(useMapGetter).mockReturnValue(mockDarkMode);
  });

  it('returns darkMode, prefersDarkMode, and getThemeClass', () => {
    const result = useDarkMode();
    expect(result).toHaveProperty('darkMode');
    expect(result).toHaveProperty('prefersDarkMode');
    expect(result).toHaveProperty('getThemeClass');
  });

  describe('prefersDarkMode', () => {
    it('returns false when darkMode is light', () => {
      const { prefersDarkMode } = useDarkMode();
      expect(prefersDarkMode.value).toBe(false);
    });

    it('returns true when darkMode is dark', () => {
      mockDarkMode.value = 'dark';
      const { prefersDarkMode } = useDarkMode();
      expect(prefersDarkMode.value).toBe(true);
    });

    it('returns true when darkMode is auto and OS prefers dark mode', () => {
      mockDarkMode.value = 'auto';
      vi.spyOn(window, 'matchMedia').mockReturnValue({ matches: true });
      const { prefersDarkMode } = useDarkMode();
      expect(prefersDarkMode.value).toBe(true);
    });

    it('returns false when darkMode is auto and OS prefers light mode', () => {
      mockDarkMode.value = 'auto';
      vi.spyOn(window, 'matchMedia').mockReturnValue({ matches: false });
      const { prefersDarkMode } = useDarkMode();
      expect(prefersDarkMode.value).toBe(false);
    });
  });

  describe('getThemeClass', () => {
    it('returns light class when darkMode is light', () => {
      const { getThemeClass } = useDarkMode();
      expect(getThemeClass('light-class', 'dark-class')).toBe('light-class');
    });

    it('returns dark class when darkMode is dark', () => {
      mockDarkMode.value = 'dark';
      const { getThemeClass } = useDarkMode();
      expect(getThemeClass('light-class', 'dark-class')).toBe('dark-class');
    });

    it('returns both classes when darkMode is auto', () => {
      mockDarkMode.value = 'auto';
      const { getThemeClass } = useDarkMode();
      expect(getThemeClass('light-class', 'dark-class')).toBe(
        'light-class dark-class'
      );
    });
  });
});
