<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-slate-50">
    <chat-header
      :title="channelConfig.websiteName"
      :show-popout-button="showPopoutButton"
      :available-agents="availableAgents"
      @back-button-click="toggleConversationView"
    />
    <conversation-wrap
      :grouped-messages="groupedMessages"
      :conversation-id="conversationId"
    />
    <div class="footer-wrap">
      <div v-if="showInputTextArea" class="px-4">
        <chat-footer />
      </div>
      <branding></branding>
    </div>
  </div>
</template>
<script>
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeader from 'widget/components/header/ChatHeader.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';
import { mapGetters } from 'vuex';
import configMixin from 'widget/mixins/configMixin';
import Branding from 'widget/components/Branding.vue';

export default {
  components: {
    Branding,
    ChatFooter,
    ChatHeader,
    ConversationWrap,
  },
  mixins: [configMixin],
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      sortedConversations: 'conversations/sortedConversations',
    }),
    showInputTextArea() {
      if (this.hideInputForBotConversations) {
        if (this.sortedConversations.open) {
          return true;
        }
        return false;
      }
      return true;
    },
  },
  methods: {
    toggleConversationView(conversationId) {
      this.$emit('toggle-conversation-view', conversationId);
    },
  },
};
</script>
