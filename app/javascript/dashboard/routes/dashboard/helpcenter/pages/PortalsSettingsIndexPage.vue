<script setup>
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import PortalSettings from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalSettings.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const portals = useMapGetter('portals/allPortals');
const isFetching = useMapGetter('portals/isFetchingPortals');

const getNextAvailablePortal = deletedPortalSlug =>
  portals.value?.find(portal => portal.slug !== deletedPortalSlug) ?? null;

const fetchPortalAndItsCategories = async (slug, locale) => {
  const selectedPortalParam = { portalSlug: slug, locale };
  await Promise.all([
    store.dispatch('portals/index'),
    store.dispatch('portals/show', selectedPortalParam),
    store.dispatch('categories/index', selectedPortalParam),
    store.dispatch('agents/get'),
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

const updatePortalSettings = async portalObj => {
  const { portalSlug } = route.params;
  try {
    await store.dispatch('portals/update', {
      ...portalObj,
      portalSlug: portalSlug || portalObj?.slug,
    });
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
