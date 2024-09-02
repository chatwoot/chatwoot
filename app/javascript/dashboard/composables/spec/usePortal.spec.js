import { describe, it, expect, vi } from 'vitest';
import { usePortal } from '../usePortal';
import { useAccount } from 'dashboard/composables/useAccount';
import { useRoute } from 'dashboard/composables/route';
import { frontendURL } from 'dashboard/helper/URLHelper';
import allLocales from 'shared/constants/locales.js';

vi.mock('dashboard/composables/useAccount');
vi.mock('dashboard/composables/route');
vi.mock('dashboard/helper/URLHelper');

describe('usePortal', () => {
  beforeEach(() => {
    vi.mocked(useAccount).mockReturnValue({ accountId: { value: 123 } });
  });

  it('returns the correct properties', () => {
    vi.mocked(useRoute).mockReturnValue({
      params: { portalSlug: 'test-portal', locale: 'en' },
    });

    const portal = usePortal();

    expect(portal).toHaveProperty('accountId');
    expect(portal).toHaveProperty('portalSlug');
    expect(portal).toHaveProperty('locale');
    expect(portal).toHaveProperty('articleUrl');
    expect(portal).toHaveProperty('localeName');
  });

  it('computes portalSlug and locale correctly', () => {
    vi.mocked(useRoute).mockReturnValue({
      params: { portalSlug: 'test-portal', locale: 'fr' },
    });

    const { portalSlug, locale } = usePortal();

    expect(portalSlug.value).toBe('test-portal');
    expect(locale.value).toBe('fr');
  });

  it('generates correct article URL', () => {
    vi.mocked(useAccount).mockReturnValue({ accountId: { value: 456 } });
    vi.mocked(useRoute).mockReturnValue({
      params: { portalSlug: 'help-center', locale: 'es' },
    });
    vi.mocked(frontendURL).mockReturnValue('https://example.com/article');

    const { articleUrl } = usePortal();
    const url = articleUrl(789);

    expect(frontendURL).toHaveBeenCalledWith(
      'accounts/456/portals/help-center/es/articles/789'
    );
    expect(url).toBe('https://example.com/article');
  });

  it('returns correct locale name', () => {
    vi.mocked(useRoute).mockReturnValue({
      params: { portalSlug: 'test-portal', locale: 'ja' },
    });

    const { localeName } = usePortal();
    const name = localeName('ja');

    expect(name).toBe(allLocales.ja);
  });
});
