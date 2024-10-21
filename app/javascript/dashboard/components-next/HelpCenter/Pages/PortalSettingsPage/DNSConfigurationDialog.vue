<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['closeDialog']);

const { t } = useI18n();

const subdomainCNAME = ref('subdomain CNAME chatwoot.help');
const dialogRef = ref(null);

const handleDialogConfirm = () => {
  emit('closeDialog');
};

const handleDialogClose = () => {
  emit('closeDialog');
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.HEADER'
      )
    "
    :description="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.DESCRIPTION'
      )
    "
    :confirm-button-label="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.CONFIRM_BUTTON_LABEL'
      )
    "
    :cancel-button-label="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.CANCEL_BUTTON_LABEL'
      )
    "
    @confirm="handleDialogConfirm"
    @close="handleDialogClose"
  >
    <template #form>
      <div class="flex flex-col gap-6">
        <Input v-model="subdomainCNAME" disabled />
        <p class="text-sm text-n-slate-11">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.HELP_TEXT'
            )
          }}
        </p>
      </div>
    </template>
  </Dialog>
</template>
