<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';

export default {
  components: { ChatFooter, ConversationWrap },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      isWidgetOpen: 'appConfig/getIsWidgetOpen',
    }),
    isVisible() {
      return this.isWidgetOpen || !IFrameHelper.isIFrame();
    },
  },
  watch: {
    // The thread can be on screen before the widget is opened; it is seen once it is visible.
    isVisible: {
      immediate: true,
      handler(isVisible) {
        if (isVisible) this.$store.dispatch('conversation/setUserLastSeen');
      },
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 overflow-hidden rounded-b-lg bg-n-surface-1">
    <div class="flex flex-1 overflow-auto">
      <ConversationWrap :grouped-messages="groupedMessages" />
    </div>
    <ChatFooter class="px-5" />
  </div>
</template>
