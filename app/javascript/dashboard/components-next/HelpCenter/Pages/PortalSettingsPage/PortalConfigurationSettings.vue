<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import AddCustomDomainDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/AddCustomDomainDialog.vue';
import DNSConfigurationDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/DNSConfigurationDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();

const addCustomDomainDialogRef = ref(null);
const dnsConfigurationDialogRef = ref(null);
const updatedDomainAddress = ref('');

const customDomainAddress = computed(
  () => props.activePortal?.custom_domain || ''
);

const updatePortalConfiguration = customDomain => {
  const portal = {
    id: props.activePortal?.id,
    custom_domain: customDomain,
  };
  emit('updatePortalConfiguration', portal);
  addCustomDomainDialogRef.value.dialogRef.close();
  if (customDomain) {
    updatedDomainAddress.value = customDomain;
    dnsConfigurationDialogRef.value.dialogRef.open();
  }
};

const closeDNSConfigurationDialog = () => {
  updatedDomainAddress.value = '';
  dnsConfigurationDialogRef.value.dialogRef.close();
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.HEADER'
          )
        }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DESCRIPTION'
          )
        }}
      </span>
    </div>
    <div class="flex flex-col w-full gap-4">
      <div class="flex justify-between w-full gap-2">
        <div
          v-if="customDomainAddress"
          class="flex items-center w-full h-8 gap-4"
        >
          <label class="text-sm font-medium text-n-slate-12">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.LABEL'
              )
            }}
          </label>
          <span class="text-sm text-n-slate-12">
            {{ customDomainAddress }}
          </span>
        </div>
        <div class="flex items-center justify-end w-full">
          <Button
            v-if="customDomainAddress"
            color="slate"
            :label="
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.EDIT_BUTTON'
              )
            "
            @click="addCustomDomainDialogRef.dialogRef.open()"
          />
          <Button
            v-else
            :label="
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.ADD_BUTTON'
              )
            "
            color="slate"
            @click="addCustomDomainDialogRef.dialogRef.open()"
          />
        </div>
      </div>
    </div>
    <AddCustomDomainDialog
      ref="addCustomDomainDialogRef"
      :mode="customDomainAddress ? 'edit' : 'add'"
      :custom-domain="customDomainAddress"
      @add-custom-domain="updatePortalConfiguration"
    />
    <DNSConfigurationDialog
      ref="dnsConfigurationDialogRef"
      :custom-domain="updatedDomainAddress || customDomainAddress"
      @confirm="closeDNSConfigurationDialog"
    />
  </div>
</template>
