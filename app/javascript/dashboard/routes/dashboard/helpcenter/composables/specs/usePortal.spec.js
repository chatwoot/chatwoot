import { describe, it, expect, vi, beforeEach } from 'vitest';
import { usePortal } from '../usePortal';
import { useMapGetter } from 'dashboard/composables/store';
import { frontendURL } from 'dashboard/helper/URLHelper';
import allLocales from 'shared/constants/locales.js';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: vi.fn(),
}));

vi.mock('dashboard/helper/URLHelper', () => ({
  frontendURL: vi.fn(),
}));

describe('usePortal', () => {
  beforeEach(() => {
    vi.resetAllMocks();

    useMapGetter
      .mockReturnValueOnce('1')
      .mockReturnValueOnce('test-portal')
      .mockReturnValueOnce('en');

    frontendURL.mockImplementation(url => `/app/${url}`);
  });

  it('returns accountId', () => {
    const { accountId } = usePortal();
    expect(accountId.value).toBe('1');
  });

  it('returns portalSlug', () => {
    const { portalSlug } = usePortal();
    expect(portalSlug.value).toBe('test-portal');
  });

  it('returns locale', () => {
    const { locale } = usePortal();
    expect(locale.value).toBe('en');
  });

  it('generates correct articleUrl', () => {
    const { articleUrl } = usePortal();
    const url = articleUrl(123);
    expect(url).toBe('/app/accounts/1/portals/test-portal/en/articles/123');
    expect(frontendURL).toHaveBeenCalledWith(
      'accounts/1/portals/test-portal/en/articles/123'
    );
  });

  it('returns correct localeName', () => {
    const { localeName } = usePortal();
    expect(localeName('es')).toBe(allLocales.es);
    expect(localeName('fr')).toBe(allLocales.fr);
  });
});
