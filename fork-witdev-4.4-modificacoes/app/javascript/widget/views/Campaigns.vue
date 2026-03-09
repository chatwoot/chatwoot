<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';
import UnreadMessageList from '../components/UnreadMessageList.vue';
import { emitter } from 'shared/helpers/mitt';

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
  methods: {
    closeFullView() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'setCampaignReadOn',
        });
        IFrameHelper.sendMessage({ event: 'toggleBubble' });
        emitter.emit('snooze-campaigns');
      }
    },
  },
};
</script>

<template>
  <UnreadMessageList :messages="messages" @close="closeFullView" />
</template>
