<script setup>
import PortalSettingsBasicForm from 'dashboard/routes/dashboard/helpcenter/components/PortalSettingsBasicForm.vue';

import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { defineOptions, computed, ref, onMounted } from 'vue';

defineOptions({ name: 'EditPortalBasic' });

const getters = useStoreGetters();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const uiFlags = getters['portals/uiFlagsIn'];

const lastPortalSlug = ref(null);

const currentPortalSlug = computed(() => {
  return route.params.portalSlug;
});

const currentPortal = computed(() => {
  const slug = route.params.portalSlug;
  return getters['portals/portalBySlug'].value(slug);
});

onMounted(() => {
  lastPortalSlug.value = currentPortalSlug.value;
});

async function updatePortalSettings(portalObj) {
  let alertMessage = '';

  try {
    const portalSlug = lastPortalSlug.value;
    await store.dispatch('portals/update', { ...portalObj, portalSlug });

    alertMessage = t('HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE_FOR_UPDATE');

    if (lastPortalSlug.value !== portalObj.slug) {
      await store.dispatch('portals/index');
      router.replace({
        name: route.name,
        params: { portalSlug: portalObj.slug },
      });
    }
  } catch (error) {
    alertMessage =
      error?.message ||
      t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_UPDATE');
  } finally {
    useAlert(alertMessage);
  }
}
async function deleteLogo() {
  try {
    const portalSlug = lastPortalSlug.value;
    await store.dispatch('portals/deleteLogo', {
      portalSlug,
    });
  } catch (error) {
    useAlert(
      error?.message || t('HELP_CENTER.PORTAL.ADD.LOGO.IMAGE_DELETE_ERROR')
    );
  }
}
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <PortalSettingsBasicForm
    v-if="currentPortal"
    :portal="currentPortal"
    :is-submitting="uiFlags.isUpdating"
    :submit-button-text="
      $t('HELP_CENTER.PORTAL.EDIT.EDIT_BASIC_INFO.BUTTON_TEXT')
    "
    @submit="updatePortalSettings"
    @delete-logo="deleteLogo"
  />
</template>
