<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.AUTH.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.AUTH.DESC')"
    />
    <div class="row channels">
      <channel-item
        v-for="channel in channelList"
        :key="channel"
        :channel="channel"
        @channel-item-click="initChannelAuth"
      />
    </div>
  </div>
</template>

<script>
import ChannelItem from 'dashboard/components/widgets/ChannelItem';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader';

export default {
  components: {
    ChannelItem,
    PageHeader,
  },
  data() {
    return {
      channelList: [
        'website',
        'facebook',
        'twitter',
        'twilio',
        'telegram',
        'line',
      ],
    };
  },
  methods: {
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
