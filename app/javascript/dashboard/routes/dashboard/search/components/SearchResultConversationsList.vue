<template>
  <search-result-section
    :title="$t('SEARCH.SECTION.CONVERSATIONS')"
    :empty="!conversations.length"
  >
    <ul class="search-list">
      <li v-for="conversation in conversations" :key="conversation.id">
        <search-result-conversation-item :conversation="conversation" />
      </li>
    </ul>
  </search-result-section>
</template>

<script>
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
  },
};
</script>
