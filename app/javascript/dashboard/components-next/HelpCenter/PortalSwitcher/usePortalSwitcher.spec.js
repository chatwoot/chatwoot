import { usePortalSwitcher } from './usePortalSwitcher';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  push: vi.fn(),
  route: { name: '', params: { portalSlug: 'handbook' } },
}));

vi.mock('vue-router', () => ({
  useRoute: () => mocks.route,
  useRouter: () => ({ push: mocks.push }),
}));
vi.mock('dashboard/composables/store.js', () => ({
  useStore: () => ({ dispatch: mocks.dispatch }),
}));

const portal = { slug: 'docs', meta: { default_locale: 'en' } };

describe('usePortalSwitcher', () => {
  beforeEach(() => {
    mocks.dispatch.mockReset();
    mocks.push.mockReset();
  });

  it('loads the portal, then opens the same page for it', async () => {
    mocks.route.name = 'portals_locales_index';

    await usePortalSwitcher().switchPortal(portal);

    expect(mocks.dispatch).toHaveBeenCalledWith('portals/show', {
      portalSlug: 'docs',
      locale: 'en',
    });
    expect(mocks.push).toHaveBeenCalledWith({
      name: 'portals_locales_index',
      params: { portalSlug: 'docs', locale: 'en' },
    });
  });

  it('opens the category list when switching from inside a category', async () => {
    mocks.route.name = 'portals_categories_articles_index';

    await usePortalSwitcher().switchPortal(portal);

    expect(mocks.push).toHaveBeenCalledWith({
      name: 'portals_categories_index',
      params: { portalSlug: 'docs', locale: 'en' },
    });
  });
});
