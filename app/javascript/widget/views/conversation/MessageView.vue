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
import { mapActions, mapGetters } from 'vuex';
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
  props: {
    conversationId: {
      type: Number,
      default: -1,
    },
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      sortedConversations: 'conversations/sortedConversations',
      earliestMessage: 'conversation/getEarliestMessage',
    }),
    ...mapActions('conversation', ['fetchOldMessages']),
    groupedMessages() {
      if (this.conversationId > 0) {
        return this.$store.getters['conversation/getGroupedConversation'](
          this.conversationId
        );
      }
      return [];
    },
    unGroupedMessages() {
      if (this.conversationId > 0) {
        return this.$store.getters['conversation/getMessages'](
          this.conversationId
        );
      }
      return [];
    },
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
  mounted() {
    if (this.unGroupedMessages.length === 1) {
      this.fetchOldMessages({
        before: this.earliestMessage.id,
        conversationId: this.conversationId,
      });
    }
  },
  beforeDestroy() {
    console.log('destroyed');
  },
  methods: {
    toggleConversationView(conversationId) {
      this.$emit('toggle-conversation-view', conversationId);
    },
  },
};
</script>
