<script>
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import router from '../../../../index';

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
    class="w-full h-full col-span-6 p-6 overflow-auto border border-b-0 rounded-t-lg border-n-weak bg-n-solid-1"
  >
    <!-- Provider Selection View -->
    <div v-if="showProviderSelection">
      <!-- Title and Description -->
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <!-- Provider Cards -->
      <div class="flex justify-start gap-6">
        <!-- WhatsApp Cloud Card -->
        <div
          class="gap-6 px-5 py-6 transition-all duration-200 border cursor-pointer w-96 bg-n-solid-2 border-n-weak rounded-2xl hover:border-woot-500 hover:bg-n-solid-3"
          @click="selectProvider('whatsapp')"
        >
          <!-- WhatsApp Icon -->
          <div class="flex justify-start mb-5">
            <div class="flex items-center justify-center w-12 h-12 rounded-lg">
              <img
                src="dashboard/assets/images/whatsapp.png"
                :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD')"
                class="object-contain w-10 h-10"
              />
            </div>
          </div>

          <!-- Card Content -->
          <div class="text-left">
            <h3 class="mb-1.5 text-sm font-medium text-slate-12">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
            </h3>
            <p class="text-sm text-slate-11">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC') }}
            </p>
          </div>
        </div>

        <div
          class="gap-6 px-5 py-6 transition-all duration-200 border cursor-pointer w-96 bg-n-solid-2 border-n-weak rounded-2xl hover:border-woot-500 hover:bg-n-solid-3"
          @click="selectProvider('whatsapp')"
        >
          <!-- WhatsApp Icon -->
          <div class="flex justify-start mb-5">
            <div class="flex items-center justify-center w-12 h-12 rounded-lg">
              <img
                src="dashboard/assets/images/twilio.png"
                :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO')"
                class="object-contain w-10 h-10"
              />
            </div>
          </div>

          <!-- Card Content -->
          <div class="text-left">
            <h3 class="mb-1.5 text-sm font-medium text-slate-12">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO') }}
            </h3>
            <p class="text-sm text-slate-11">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC') }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Configuration View -->
    <div v-else-if="showConfiguration">
      <!-- Configuration Form Container -->
      <div class="p-8 border bg-n-solid-2 border-n-weak rounded-2xl">
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
