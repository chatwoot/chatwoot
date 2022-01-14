<template>
  <unread-message-list :messages="messages" />
</template>

<script>
import { mapGetters } from 'vuex';
import UnreadMessageList from '../components/UnreadMessageList.vue';

export default {
  name: 'Campaigns',
  components: {
    UnreadMessageList,
  },
  computed: {
    ...mapGetters({ campaign: 'campaign/getActiveCampaign' }),
    messages() {
      const { sender, id: campaignId, message: content } = this.campaign;
      return [
        {
          content,
          sender,
          campaignId,
        },
      ];
    },
  },
};
</script>
