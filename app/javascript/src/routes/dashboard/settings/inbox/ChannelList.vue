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
      />
    </div>
  </div>
</template>

<script>
/* global bus */
import ChannelItem from '../../../../components/widgets/ChannelItem';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader';

export default {
  components: {
    ChannelItem,
    PageHeader,
  },
  data() {
    return {
      channelList: ['facebook', 'email', 'twitter', 'telegram', 'line'],
    };
  },
  created() {
    bus.$on('channelItemClick', channel => {
      this.initChannelAuth(channel);
    });
  },
  methods: {
    initChannelAuth(channel) {
      if (channel === 'facebook') {
        router.push({
          name: 'settings_inboxes_page_channel',
          params: { page: 'new', sub_page: 'facebook' },
        });
      } else if (channel === 'email') {
        router.push({
          name: 'settings_inboxes_page_channel',
          params: { page: 'new', sub_page: 'email' },
        });
      }
    },
  },
};
</script>
