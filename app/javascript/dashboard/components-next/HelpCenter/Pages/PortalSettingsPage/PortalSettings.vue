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
]);

const { t } = useI18n();
const route = useRoute();

const confirmDeletePortalDialogRef = ref(null);

const currentPortalSlug = computed(() => route.params.portalSlug);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');

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
        class="flex items-center justify-center py-10 pt-2 pb-8 text-n-slate-11"
      >
        <Spinner />
      </div>
      <div
        v-else-if="activePortal"
        class="flex flex-col w-full gap-4 max-w-[40rem] pb-8"
      >
        <PortalBaseSettings
          :active-portal="activePortal"
          :is-fetching="isFetching"
          @update-portal="handleUpdatePortal"
        />
        <div class="w-full h-px bg-slate-50 dark:bg-slate-800/50" />
        <PortalConfigurationSettings
          :active-portal="activePortal"
          :is-fetching="isFetching"
          @update-portal-configuration="handleUpdatePortalConfiguration"
        />
        <div class="w-full h-px bg-slate-50 dark:bg-slate-800/50" />
        <div class="flex items-end justify-between w-full gap-4">
          <div class="flex flex-col gap-2">
            <h6 class="text-base font-medium text-n-slate-12">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.HEADER'
                )
              }}
            </h6>
            <span class="text-sm text-n-slate-11">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DESCRIPTION'
                )
              }}
            </span>
          </div>
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
    </template>
    <ConfirmDeletePortalDialog
      ref="confirmDeletePortalDialogRef"
      :active-portal-name="activePortalName"
      @delete-portal="handleDeletePortal"
    />
  </HelpCenterLayout>
</template>
