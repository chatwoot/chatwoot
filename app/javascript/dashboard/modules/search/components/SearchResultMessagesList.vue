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
    <table-footer
      v-if="messages.length && totalPages > 1"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      class="mt-4"
      @page-change="onPageChange"
    />
  </search-result-section>
</template>

<script>
import { mapGetters } from 'vuex';
import SearchResultConversationItem from './SearchResultConversationItem.vue';
import SearchResultSection from './SearchResultSection.vue';
import MessageContent from './MessageContent.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';

const PAGE_SIZE = 15;

export default {
  components: {
    SearchResultConversationItem,
    SearchResultSection,
    MessageContent,
    TableFooter,
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
    currentPage: {
      type: Number,
      default: 1,
    },
    totalCount: {
      type: Number,
      default: 0,
    },
    totalPages: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    pageSize() {
      return PAGE_SIZE;
    },
  },
  methods: {
    getName(message) {
      return message && message.sender && message.sender.name
        ? message.sender.name
        : this.$t('SEARCH.BOT_LABEL');
    },
    onPageChange(page) {
      this.$emit('page-change', page);
    },
  },
};
</script>
