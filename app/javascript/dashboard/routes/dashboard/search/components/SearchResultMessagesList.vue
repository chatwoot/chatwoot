<template>
  <search-result-section
    :title="$t('SEARCH.SECTION.MESSAGES')"
    :empty="!messages.length"
  >
    <ul class="search-list">
      <li v-for="message in messages" :key="message.id">
        <search-result-message-item :message="message" />
      </li>
    </ul>
  </search-result-section>
</template>

<script>
import SearchResultSection from './SearchResultSection.vue';
import SearchResultMessageItem from './SearchResultMessageItem.vue';
export default {
  components: {
    SearchResultSection,
    SearchResultMessageItem,
  },
  props: {
    messages: {
      type: Array,
      default: () => [],
    },
  },
};
</script>
