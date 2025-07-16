<script>
import TeamAvailability from 'widget/components/TeamAvailability.vue';
import { mapGetters, mapActions } from 'vuex';
import routerMixin from 'widget/mixins/routerMixin';
import configMixin from 'widget/mixins/configMixin';
import ArticleContainer from '../components/pageComponents/Home/Article/ArticleContainer.vue';
export default {
  name: 'Home',
  components: {
    ArticleContainer,
    TeamAvailability,
  },
  mixins: [configMixin, routerMixin],
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationSize: 'conversation/getConversationSize',
      conversationAttributes: 'conversationAttributes/getConversationParams',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
    }),
    isConversationResolved() {
      return this.conversationAttributes?.status === 'resolved';
    },
    hasActiveConversation() {
      const { allowMessagesAfterResolved } = window.chatwootWebChannel || {};
      return (
        !!this.conversationSize &&
        (allowMessagesAfterResolved || !this.isConversationResolved)
      );
    },
    shouldShowPreChatForm() {
      return this.preChatFormEnabled && !this.hasActiveConversation;
    },
  },
  methods: {
    ...mapActions('conversation', ['clearConversations']),
    ...mapActions('conversationAttributes', ['clearConversationAttributes']),
    startConversation() {
      if (this.hasActiveConversation) {
        return this.replaceRoute('messages');
      }
      this.clearConversations();
      this.clearConversationAttributes();
      const nextRoute = this.shouldShowPreChatForm
        ? 'prechat-form'
        : 'messages';
      return this.replaceRoute(nextRoute);
    },
  },
};
</script>

<template>
  <div class="z-50 flex flex-col justify-end flex-1 w-full p-4 gap-4">
    <TeamAvailability
      :available-agents="availableAgents"
      :has-conversation="hasActiveConversation"
      :unread-count="unreadMessageCount"
      @start-conversation="startConversation"
    />

    <ArticleContainer />
  </div>
</template>
