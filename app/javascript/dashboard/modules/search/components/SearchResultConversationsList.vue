<script setup>
import { useMapGetter } from 'dashboard/composables/store.js';
import SearchResultSection from './SearchResultSection.vue';
import SearchResultConversationItem from './SearchResultConversationItem.vue';

defineProps({
  conversations: {
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
});

const accountId = useMapGetter('getCurrentAccountId');
</script>

<template>
  <SearchResultSection
    :title="$t('SEARCH.SECTION.CONVERSATIONS')"
    :empty="!conversations.length"
    :query="query"
    :show-title="showTitle"
    :is-fetching="isFetching"
  >
    <ul v-if="conversations.length" class="space-y-1.5 list-none">
      <li v-for="conversation in conversations" :key="conversation.id">
        <SearchResultConversationItem
          :id="conversation.id"
          :name="conversation.contact.name"
          :email="conversation.contact.email"
          :account-id="accountId"
          :inbox="conversation.inbox"
          :created-at="conversation.created_at"
        />
      </li>
    </ul>
  </SearchResultSection>
</template>
