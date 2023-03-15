<template>
  <search-result-section
    :title="$t('SEARCH.SECTION.CONTACTS')"
    :empty="!contacts.length"
    :query="query"
  >
    <ul class="search-list">
      <li v-for="contact in contacts" :key="contact.id">
        <search-result-contact-item
          :id="contact.id"
          :name="contact.name"
          :email="contact.email"
          :phone="contact.phone_number"
          :account-id="accountId"
          :thumbnail="contact.thumbnail"
        />
      </li>
    </ul>
  </search-result-section>
</template>

<script>
import { mapGetters } from 'vuex';

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
