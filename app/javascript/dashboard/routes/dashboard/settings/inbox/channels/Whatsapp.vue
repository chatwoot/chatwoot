<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
    WhatsappEmbeddedSignup,
  },
  data() {
    return {
      provider: 'whatsapp_cloud',
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
      const providers = [];

      if (this.hasWhatsappAppId) {
        providers.push({
          value: 'whatsapp_embedded',
          label: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_EMBEDDED'),
        });
      } else {
        providers.push({
          value: 'whatsapp_cloud',
          label: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
        });
      }

      providers.push({
        value: 'twilio',
        label: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
      });

      return providers;
    },
  },
  mounted() {
    // Set the appropriate default provider based on configuration
    this.provider = this.hasWhatsappAppId
      ? 'whatsapp_embedded'
      : 'whatsapp_cloud';
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <div class="flex-shrink-0 flex-grow-0">
      <label>
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option
            v-for="providerOption in availableProviders"
            :key="providerOption.value"
            :value="providerOption.value"
          >
            {{ providerOption.label }}
          </option>
        </select>
      </label>
    </div>

    <WhatsappEmbeddedSignup v-if="provider === 'whatsapp_embedded'" />
    <Twilio v-else-if="provider === 'twilio'" type="whatsapp" />
    <ThreeSixtyDialogWhatsapp v-else-if="provider === '360dialog'" />
    <CloudWhatsapp v-else />
  </div>
</template>
