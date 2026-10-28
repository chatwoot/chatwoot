<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import PortalBaseSettings from './PortalBaseSettings.vue';
import ConfirmDeletePortalDialog from './ConfirmDeletePortalDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortal', 'deletePortal']);

const { t } = useI18n();

const confirmDeletePortalDialogRef = ref(null);

const activePortalName = computed(() => props.activePortal?.name || '');

const handleUpdatePortal = portal => {
  emit('updatePortal', portal);
};

const openConfirmDeletePortalDialog = () => {
  confirmDeletePortalDialogRef.value.dialogRef.open();
};

const handleDeletePortal = () => {
  emit('deletePortal', props.activePortal);
  confirmDeletePortalDialogRef.value.dialogRef.close();
};
</script>

<template>
  <div class="flex flex-col w-full gap-4">
    <PortalBaseSettings
      :active-portal="activePortal"
      :is-fetching="isFetching"
      @update-portal="handleUpdatePortal"
    />
    <div class="w-full h-px bg-n-weak" />
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
            { portalName: activePortalName }
          )
        "
        color="ruby"
        class="max-w-56 !w-fit"
        @click="openConfirmDeletePortalDialog"
      />
    </div>
    <ConfirmDeletePortalDialog
      ref="confirmDeletePortalDialogRef"
      :active-portal-name="activePortalName"
      @delete-portal="handleDeletePortal"
    />
  </div>
</template>
