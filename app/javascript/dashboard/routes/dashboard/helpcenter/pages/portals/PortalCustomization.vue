<script setup>
import PortalSettingsCustomizationForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsCustomizationForm.vue';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import { useAlert, useTrack } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { defineOptions, onMounted, computed } from 'vue';

defineOptions({
  name: 'PortalCustomization',
});

const getters = useStoreGetters();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const uiFlags = getters['portals/uiFlagsIn'];

const currentPortal = computed(() => {
  const slug = route.params.portalSlug;
  if (slug) return getters['portals/portalBySlug'].value(slug);

  return {};
});

onMounted(() => {
  store.dispatch('portals/index');
});

async function updatePortalSettings(portalObj) {
  const portalSlug = route.params.portalSlug;
  let alertMessage = '';
  try {
    await store.dispatch('portals/update', {
      portalSlug,
      ...portalObj,
    });
    alertMessage = t('HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE');

    useTrack(PORTALS_EVENTS.ONBOARD_CUSTOMIZATION, {
      hasHomePageLink: Boolean(portalObj.homepage_link),
      hasPageTitle: Boolean(portalObj.page_title),
      hasHeaderText: Boolean(portalObj.headerText),
    });
  } catch (error) {
    alertMessage =
      error?.message ||
      t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_UPDATE');
  } finally {
    useAlert(alertMessage);
    router.push({ name: 'portal_finish' });
  }
}
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <PortalSettingsCustomizationForm
    v-if="currentPortal"
    :portal="currentPortal"
    :is-submitting="uiFlags.isUpdating"
    :submit-button-text="
      $t('HELP_CENTER.PORTAL.EDIT.EDIT_BASIC_INFO.BUTTON_TEXT')
    "
    @submit="updatePortalSettings"
  />
</template>
