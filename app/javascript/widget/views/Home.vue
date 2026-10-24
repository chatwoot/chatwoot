<script>
import TeamAvailability from 'widget/components/TeamAvailability.vue';
import { mapGetters } from 'vuex';
import { useRouter } from 'vue-router';
import configMixin from 'widget/mixins/configMixin';
import ArticleContainer from '../components/pageComponents/Home/Article/ArticleContainer.vue';
export default {
  name: 'Home',
  components: {
    ArticleContainer,
    TeamAvailability,
  },
  mixins: [configMixin],
  setup() {
    const router = useRouter();
    return { router };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationSize: 'conversation/getConversationSize',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      latestConversation: 'conversationList/getLatestConversation',
    }),
    hasConversation() {
      if (this.hasMultipleConversationsEnabled) {
        return (
          !!this.latestConversation &&
          this.latestConversation.status !== 'resolved'
        );
      }
      return !!this.conversationSize;
    },
  },
  methods: {
    startConversation() {
      if (this.hasMultipleConversationsEnabled) {
        return this.hasConversation
          ? this.openConversation(this.latestConversation.id)
          : this.startNewConversation();
      }
      if (this.preChatFormEnabled && !this.conversationSize) {
        return this.router.replace({ name: 'prechat-form' });
      }
      return this.router.replace({ name: 'messages' });
    },
    async openConversation(id) {
      await this.$store.dispatch('conversationList/open', id);
      this.router.replace({ name: 'messages' });
    },
    async startNewConversation() {
      await this.$store.dispatch('conversationList/startNew');
      this.router.replace({
        name: this.preChatFormEnabled ? 'prechat-form' : 'messages',
      });
    },
  },
};
</script>

<template>
  <div class="z-50 flex flex-col justify-end flex-1 w-full p-4 gap-4">
    <TeamAvailability
      :available-agents="availableAgents"
      :has-conversation="hasConversation"
      :unread-count="unreadMessageCount"
      @start-conversation="startConversation"
    />

    <ArticleContainer />
  </div>
</template>
