<template>
  <search-result-section
    :title="$t('SEARCH.SECTION.MESSAGES')"
    :empty="!messages.length"
    :query="query"
    :show-title="showTitle"
    :is-fetching="isFetching"
  >
    <ul v-if="messages.length" class="search-list">
      <li v-for="message in messages" :key="message.id">
        <search-result-conversation-item
          :id="message.conversation_id"
          :account-id="accountId"
          :inbox="message.inbox"
          :created-at="message.created_at"
          :message-id="message.id"
        >
          <message-content
            :author="getName(message)"
            :content="message.content"
            :search-term="query"
          />
        </search-result-conversation-item>
      </li>
    </ul>
  </search-result-section>
</template>

<script>
import { mapGetters } from 'vuex';
import SearchResultConversationItem from './SearchResultConversationItem.vue';
import SearchResultSection from './SearchResultSection.vue';
import MessageContent from './MessageContent.vue';

export default {
  components: {
    SearchResultConversationItem,
    SearchResultSection,
    MessageContent,
  },
  props: {
    messages: {
      type: Array,
      default: () => [],
    },
    query: {
      type: String,
      default: '',
    },
    isFetching: {
      type: Boolean,
      default: false,
    },
    showTitle: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    getName(message) {
      return message && message.sender && message.sender.name
        ? message.sender.name
        : this.$t('SEARCH.BOT_LABEL');
    },
  },
};
</script>
