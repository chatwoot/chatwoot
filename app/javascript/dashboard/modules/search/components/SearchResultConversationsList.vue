<script setup>
import { defineProps, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import SearchResultSection from './SearchResultSection.vue';
import SearchResultConversationItem from './SearchResultConversationItem.vue';

const props = defineProps({
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

const conversationsWithSubject = computed(() => {
  return props.conversations.map(conversation => ({
    ...conversation,
    mail_subject: conversation.additional_attributes?.mail_subject || '',
  }));
});
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
      <li
        v-for="conversation in conversationsWithSubject"
        :key="conversation.id"
      >
        <SearchResultConversationItem
          :id="conversation.id"
          :name="conversation.contact.name"
          :email="conversation.contact.email"
          :account-id="accountId"
          :inbox="conversation.inbox"
          :created-at="conversation.created_at"
          :email-subject="conversation.mail_subject"
        />
      </li>
    </ul>
  </SearchResultSection>
</template>
