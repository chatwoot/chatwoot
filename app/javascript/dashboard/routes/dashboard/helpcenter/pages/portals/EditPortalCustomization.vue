<script setup>
import PortalSettingsCustomizationForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsCustomizationForm.vue';

import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { defineOptions, computed } from 'vue';

defineOptions({
  name: 'EditPortalCustomization',
});

const getters = useStoreGetters();
const route = useRoute();
const store = useStore();
const { t } = useI18n();

const uiFlags = getters['portals/uiFlagsIn'];

const currentPortal = computed(() => {
  const slug = route.params.portalSlug;
  return getters['portals/portalBySlug'].value(slug);
});

async function updatePortalSettings(portalObj) {
  const portalSlug = route.params.portalSlug;
  let alertMessage = '';
  try {
    await store.dispatch('portals/update', {
      ...portalObj,
      portalSlug,
    });

    alertMessage = t('HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE');
  } catch (error) {
    alertMessage =
      error?.message ||
      t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_UPDATE');
  } finally {
    useAlert(alertMessage);
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
