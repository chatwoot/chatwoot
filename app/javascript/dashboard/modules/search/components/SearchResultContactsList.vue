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
};
</script>

<template>
  <SearchResultSection
    :title="$t('SEARCH.SECTION.CONTACTS')"
    :empty="!contacts.length"
    :query="query"
    :show-title="showTitle"
    :is-fetching="isFetching"
  >
    <ul v-if="contacts.length" class="search-list">
      <li v-for="contact in contacts" :key="contact.id">
        <SearchResultContactItem
          :id="contact.id"
          :name="contact.name"
          :email="contact.email"
          :phone="contact.phone_number"
          :account-id="accountId"
          :thumbnail="contact.thumbnail"
        />
      </li>
    </ul>
  </SearchResultSection>
</template>
