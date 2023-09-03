<template>
  <div class="conversation--container" :class="colorSchemeClass">
    <div class="conversation-wrap" :class="{ 'is-typing': isAgentTyping }">
      <div v-if="isFetchingList" class="message--loader">
        <spinner />
      </div>
      <div
        v-for="groupedMessage in groupedMessages"
        :key="groupedMessage.date"
        class="messages-wrap"
      >
        <date-separator :date="groupedMessage.date" />
        <chat-message
          v-for="message in groupedMessage.messages"
          :key="message.id"
          :message="message"
        />
      </div>
      <agent-typing-bubble v-if="showStatusIndicator" />
    </div>
  </div>
</template>

<script>
import ChatMessage from 'widget/components/ChatMessage.vue';
import AgentTypingBubble from 'widget/components/AgentTypingBubble.vue';
import DateSeparator from 'shared/components/DateSeparator.vue';
import Spinner from 'shared/components/Spinner.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import { MESSAGE_TYPE } from 'shared/constants/messages';
import { mapActions, mapGetters } from 'vuex';

export default {
  name: 'ConversationWrap',
  components: {
    ChatMessage,
    AgentTypingBubble,
    DateSeparator,
    Spinner,
  },
  mixins: [darkModeMixin],
  props: {
    groupedMessages: {
      type: Array,
      default: () => [],
    },
    conversationId: {
      type: Number,
      default: undefined,
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
      firstMessageIn: 'conversationV3/firstMessageIn',
      lastMessageIn: 'conversationV3/lastMessageIn',
      isAllMessagesFetchedIn: 'conversationV3/isAllMessagesFetchedIn',
      isFetchingMessagesIn: 'conversationV3/isFetchingMessagesIn',
      allMessagesCountIn: 'conversationV3/allMessagesCountIn',
      isAgentTypingIn: 'conversationV3/isAgentTypingIn',
      conversationAttributes: 'conversationAttributes/getConversationParams',
    }),
    earliestMessage() {
      return this.firstMessageIn(this.conversationId);
    },
    lastMessage() {
      return this.lastMessageIn(this.conversationId);
    },
    allMessagesLoaded() {
      return this.isAllMessagesFetchedIn(this.conversationId);
    },
    isFetchingList() {
      return this.isFetchingMessagesIn(this.conversationId);
    },
    isAgentTyping() {
      return this.isAgentTypingIn(this.conversationId);
    },
    conversationSize() {
      return this.allMessagesCountIn(this.conversationId);
    },
    colorSchemeClass() {
      return `${this.darkMode === 'dark' ? 'dark-scheme' : 'light-scheme'}`;
    },
    showStatusIndicator() {
      const { status } = this.conversationAttributes;
      const isConversationInPendingStatus = status === 'pending';
      const isLastMessageIncoming =
        this.lastMessage.message_type === MESSAGE_TYPE.INCOMING;
      return (
        this.isAgentTyping ||
        (isConversationInPendingStatus && isLastMessageIncoming)
      );
    },
  },
  watch: {
    allMessagesLoaded() {
      this.previousScrollHeight = 0;
    },
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
        this.isFetchingList ||
        this.allMessagesLoaded ||
        !this.conversationSize
      ) {
        return;
      }

      if (this.$el.scrollTop < 100) {
        this.fetchOldConversations({ before: this.earliestMessage.id });
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
  color-scheme: light dark;

  &.light-scheme {
    color-scheme: light;
  }
  &.dark-scheme {
    color-scheme: dark;
  }
}

.conversation-wrap {
  flex: 1;
  padding: $space-large $space-small $space-small $space-small;
}

.message--loader {
  text-align: center;
}
</style>
