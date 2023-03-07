<template>
  <search-result-section
    :title="$t('SEARCH.SECTION.CONVERSATIONS')"
    :empty="!conversations.length"
    :query="query"
  >
    <ul class="search-list">
      <li v-for="conversation in conversations" :key="conversation.id">
        <search-result-conversation-item
          :id="conversation.id"
          :name="conversation.contact.name"
          :account-id="accountId"
          :inbox="conversation.inbox"
          :created-at="conversation.created_at"
        />
      </li>
    </ul>
  </search-result-section>
</template>

<script>
import { mapGetters } from 'vuex';
import SearchResultSection from './SearchResultSection.vue';
import SearchResultConversationItem from './SearchResultConversationItem.vue';

export default {
  components: {
    SearchResultSection,
    SearchResultConversationItem,
  },
  props: {
    conversations: {
      type: Array,
      default: () => [],
    },
    query: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
};
</script>
