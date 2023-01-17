<template>
  <div
    v-if="!provider"
    class="wizard-body small-12 medium-9 columns height-auto"
  >
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_PROVIDER.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_PROVIDER.DESCRIPTION')"
    />
    <div class="row channel-list">
      <channel-selector
        v-for="emailProvider in emailProviderList"
        :key="emailProvider.key"
        :title="emailProvider.title"
        :src="emailProvider.src"
        @click="() => onClick(emailProvider.key)"
      />
    </div>
  </div>
  <microsoft v-else-if="provider === 'microsoft'" />
  <forward-to-option v-else-if="provider === 'other_provider'" />
</template>
<script>
import ForwardToOption from './emailChannels/ForwardToOption';
import Microsoft from './emailChannels/Microsoft';
import { mapGetters } from 'vuex';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import PageHeader from '../../SettingsSubPageHeader';

export default {
  components: {
    ChannelSelector,
    ForwardToOption,
    Microsoft,
    PageHeader,
  },
  data() {
    return { provider: '' };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    emailProviderList() {
      return [
        {
          title: this.$t('INBOX_MGMT.EMAIL_PROVIDERS.MICROSOFT'),
          isEnabled: !!this.globalConfig.azureAppId,
          key: 'microsoft',
          src: '/assets/images/dashboard/channels/microsoft.png',
        },
        {
          title: this.$t('INBOX_MGMT.EMAIL_PROVIDERS.OTHER_PROVIDERS'),
          isEnabled: true,
          key: 'other_provider',
          src: '/assets/images/dashboard/channels/email.png',
        },
      ].filter(provider => provider.isEnabled);
    },
  },
  methods: {
    onClick(provider) {
      this.provider = provider;
    },
  },
};
</script>

<style scoped>
.channel-list {
  margin-top: var(--space-medium);
}
</style>
