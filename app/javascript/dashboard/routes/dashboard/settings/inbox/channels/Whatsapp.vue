<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import whatsappIcon from 'dashboard/assets/images/whatsapp.png';
import twilioIcon from 'dashboard/assets/images/twilio.png';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

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

const selectedProvider = computed(() => route.query.provider);

const showProviderSelection = computed(() => !selectedProvider.value);

const showConfiguration = computed(() => Boolean(selectedProvider.value));

const availableProviders = computed(() => [
  {
    value: PROVIDER_TYPES.WHATSAPP,
    label: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'),
    icon: whatsappIcon,
  },
  {
    value: PROVIDER_TYPES.TWILIO,
    label: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
    icon: twilioIcon,
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
  return (
    (provider === PROVIDER_TYPES.WHATSAPP && hasWhatsappAppId.value) ||
    provider === PROVIDER_TYPES.WHATSAPP_EMBEDDED
  );
};

const shouldShowCloudWhatsapp = provider => {
  return provider === PROVIDER_TYPES.WHATSAPP && !hasWhatsappAppId.value;
};
</script>

<template>
  <div
    class="w-full h-full col-span-6 p-6 overflow-auto border border-b-0 rounded-t-lg border-n-weak bg-n-solid-1"
  >
    <!-- Provider Selection View -->
    <div v-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <!-- Dynamic Provider Cards -->
      <div class="flex justify-start gap-6">
        <div
          v-for="provider in availableProviders"
          :key="provider.value"
          class="gap-6 px-5 py-6 transition-all duration-200 border cursor-pointer w-96 border-n-weak rounded-2xl hover:bg-n-slate-3"
          @click="selectProvider(provider.value)"
        >
          <!-- Provider Icon -->
          <div class="flex justify-start mb-5">
            <div class="flex items-center justify-center w-12 h-12 rounded-lg">
              <img
                :src="provider.icon"
                :alt="provider.label"
                class="object-contain w-10 h-10"
              />
            </div>
          </div>

          <!-- Card Content -->
          <div class="text-left">
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

    <!-- Configuration View -->
    <div v-else-if="showConfiguration">
      <div class="py-5 px-6 border bg-n-solid-2 border-n-weak rounded-2xl">
        <!-- Provider Configuration Forms -->
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
