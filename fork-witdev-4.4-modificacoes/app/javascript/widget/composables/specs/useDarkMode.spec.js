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

  it('returns darkMode, prefersDarkMode', () => {
    const result = useDarkMode();
    expect(result).toHaveProperty('darkMode');
    expect(result).toHaveProperty('prefersDarkMode');
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
});
