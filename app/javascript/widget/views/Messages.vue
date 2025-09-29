<template>
  <div
    class="flex flex-col flex-1 overflow-hidden rounded-b-lg bg-slate-25 dark:bg-slate-800"
    :style="`--widget-color: ${widgetColor}; --text-color: ${textColor};`"
  >
    <div
      class="flex flex-1 overflow-auto"
      :class="{
        'mb-[70px]': hideReplyBox,
      }"
    >
      <conversation-wrap :grouped-messages="groupedMessages" />
    </div>
    <chat-footer />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  components: { ChatFooter, ConversationWrap },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
      groupedMessages: 'conversation/getFilteredGroupedConversation',
      widgetColor: 'appConfig/getWidgetColor',
    }),
    hideReplyBox() {
      const { allowMessagesAfterResolved } = window.chatwootWebChannel;
      const { status } = this.conversationAttributes;
      return !allowMessagesAfterResolved && status === 'resolved';
    },
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
  mounted() {
    this.$store.dispatch('conversation/setUserLastSeen');
  },
};
</script>
