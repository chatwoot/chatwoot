<template>
  <div class="conversation--container">
    <div class="conversation-wrap">
      <div v-if="uiFlags.isFetchingList" class="message--loader">
        <spinner></spinner>
      </div>
      <ChatMessage
        v-for="message in messages"
        :key="message.id"
        :message="message"
      />
    </div>
    <branding></branding>
  </div>
</template>

<script>
import Branding from 'widget/components/Branding.vue';
import ChatMessage from 'widget/components/ChatMessage.vue';
import Spinner from 'shared/components/Spinner.vue';
import { mapActions, mapGetters } from 'vuex';

export default {
  name: 'ConversationWrap',
  components: {
    Branding,
    ChatMessage,
    Spinner,
  },
  props: {
    messages: Object,
  },
  data() {
    return {
      previousScrollHeight: 0,
      previousConversationSize: 0,
    };
  },
  computed: {
    ...mapGetters({
      earliestMessage: 'conversation/getEarliestMessage',
      uiFlags: 'conversation/getUIFlags',
      conversationSize: 'conversation/getConversationSize',
    }),
  },
  mounted() {
    this.$el.addEventListener('scroll', this.handleScroll);
    this.scrollToBottom();
  },
  updated() {
    if (this.previousConversationSize !== this.conversationSize) {
      this.previousConversationSize = this.conversationSize;
      this.scrollToBottom();
    }
  },
  unmounted() {
    this.$el.removeEventListener('scroll', this.handleScroll);
  },
  methods: {
    ...mapActions('conversation', ['fetchOldConversations']),
    scrollToBottom() {
      const container = this.$el;
      container.scrollTop = container.scrollHeight - this.previousScrollHeight;
      this.previousScrollHeight = 0;
    },
    handleScroll() {
      if (
        this.uiFlags.isFetchingList ||
        this.uiFlags.allMessagesLoaded ||
        !this.conversationSize
      ) {
        return;
      }

      if (this.$el.scrollTop < 400) {
        this.fetchOldConversations({ before: this.earliestMessage.id });
      }

      this.previousScrollHeight = this.$el.scrollHeight;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/woot.scss';

.conversation--container {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow-y: auto;
}

.conversation-wrap {
  flex: 1;
  padding: $space-large $space-small $zero $space-small;
}

.message--loader {
  text-align: center;
}
</style>
