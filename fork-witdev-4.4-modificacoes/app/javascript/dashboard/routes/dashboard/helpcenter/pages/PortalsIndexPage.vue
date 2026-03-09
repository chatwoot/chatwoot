<script setup>
import { computed, nextTick, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();
const router = useRouter();
const { uiSettings } = useUISettings();
const route = useRoute();

const portals = computed(() => store.getters['portals/allPortals']);

const isPortalPresent = portalSlug => {
  return !!portals.value.find(portal => portal.slug === portalSlug);
};

const routeToView = (name, params) => {
  router.replace({ name, params, replace: true });
};

const generateRouterParams = () => {
  const {
    last_active_portal_slug: lastActivePortalSlug,
    last_active_locale_code: lastActiveLocaleCode,
  } = uiSettings.value || {};
  if (isPortalPresent(lastActivePortalSlug)) {
    return {
      portalSlug: lastActivePortalSlug,
      locale: lastActiveLocaleCode,
    };
  }

  if (portals.value.length > 0) {
    const { slug: portalSlug, meta: { default_locale: locale } = {} } =
      portals.value[0];
    return { portalSlug, locale };
  }

  return null;
};

const routeToLastActivePortal = () => {
  const params = generateRouterParams();
  const { navigationPath } = route.params;
  const isAValidRoute = [
    'portals_articles_index',
    'portals_categories_index',
    'portals_locales_index',
    'portals_settings_index',
  ].includes(navigationPath);

  const navigateTo = isAValidRoute ? navigationPath : 'portals_articles_index';
  if (params) {
    return routeToView(navigateTo, params);
  }
  return routeToView('portals_new', {});
};

const performRouting = async () => {
  await store.dispatch('portals/index');
  nextTick(() => routeToLastActivePortal());
};

onMounted(() => performRouting());
</script>

<template>
  <div
    class="flex items-center justify-center w-full bg-n-background text-slate-600 dark:text-slate-200"
  >
    <Spinner />
  </div>
</template>
