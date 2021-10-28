<template>
  <div class="conversation--container">
    <div class="conversation-wrap" :class="{ 'is-typing': isAgentTyping }">
      <div v-if="isFetchingMessages" class="message--loader">
        <spinner />
      </div>
      <div
        v-for="groupedMessage in groupedMessages"
        :key="groupedMessage.date"
        class="messages-wrap"
      >
        <date-separator :date="groupedMessage.date"></date-separator>
        <chat-message
          v-for="message in groupedMessage.messages"
          :key="message.id"
          :message="message"
        />
      </div>
      <agent-typing-bubble v-if="isAgentTyping" />
    </div>
  </div>
</template>

<script>
import ChatMessage from 'widget/components/ChatMessage.vue';
import AgentTypingBubble from 'widget/components/AgentTypingBubble.vue';
import DateSeparator from 'shared/components/DateSeparator.vue';
import Spinner from 'shared/components/Spinner.vue';
import { mapActions, mapGetters } from 'vuex';

export default {
  name: 'ConversationWrap',
  components: {
    ChatMessage,
    AgentTypingBubble,
    DateSeparator,
    Spinner,
  },
  props: {
    groupedMessages: {
      type: Array,
      default: () => [],
    },
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      previousScrollHeight: 0,
      previousConversationSize: 0,
    };
  },
  computed: {
    ...mapGetters({
      isFetchingMessagesIn: 'conversationV2/isFetchingMessagesIn',
      firstMessageIn: 'conversationV2/firstMessageIn',
      isAllMessagesFetchedIn: 'conversationV2/isAllMessagesFetchedIn',
      totalMessagesSizeIn: 'conversationV2/allMessagesCountIn',
      isAgentTypingIn: 'conversationV2/isAgentTypingIn',
    }),
    firstMessage() {
      return this.firstMessageIn(this.conversationId);
    },
    isAgentTyping() {
      return this.isAgentTypingIn(this.conversationId);
    },
    totalMessagesSize() {
      return this.totalMessagesSizeIn(this.conversationId);
    },
    isAllMessagesFetched() {
      return this.isAllMessagesFetchedIn(this.conversationId);
    },
    isFetchingMessages() {
      return this.isFetchingMessagesIn(this.conversationId);
    },
  },
  watch: {
    isAllMessagesFetched() {
      this.previousScrollHeight = 0;
    },
  },
  mounted() {
    this.$el.addEventListener('scroll', this.handleScroll);
    this.handleScroll();
    this.scrollToBottom();
  },
  updated() {
    if (this.previousConversationSize !== this.totalMessagesSize) {
      this.previousConversationSize = this.totalMessagesSize;
      this.scrollToBottom();
    }
  },
  unmounted() {
    this.$el.removeEventListener('scroll', this.handleScroll);
  },
  methods: {
    ...mapActions('conversationV2', ['fetchOldMessagesIn']),
    scrollToBottom() {
      const container = this.$el;
      container.scrollTop = container.scrollHeight - this.previousScrollHeight;
      this.previousScrollHeight = 0;
    },
    handleScroll() {
      if (
        this.isFetchingMessages ||
        this.isAllMessagesFetched ||
        !this.totalMessagesSize
      ) {
        return;
      }

      if (this.$el.scrollTop < 100) {
        const [conversationId, beforeId] = [
          this.conversationId,
          this.firstMessage.id,
        ];
        this.fetchOldMessagesIn({ conversationId, beforeId });
        this.previousScrollHeight = this.$el.scrollHeight;
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.conversation--container {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow-y: auto;
}

.conversation-wrap {
  @apply relative;
  flex: 1;
  padding: $space-large $space-small $space-small $space-small;
}

.message--loader {
  @apply sticky;
  @apply top-2;
  @apply left-0 right-0;
  @apply text-center;
  @apply z-10;

  &::v-deep .spinner {
    @apply w-8;
    @apply h-8;
    @apply p-0;
    @apply rounded-full;
    @apply bg-white;
    @apply shadow-md;
  }
}
</style>
<style lang="scss">
.conversation-wrap.is-typing .messages-wrap div:last-child {
  .agent-message {
    .agent-name {
      display: none;
    }
    .user-thumbnail-box {
      margin-top: 0;
    }
  }
}
</style>
