<script>
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import router from '../../../../index';

// Using direct paths instead of imports
// import whatsappIcon from 'dashboard/assets/images/whatsapp.png';
// import twilioIcon from 'dashboard/assets/images/twilio.png';

export default {
  components: {
    Twilio,
    ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
    WhatsappEmbeddedSignup,
  },
  data() {
    return {
      // No default provider selected
      provider: null,
    };
  },
  computed: {
    hasWhatsappAppId() {
      return (
        window.chatwootConfig?.whatsappAppId &&
        window.chatwootConfig.whatsappAppId !== 'none'
      );
    },
    availableProviders() {
      return [
        {
          value: 'whatsapp',
          label: 'WhatsApp',
        },
        {
          value: 'twilio',
          label: 'Twilio',
        },
      ];
    },
    selectedProvider() {
      return this.$route.query.provider;
    },
    showProviderSelection() {
      return !this.selectedProvider;
    },
    showConfiguration() {
      return !!this.selectedProvider;
    },
    configurationTitle() {
      const providerTitles = {
        whatsapp: this.hasWhatsappAppId
          ? this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_EMBEDDED')
          : this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
        whatsapp_cloud: this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'
        ),
        whatsapp_embedded: this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_EMBEDDED'
        ),
        twilio: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
      };
      return `${providerTitles[this.selectedProvider]} ${this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.TITLE'
      )}`;
    },
    configurationDescription() {
      const descriptions = {
        whatsapp: this.hasWhatsappAppId
          ? "Quick setup with Meta's embedded signup."
          : 'Configure WhatsApp integration through Meta.',
        whatsapp_cloud: 'Configure WhatsApp integration through Meta.',
        whatsapp_embedded: "Quick setup with Meta's embedded signup.",
        twilio: 'Configure WhatsApp integration through your Twilio account.',
      };
      return descriptions[this.selectedProvider] || '';
    },
  },
  methods: {
    selectProvider(providerValue) {
      // Directly navigate to configuration when provider is clicked
      router.push({
        name: this.$route.name,
        params: this.$route.params,
        query: { provider: providerValue },
      });
    },
    goBackToProviderSelection() {
      router.push({
        name: this.$route.name,
        params: this.$route.params,
        query: {},
      });
    },
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <!-- Provider Selection View -->
    <div v-if="showProviderSelection">
      <!-- Title and Description -->
      <div class="text-left mb-12">
        <h1 class="text-lg font-medium text-slate-800 dark:text-slate-100 mb-2">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <!-- Provider Cards -->
      <div class="flex gap-8 justify-start">
        <!-- WhatsApp Cloud Card -->
        <div
          class="w-96 bg-n-solid-2 border border-n-weak rounded-2xl p-8 cursor-pointer transition-all duration-200 hover:border-woot-500 hover:bg-n-solid-3"
          @click="selectProvider('whatsapp')"
        >
          <!-- WhatsApp Icon -->
          <div class="flex justify-start mb-8">
            <div class="w-12 h-12 rounded-lg flex items-center justify-center">
              <img
                src="dashboard/assets/images/whatsapp.png"
                :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD')"
                class="w-10 h-10 object-contain"
              />
            </div>
          </div>

          <!-- Card Content -->
          <div class="text-left">
            <h3
              class="text-sm font-medium text-slate-800 dark:text-slate-100 mb-1.5"
            >
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
            </h3>
            <p class="text-sm text-slate-600 dark:text-slate-300">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC') }}
            </p>
          </div>
        </div>

        <!-- Twilio Card -->
        <div
          class="w-96 bg-n-solid-2 border border-n-weak rounded-2xl p-8 cursor-pointer transition-all duration-200 hover:border-woot-500 hover:bg-n-solid-3"
          @click="selectProvider('twilio')"
        >
          <!-- Twilio Icon -->
          <div class="flex justify-start mb-8">
            <div class="w-12 h-12 rounded-lg flex items-center justify-center">
              <img
                src="dashboard/assets/images/twilio.png"
                :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO')"
                class="w-10 h-10 object-contain"
              />
            </div>
          </div>
          <!-- Card Content -->
          <div class="text-left">
            <h3
              class="text-sm font-medium text-slate-800 dark:text-slate-100 mb-1.5"
            >
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO') }}
            </h3>
            <p class="text-sm text-slate-600 dark:text-slate-300">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC') }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Configuration View -->
    <div v-else-if="showConfiguration">
      <!-- Back Button -->
      <div class="mb-6">
        <button
          type="button"
          class="inline-flex items-center text-woot-500 hover:text-woot-600 transition-colors"
          @click="goBackToProviderSelection"
        >
          <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path
              fill-rule="evenodd"
              d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z"
              clip-rule="evenodd"
            />
          </svg>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BACK_TO_PROVIDER_SELECTION') }}
        </button>
      </div>

      <!-- Configuration Form Container -->
      <div class="bg-n-solid-2 border border-n-weak rounded-2xl p-8">
        <!-- Provider Configuration Forms -->
        <WhatsappEmbeddedSignup
          v-if="selectedProvider === 'whatsapp' && hasWhatsappAppId"
        />
        <CloudWhatsapp
          v-else-if="selectedProvider === 'whatsapp' && !hasWhatsappAppId"
        />
        <Twilio v-else-if="selectedProvider === 'twilio'" type="whatsapp" />
        <ThreeSixtyDialogWhatsapp
          v-else-if="selectedProvider === '360dialog'"
        />
        <WhatsappEmbeddedSignup
          v-else-if="selectedProvider === 'whatsapp_embedded'"
        />
        <CloudWhatsapp v-else />
      </div>
    </div>
  </div>
</template>
