<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import PortalBaseSettings from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalBaseSettings.vue';
import PortalConfigurationSettings from './PortalConfigurationSettings.vue';
import ConfirmDeletePortalDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/ConfirmDeletePortalDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  portals: {
    type: Array,
    required: true,
  },
  isFetching: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortal',
  'updatePortalConfiguration',
  'deletePortal',
  'refreshStatus',
  'sendCnameInstructions',
]);

const { t } = useI18n();
const route = useRoute();

const confirmDeletePortalDialogRef = ref(null);

const currentPortalSlug = computed(() => route.params.portalSlug);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isFetchingSSLStatus = useMapGetter('portals/isFetchingSSLStatus');

const activePortal = computed(() => {
  return props.portals?.find(portal => portal.slug === currentPortalSlug.value);
});

const activePortalName = computed(() => activePortal.value?.name || '');

const isLoading = computed(() => props.isFetching || isSwitchingPortal.value);

const handleUpdatePortal = portal => {
  emit('updatePortal', portal);
};

const handleUpdatePortalConfiguration = portal => {
  emit('updatePortalConfiguration', portal);
};

const fetchSSLStatus = () => {
  emit('refreshStatus');
};

const handleSendCnameInstructions = payload => {
  emit('sendCnameInstructions', payload);
};

const openConfirmDeletePortalDialog = () => {
  confirmDeletePortalDialogRef.value.dialogRef.open();
};

const handleDeletePortal = () => {
  emit('deletePortal', activePortal.value);
  confirmDeletePortalDialogRef.value.dialogRef.close();
};
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center gap-2 py-10 pb-8 pt-2 text-on-surface-variant"
      >
        <Spinner />
      </div>
      <div
        v-else-if="activePortal"
        class="portal-settings-page mx-auto flex w-full max-w-[60rem] flex-col space-y-10 pb-8 text-on-surface antialiased selection:bg-secondary/30"
      >
        <header class="space-y-1">
          <h1 class="text-3xl font-bold tracking-tight text-on-surface">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.PAGE_TITLE') }}
          </h1>
          <p class="mb-0 text-lg text-on-primary-container">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.PAGE_SUBTITLE') }}
          </p>
        </header>

        <div class="space-y-8">
          <PortalBaseSettings
            :active-portal="activePortal"
            :is-fetching="isFetching"
            @update-portal="handleUpdatePortal"
          />

          <PortalConfigurationSettings
            :active-portal="activePortal"
            :is-fetching="isFetching"
            :is-fetching-status="isFetchingSSLStatus"
            @update-portal-configuration="handleUpdatePortalConfiguration"
            @refresh-status="fetchSSLStatus"
            @send-cname-instructions="handleSendCnameInstructions"
          />

          <section
            class="rounded-xl border border-outline-variant/5 bg-surface-container-low p-6 shadow-sm"
          >
            <div
              class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
            >
              <div class="flex gap-3">
                <Icon
                  icon="i-lucide-alert-triangle"
                  class="mt-0.5 size-5 shrink-0 text-error"
                />
                <div class="min-w-0 space-y-1">
                  <h3 class="text-base font-semibold text-on-surface">
                    {{
                      t(
                        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.HEADER'
                      )
                    }}
                  </h3>
                  <p class="mb-0 text-sm text-on-surface-variant">
                    {{
                      t(
                        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DESCRIPTION'
                      )
                    }}
                  </p>
                </div>
              </div>
              <div class="shrink-0 sm:pt-0.5">
                <Button
                  :label="
                    t(
                      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.BUTTON',
                      {
                        portalName: activePortalName,
                      }
                    )
                  "
                  color="ruby"
                  class="max-w-56 !w-fit"
                  @click="openConfirmDeletePortalDialog"
                />
              </div>
            </div>
          </section>
        </div>
      </div>
    </template>
    <ConfirmDeletePortalDialog
      ref="confirmDeletePortalDialogRef"
      :active-portal-name="activePortalName"
      @delete-portal="handleDeletePortal"
    />
  </HelpCenterLayout>
</template>
