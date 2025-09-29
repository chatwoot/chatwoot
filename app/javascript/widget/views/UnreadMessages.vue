<template>
  <ai-nudge
    v-if="hasAINudgeMessages"
    :message="aiNudgeMessage"
    @close="closeFullView"
  />
  <unread-message-list v-else :messages="messages" @close="closeFullView" />
</template>

<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';
import UnreadMessageList from '../components/UnreadMessageList.vue';
import AiNudge from '../components/AINudge.vue';

export default {
  name: 'UnreadMessages',
  components: {
    UnreadMessageList,
    AiNudge,
  },
  computed: {
    ...mapGetters({
      messages: 'conversation/getUnreadMessagesForDisplay',
      hasAINudgeMessages: 'conversation/hasAINudgeMessages',
    }),
    aiNudgeMessage() {
      // Get the last AI nudge message to display
      const aiNudgeMessages =
        this.$store.getters['conversation/getAINudgeMessages'];
      return aiNudgeMessages.length > 0
        ? aiNudgeMessages[aiNudgeMessages.length - 1]
        : null;
    },
  },
  methods: {
    closeFullView() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'toggleBubble' });
      }
    },
  },
};
</script>
