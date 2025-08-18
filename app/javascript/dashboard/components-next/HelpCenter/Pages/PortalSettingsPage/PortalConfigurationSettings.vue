<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

import AddCustomDomainDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/AddCustomDomainDialog.vue';
import DNSConfigurationDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/DNSConfigurationDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
  isFetchingStatus: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortalConfiguration',
  'refreshStatus',
  'sendCnameInstructions',
]);

const SSL_STATUS = {
  LIVE: ['active', 'staging_active'],
  PENDING: [
    'provisioned',
    'pending',
    'initializing',
    'pending_validation',
    'pending_deployment',
    'pending_issuance',
    'holding_deployment',
    'holding_validation',
    'pending_expiration',
    'pending_cleanup',
    'pending_deletion',
    'staging_deployment',
    'backup_issued',
  ],
  ERROR: [
    'blocked',
    'inactive',
    'moved',
    'expired',
    'deleted',
    'timed_out_initializing',
    'timed_out_validation',
    'timed_out_issuance',
    'timed_out_deployment',
    'timed_out_deletion',
    'deactivating',
  ],
};

const { t } = useI18n();
const { isOnChatwootCloud } = useAccount();

const addCustomDomainDialogRef = ref(null);
const dnsConfigurationDialogRef = ref(null);
const updatedDomainAddress = ref('');

const customDomainAddress = computed(
  () => props.activePortal?.custom_domain || ''
);

const sslSettings = computed(() => props.activePortal?.ssl_settings || {});
const verificationErrors = computed(
  () => sslSettings.value.verification_errors || ''
);

const isLive = computed(() =>
  SSL_STATUS.LIVE.includes(sslSettings.value.status)
);
const isPending = computed(() =>
  SSL_STATUS.PENDING.includes(sslSettings.value.status)
);
const isError = computed(() =>
  SSL_STATUS.ERROR.includes(sslSettings.value.status)
);

const statusText = computed(() => {
  if (isLive.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.LIVE'
    );
  if (isPending.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.PENDING'
    );
  if (isError.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.ERROR'
    );
  return '';
});

const statusColors = computed(() => {
  if (isLive.value)
    return { text: 'text-n-teal-11', bubble: 'outline-n-teal-6 bg-n-teal-9' };
  if (isError.value)
    return { text: 'text-n-ruby-11', bubble: 'outline-n-ruby-6 bg-n-ruby-9' };
  return { text: 'text-n-amber-11', bubble: 'outline-n-amber-6 bg-n-amber-9' };
});

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

const onClickRefreshSSLStatus = () => {
  emit('refreshStatus');
};

const onClickSend = email => {
  emit('sendCnameInstructions', {
    portalSlug: props.activePortal?.slug,
    email,
  });
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
      <div class="flex items-center justify-between w-full gap-2">
        <div v-if="customDomainAddress" class="flex flex-col gap-1">
          <div class="flex items-center w-full h-8 gap-4">
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
          <span
            v-if="!isLive && isOnChatwootCloud"
            class="text-sm text-n-slate-11"
          >
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS_DESCRIPTION'
              )
            }}
          </span>
        </div>
        <div class="flex items-center">
          <div v-if="customDomainAddress" class="flex items-center gap-3">
            <div
              v-if="statusText && isOnChatwootCloud"
              v-tooltip="verificationErrors"
              class="flex items-center gap-3 flex-shrink-0"
            >
              <span
                class="size-1.5 rounded-full outline outline-2 block flex-shrink-0"
                :class="statusColors.bubble"
              />
              <span
                :class="statusColors.text"
                class="text-sm leading-[16px] font-medium"
              >
                {{ statusText }}
              </span>
            </div>
            <div
              v-if="statusText && isOnChatwootCloud"
              class="w-px h-3 bg-n-weak"
            />
            <Button
              slate
              sm
              link
              :label="
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.EDIT_BUTTON'
                )
              "
              class="hover:!no-underline flex-shrink-0"
              @click="addCustomDomainDialogRef.dialogRef.open()"
            />
            <div v-if="isOnChatwootCloud" class="w-px h-3 bg-n-weak" />
            <Button
              v-if="isOnChatwootCloud"
              slate
              sm
              link
              icon="i-lucide-refresh-ccw"
              :class="isFetchingStatus && 'animate-spin'"
              @click="onClickRefreshSSLStatus"
            />
          </div>
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
      @close="closeDNSConfigurationDialog"
      @send="onClickSend"
    />
  </div>
</template>
