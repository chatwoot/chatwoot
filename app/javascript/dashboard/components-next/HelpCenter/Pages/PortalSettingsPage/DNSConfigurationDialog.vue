<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getHostNameFromURL } from 'dashboard/helper/URLHelper';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  customDomain: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['confirm']);

const { t } = useI18n();

const domain = computed(() => {
  const { hostURL, helpCenterURL } = window?.chatwootConfig || {};
  return getHostNameFromURL(helpCenterURL) || getHostNameFromURL(hostURL) || '';
});

const subdomainCNAME = computed(
  () => `${props.customDomain} CNAME ${domain.value}`
);

const dialogRef = ref(null);

const handleDialogConfirm = () => {
  emit('confirm');
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
    :confirm-button-label="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.CONFIRM_BUTTON_LABEL'
      )
    "
    :show-cancel-button="false"
    @confirm="handleDialogConfirm"
  >
    <template #description>
      <p class="mb-0 text-sm text-n-slate-12">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.DESCRIPTION'
          )
        }}
      </p>
    </template>

    <div class="flex flex-col gap-6">
      <span
        class="h-10 px-3 py-2.5 text-sm select-none bg-transparent border rounded-lg text-n-slate-11 border-n-strong"
      >
        {{ subdomainCNAME }}
      </span>
      <p class="text-sm text-n-slate-12">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DNS_CONFIGURATION_DIALOG.HELP_TEXT'
          )
        }}
      </p>
    </div>
  </Dialog>
</template>
