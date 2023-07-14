<template>
  <div class="wizard-body small-12 medium-9 columns height-auto">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.AUTH.TITLE')"
      :header-content="
        useInstallationName(
          $t('INBOX_MGMT.ADD.AUTH.DESC'),
          globalConfig.installationName
        )
      "
    />
    <div class="row channel-list">
      <channel-item
        v-for="channel in channelList"
        :key="channel.key"
        :channel="channel"
        :enabled-features="enabledFeatures"
        @channel-item-click="initChannelAuth"
      />
    </div>
  </div>
</template>

<script>
import ChannelItem from 'dashboard/components/widgets/ChannelItem';
import PageHeader from '../SettingsSubPageHeader';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    ChannelItem,
    PageHeader,
  },
  mixins: [globalConfigMixin],
  data() {
    return {
      enabledFeatures: {},
    };
  },
  computed: {
    account() {
      return this.$store.getters['accounts/getAccount'](this.accountId);
    },
    channelList() {
      const { apiChannelName, apiChannelThumbnail } = this.globalConfig;
      return [
        { key: 'website', name: 'Website' },
        { key: 'facebook', name: 'Messenger' },
        { key: 'whatsapp', name: 'WhatsApp' },
        { key: 'sms', name: 'SMS' },
        { key: 'email', name: 'Email' },
        {
          key: 'api',
          name: apiChannelName || 'API',
          thumbnail: apiChannelThumbnail,
        },
        { key: 'telegram', name: 'Telegram' },
        { key: 'line', name: 'Line' },
      ];
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    this.initializeEnabledFeatures();
  },
  methods: {
    async initializeEnabledFeatures() {
      await this.$store.dispatch('accounts/get', this.accountId);
      this.enabledFeatures = this.account.features;
    },
    initChannelAuth(channel) {
      let query = {};
      const isWhatsappChannel = channel === 'whatsapp';
      const params = {
        page: 'new',
        sub_page: channel,
      };
      if (isWhatsappChannel) {
        query = {
          provider_type: 'whatsapp_cloud',
        };
      }
      this.$router.push({
        name: 'settings_inboxes_page_channel',
        params,
        query,
      });
    },
  },
};
</script>
<style scoped>
.height-auto {
  height: auto;
}

.channel-list {
  margin-top: var(--space-medium);
}
</style>
