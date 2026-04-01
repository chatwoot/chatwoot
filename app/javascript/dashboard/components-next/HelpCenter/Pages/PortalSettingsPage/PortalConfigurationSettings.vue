<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

import AddCustomDomainDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/AddCustomDomainDialog.vue';
import DNSConfigurationDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/DNSConfigurationDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
    return {
      text: 'text-secondary',
      bubble: 'bg-secondary/30 ring-2 ring-secondary/45',
    };
  if (isError.value)
    return {
      text: 'text-error',
      bubble: 'bg-error/25 ring-2 ring-error/40',
    };
  return {
    text: 'text-amber-11',
    bubble: 'bg-amber-9/60 ring-2 ring-amber-7/50',
  };
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
  <section
    class="rounded-xl border border-outline-variant/5 bg-surface-container-low p-6 shadow-sm"
  >
    <h3
      class="mb-6 flex items-center gap-2 text-lg font-semibold text-on-surface"
    >
      <Icon icon="i-lucide-globe" class="size-5 shrink-0 text-secondary" />
      {{
        t('HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.HEADER')
      }}
    </h3>
    <p class="mb-6 text-sm text-on-primary-container">
      {{
        t(
          'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DESCRIPTION'
        )
      }}
    </p>
    <div class="flex w-full flex-col gap-4">
      <div class="flex w-full items-center justify-between gap-2">
        <div v-if="customDomainAddress" class="flex flex-col gap-1">
          <div class="flex h-8 w-full items-center gap-4">
            <label
              class="text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
            >
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.LABEL'
                )
              }}
            </label>
            <span class="text-sm text-on-surface">
              {{ customDomainAddress }}
            </span>
          </div>
          <span
            v-if="!isLive && isOnChatwootCloud"
            class="text-sm text-on-surface-variant"
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
              class="flex flex-shrink-0 items-center gap-3"
            >
              <span
                class="block size-1.5 flex-shrink-0 rounded-full"
                :class="statusColors.bubble"
              />
              <span
                :class="statusColors.text"
                class="text-sm font-medium leading-4"
              >
                {{ statusText }}
              </span>
            </div>
            <div
              v-if="statusText && isOnChatwootCloud"
              class="h-3 w-px bg-outline-variant/40"
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
              class="flex-shrink-0 hover:!no-underline"
              @click="addCustomDomainDialogRef.dialogRef.open()"
            />
            <div
              v-if="isOnChatwootCloud"
              class="h-3 w-px bg-outline-variant/40"
            />
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
  </section>
</template>
