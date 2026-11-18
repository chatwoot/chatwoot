import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store.js';

export const DEFAULT_ROUTE = 'portals_articles_index';
const CATEGORY_ROUTE = 'portals_categories_index';
const CATEGORY_SUB_ROUTES = [
  'portals_categories_articles_index',
  'portals_categories_articles_new',
  'portals_categories_articles_edit',
];

export function usePortalSwitcher() {
  const route = useRoute();
  const router = useRouter();
  const store = useStore();

  const fetchPortalAndItsCategories = async (slug, locale) => {
    await store.dispatch('portals/switchPortal', true);
    await store.dispatch('portals/index');
    const selectedPortalParam = {
      portalSlug: slug,
      locale,
    };
    await store.dispatch('portals/show', selectedPortalParam);
    await store.dispatch('categories/index', selectedPortalParam);
    await store.dispatch('agents/get');
    await store.dispatch('portals/switchPortal', false);
  };

  const switchPortal = async portal => {
    const {
      slug,
      meta: { default_locale: defaultLocale },
    } = portal;
    await fetchPortalAndItsCategories(slug, defaultLocale);
    const targetRouteName = CATEGORY_SUB_ROUTES.includes(route.name)
      ? CATEGORY_ROUTE
      : route.name || DEFAULT_ROUTE;
    router.push({
      name: targetRouteName,
      params: {
        portalSlug: slug,
        locale: defaultLocale,
      },
    });
  };

  return { switchPortal };
}
