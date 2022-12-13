<template>
  <search-result-section
    :title="$t('SEARCH.SECTION.CONTACTS')"
    :empty="!contacts.length"
  >
    <ul class="search-list">
      <li v-for="contact in contacts" :key="contact.id">
        <search-result-contact-item :contact="contact" />
      </li>
    </ul>
  </search-result-section>
</template>

<script>
import SearchResultSection from './SearchResultSection.vue';
import SearchResultContactItem from './SearchResultContactItem.vue';
export default {
  components: {
    SearchResultSection,
    SearchResultContactItem,
  },
  props: {
    contacts: {
      type: Array,
      default: () => [],
    },
  },
};
</script>
