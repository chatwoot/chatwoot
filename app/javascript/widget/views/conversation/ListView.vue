<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-slate-50">
    <chat-header-expanded />
    <div class="flex-1 p-3">
      <div class="w-full shadow  bg-white rounded py-4">
        <conversation-card-item
          v-for="conversation in sortedConversations"
          :key="conversation.id"
          :conversation="conversation"
          @click="toggleConversationView"
        />
      </div>
    </div>
    <div class="footer-wrap">
      <team-availability
        :available-agents="availableAgents"
        @start-conversation="toggleConversationView"
      />
      <branding></branding>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Branding from 'widget/components/Branding.vue';
import TeamAvailability from 'widget/components/TeamAvailability';
import ConversationCardItem from 'widget/components/conversation/ConversationCardItem.vue';
import ChatHeaderExpanded from 'widget/components/header/ChatHeaderExpanded.vue';

export default {
  components: {
    Branding,
    TeamAvailability,
    ConversationCardItem,
    ChatHeaderExpanded,
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      sortedConversations: 'conversations/sortedConversations',
    }),
  },
  methods: {
    toggleConversationView(conversationId) {
      this.$emit('toggle-conversation-view', conversationId);
    },
  },
};
</script>
