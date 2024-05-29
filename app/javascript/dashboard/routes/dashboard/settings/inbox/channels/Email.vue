<template>
  <div
    v-if="!provider"
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full md:w-full max-w-full md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <page-header
      class="max-w-4xl"
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_PROVIDER.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_PROVIDER.DESCRIPTION')"
    />
    <div class="grid grid-cols-4 max-w-3xl mx-0 mt-6">
      <channel-selector
        v-for="emailProvider in emailProviderList"
        :key="emailProvider.key"
        :class="{ inactive: !emailProvider.isEnabled }"
        :title="emailProvider.title"
        :src="emailProvider.src"
        @click="() => onClick(emailProvider)"
      />
    </div>
  </div>
  <microsoft v-else-if="provider === 'microsoft'" />
  <forward-to-option v-else-if="provider === 'other_provider'" />
</template>
<script>
import ForwardToOption from './emailChannels/ForwardToOption.vue';
import Microsoft from './emailChannels/Microsoft.vue';
import { mapGetters } from 'vuex';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import PageHeader from '../../SettingsSubPageHeader.vue';

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
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      isAChatwootInstance: 'globalConfig/isAChatwootInstance',
    }),
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
      ].filter(provider => {
        if (this.isAChatwootInstance) {
          return true;
        }
        return provider.isEnabled;
      });
    },
  },
  methods: {
    onClick(emailProvider) {
      if (emailProvider.isEnabled) {
        this.provider = emailProvider.key;
      }
    },
  },
};
</script>
