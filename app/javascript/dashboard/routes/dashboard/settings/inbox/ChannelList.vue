<template>
  <div class="wizard-body small-12 medium-9 columns height-auto">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.AUTH.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.AUTH.DESC')"
    />
    <div class="row channels">
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
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader';
import { mapGetters } from 'vuex';

export default {
  components: {
    ChannelItem,
    PageHeader,
  },
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
        { key: 'facebook', name: 'Facebook' },
        { key: 'twitter', name: 'Twitter' },
        { key: 'whatsapp', name: 'WhatsApp via Twilio' },
        { key: 'sms', name: 'SMS via Twilio' },
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
      const params = {
        page: 'new',
        sub_page: channel,
      };
      router.push({ name: 'settings_inboxes_page_channel', params });
    },
  },
};
</script>
<style scoped>
.height-auto {
  height: auto;
}
</style>
