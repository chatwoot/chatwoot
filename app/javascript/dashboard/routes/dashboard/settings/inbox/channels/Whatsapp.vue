<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
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
    value: PROVIDER_TYPES.WHATSAPP,
    label: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'),
    icon: '/assets/images/dashboard/channels/whatsapp.png',
  },
  {
    value: PROVIDER_TYPES.TWILIO,
    label: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
    icon: '/assets/images/dashboard/channels/twilio.png',
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
  <div
    class="overflow-auto col-span-6 p-6 w-full h-full rounded-t-lg border border-b-0 border-n-weak bg-n-solid-1"
  >
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
        <div
          v-for="provider in availableProviders"
          :key="provider.value"
          class="gap-6 px-5 py-6 w-96 rounded-2xl border transition-all duration-200 cursor-pointer border-n-weak hover:bg-n-slate-3"
          @click="selectProvider(provider.value)"
        >
          <div class="flex justify-start mb-5">
            <div
              class="flex justify-center items-center rounded-full size-10 bg-n-alpha-2"
            >
              <img
                :src="provider.icon"
                :alt="provider.label"
                class="object-contain size-[26px]"
              />
            </div>
          </div>

          <div class="text-start">
            <h3 class="mb-1.5 text-sm font-medium text-slate-12">
              {{ provider.label }}
            </h3>
            <p class="text-sm text-slate-11">
              {{ provider.description }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <div class="px-6 py-5 rounded-2xl border bg-n-solid-2 border-n-weak">
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
  </div>
</template>
