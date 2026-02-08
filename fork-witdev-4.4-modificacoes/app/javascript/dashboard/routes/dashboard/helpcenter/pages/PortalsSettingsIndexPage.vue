<script setup>
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import PortalSettings from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalSettings.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const { updateUISettings } = useUISettings();

const portals = useMapGetter('portals/allPortals');
const isFetching = useMapGetter('portals/isFetchingPortals');
const getPortalBySlug = useMapGetter('portals/portalBySlug');

const getNextAvailablePortal = deletedPortalSlug =>
  portals.value?.find(portal => portal.slug !== deletedPortalSlug) ?? null;

const getDefaultLocale = slug => {
  return getPortalBySlug.value(slug)?.meta?.default_locale;
};

const fetchPortalAndItsCategories = async (slug, locale) => {
  const selectedPortalParam = { portalSlug: slug, locale };
  await Promise.all([
    store.dispatch('portals/index'),
    store.dispatch('portals/show', selectedPortalParam),
    store.dispatch('categories/index', selectedPortalParam),
    store.dispatch('agents/get'),
    store.dispatch('inboxes/get'),
  ]);
};

const updateRouteAfterDeletion = async deletedPortalSlug => {
  const nextPortal = getNextAvailablePortal(deletedPortalSlug);
  if (nextPortal) {
    const {
      slug,
      meta: { default_locale: defaultLocale },
    } = nextPortal;
    await fetchPortalAndItsCategories(slug, defaultLocale);
    router.push({
      name: 'portals_articles_index',
      params: { portalSlug: slug, locale: defaultLocale },
    });
  } else {
    router.push({ name: 'portals_new' });
  }
};

const refreshPortalRoute = async (newSlug, defaultLocale) => {
  // This is to refresh the portal route and update the UI settings
  // If there is slug change, this will be called to refresh the route and UI settings
  await fetchPortalAndItsCategories(newSlug, defaultLocale);
  updateUISettings({
    last_active_portal_slug: newSlug,
    last_active_locale_code: defaultLocale,
  });
  await router.replace({
    name: 'portals_settings_index',
    params: { portalSlug: newSlug },
  });
};

const updatePortalSettings = async portalObj => {
  const { portalSlug } = route.params;
  try {
    const defaultLocale = getDefaultLocale(portalSlug);
    await store.dispatch('portals/update', {
      ...portalObj,
      portalSlug: portalSlug || portalObj?.slug,
    });

    // If there is a slug change, this will refresh the route and update the UI settings
    if (portalObj?.slug && portalSlug !== portalObj.slug) {
      await refreshPortalRoute(portalObj.slug, defaultLocale);
    }
    useAlert(
      t('HELP_CENTER.PORTAL_SETTINGS.API.UPDATE_PORTAL.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.PORTAL_SETTINGS.API.UPDATE_PORTAL.ERROR_MESSAGE')
    );
  }
};

const deletePortal = async selectedPortalForDelete => {
  const { slug } = selectedPortalForDelete;
  try {
    await store.dispatch('portals/delete', { portalSlug: slug });
    await updateRouteAfterDeletion(slug);
    useAlert(
      t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.API.DELETE_SUCCESS')
    );
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.DELETE_PORTAL.API.DELETE_ERROR')
    );
  }
};

const handleUpdatePortal = updatePortalSettings;
const handleUpdatePortalConfiguration = updatePortalSettings;
const handleDeletePortal = deletePortal;
</script>

<template>
  <PortalSettings
    :portals="portals"
    :is-fetching="isFetching"
    @update-portal="handleUpdatePortal"
    @update-portal-configuration="handleUpdatePortalConfiguration"
    @delete-portal="handleDeletePortal"
  />
</template>
