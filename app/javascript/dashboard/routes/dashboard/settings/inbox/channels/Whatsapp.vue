<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const store = useStore();

const PROVIDER_TYPES = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
  WHATSAPP_CLOUD: 'whatsapp_cloud',
  WHATSAPP_EMBEDDED: 'whatsapp_embedded',
  THREE_SIXTY_DIALOG: '360dialog',
};

const hasWhatsappAppId = computed(() => {
  return (
    window.chatwootConfig?.whatsappAppId &&
    window.chatwootConfig.whatsappAppId !== 'none'
  );
});

const isWhatsappEmbeddedSignupEnabled = computed(() => {
  const accountId = route.params.accountId;
  return store.getters['accounts/isFeatureEnabledonAccount'](
    accountId,
    FEATURE_FLAGS.WHATSAPP_EMBEDDED_SIGNUP
  );
});

const selectedProvider = computed(() => route.query.provider);

const showProviderSelection = computed(() => !selectedProvider.value);

const showConfiguration = computed(() => Boolean(selectedProvider.value));

const availableProviders = computed(() => [
  {
    key: PROVIDER_TYPES.WHATSAPP,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'),
    icon: 'i-woot-whatsapp',
  },
  {
    key: PROVIDER_TYPES.TWILIO,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
    icon: 'i-woot-twilio',
  },
]);

const selectProvider = providerValue => {
  router.push({
    name: route.name,
    params: route.params,
    query: { provider: providerValue },
  });
};

const shouldShowEmbeddedSignup = provider => {
  // Check if the feature is enabled for the account
  if (!isWhatsappEmbeddedSignupEnabled.value) {
    return false;
  }

  return (
    (provider === PROVIDER_TYPES.WHATSAPP && hasWhatsappAppId.value) ||
    provider === PROVIDER_TYPES.WHATSAPP_EMBEDDED
  );
};

const shouldShowCloudWhatsapp = provider => {
  // If embedded signup feature is enabled and app ID is configured, don't show cloud whatsapp
  if (isWhatsappEmbeddedSignupEnabled.value && hasWhatsappAppId.value) {
    return false;
  }

  // Show cloud whatsapp when:
  // 1. Provider is whatsapp AND
  // 2. Either no app ID is configured OR embedded signup feature is disabled
  return provider === PROVIDER_TYPES.WHATSAPP;
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div v-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <div class="flex gap-6 justify-start">
        <ChannelSelector
          v-for="provider in availableProviders"
          :key="provider.key"
          :title="provider.title"
          :description="provider.description"
          :icon="provider.icon"
          @click="selectProvider(provider.key)"
        />
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <WhatsappEmbeddedSignup
        v-if="shouldShowEmbeddedSignup(selectedProvider)"
      />
      <CloudWhatsapp v-else-if="shouldShowCloudWhatsapp(selectedProvider)" />
      <Twilio
        v-else-if="selectedProvider === PROVIDER_TYPES.TWILIO"
        type="whatsapp"
      />
      <ThreeSixtyDialogWhatsapp
        v-else-if="selectedProvider === PROVIDER_TYPES.THREE_SIXTY_DIALOG"
      />
      <CloudWhatsapp v-else />
    </div>
  </div>
</template>
