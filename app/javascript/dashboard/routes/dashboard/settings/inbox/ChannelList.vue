<script>
import ChannelItem from 'dashboard/components/widgets/ChannelItem.vue';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';
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
        { key: 'instagram', name: 'Instagram' },
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
      this.enabledFeatures = this.account.features;
    },
    initChannelAuth(channel) {
      const params = {
        sub_page: channel,
        accountId: this.accountId,
      };
      router.push({ name: 'settings_inboxes_page_channel', params });
    },
  },
};
</script>

<template>
  <div
    class="w-full h-full col-span-6 p-6 overflow-auto border border-b-0 rounded-t-lg border-n-weak bg-n-solid-1"
  >
    <PageHeader
      class="max-w-4xl"
      :header-title="$t('INBOX_MGMT.ADD.AUTH.TITLE')"
      :header-content="
        useInstallationName(
          $t('INBOX_MGMT.ADD.AUTH.DESC'),
          globalConfig.installationName
        )
      "
    />
    <div
      class="grid max-w-3xl grid-cols-2 mx-0 mt-6 sm:grid-cols-3 lg:grid-cols-4"
    >
      <ChannelItem
        v-for="channel in channelList"
        :key="channel.key"
        :channel="channel"
        :enabled-features="enabledFeatures"
        @channel-item-click="initChannelAuth"
      />
    </div>
  </div>
</template>
