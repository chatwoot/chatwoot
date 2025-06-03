<script setup>
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import SearchResultConversationItem from './SearchResultConversationItem.vue';
import SearchResultSection from './SearchResultSection.vue';
import MessageContent from './MessageContent.vue';

defineProps({
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
});
const { t } = useI18n();

const accountId = useMapGetter('getCurrentAccountId');

const getName = message => {
  return message && message.sender && message.sender.name
    ? message.sender.name
    : t('SEARCH.BOT_LABEL');
};
</script>

<template>
  <SearchResultSection
    :title="$t('SEARCH.SECTION.MESSAGES')"
    :empty="!messages.length"
    :query="query"
    :show-title="showTitle"
    :is-fetching="isFetching"
  >
    <ul v-if="messages.length" class="space-y-1.5 list-none">
      <li v-for="message in messages" :key="message.id">
        <SearchResultConversationItem
          :id="message.conversation_id"
          :account-id="accountId"
          :inbox="message.inbox"
          :created-at="message.created_at"
          :message-id="message.id"
        >
          <MessageContent
            :author="getName(message)"
            :content="message.content"
            :search-term="query"
          />
        </SearchResultConversationItem>
      </li>
    </ul>
  </SearchResultSection>
</template>
