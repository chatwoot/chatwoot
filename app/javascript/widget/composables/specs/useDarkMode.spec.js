import { ref } from 'vue';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useDarkMode } from '../useDarkMode';
import { useStoreGetters } from 'dashboard/composables/store';

vi.mock('dashboard/composables/store');

describe('useDarkMode', () => {
  beforeEach(() => {
    useStoreGetters.mockReturnValue({
      'appConfig/getDarkMode': ref('light'),
    });

    // Mock window.matchMedia
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: vi.fn().mockImplementation(query => ({
        matches: false,
        media: query,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })),
    });
  });

  it('returns light theme when darkMode is light', () => {
    const { $dm } = useDarkMode();
    expect($dm('bg-100', 'bg-600')).toBe('bg-100');
  });

  it('returns dark theme when darkMode is dark', () => {
    useStoreGetters.mockReturnValue({
      'appConfig/getDarkMode': ref('dark'),
    });
    const { $dm } = useDarkMode();
    expect($dm('bg-100', 'bg-600')).toBe('bg-600');
  });

  it('returns both themes when darkMode is auto', () => {
    useStoreGetters.mockReturnValue({
      'appConfig/getDarkMode': ref('auto'),
    });
    const { $dm } = useDarkMode();
    expect($dm('bg-100', 'bg-600')).toBe('bg-100 bg-600');
  });

  it('correctly computes prefersDarkMode when OS is in dark mode', () => {
    useStoreGetters.mockReturnValue({
      'appConfig/getDarkMode': ref('auto'),
    });
    window.matchMedia.mockImplementationOnce(query => ({
      matches: query === '(prefers-color-scheme: dark)',
      media: query,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }));
    const { prefersDarkMode } = useDarkMode();
    expect(prefersDarkMode.value).toBe(true);
  });

  it('correctly computes prefersDarkMode when OS is not in dark mode', () => {
    useStoreGetters.mockReturnValue({
      'appConfig/getDarkMode': ref('auto'),
    });
    const { prefersDarkMode } = useDarkMode();
    expect(prefersDarkMode.value).toBe(false);
  });
});
