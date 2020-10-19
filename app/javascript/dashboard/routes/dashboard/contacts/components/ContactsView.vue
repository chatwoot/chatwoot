<template>
  <div class="contacts-page">
    <contacts-header
      :search-query="searchQuery"
      :on-search-submit="onSearchSubmit"
      :on-input-search="onInputSearch"
    />
    <contacts
      :contacts="records"
      :show-search-empty-state="showEmptySearchResult"
    />
    <contacts-footer
      :on-page-change="onPageChange"
      :current-page="currentPage"
      :total-count="records.length"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ContactsHeader from './Header';
import Contacts from './Contacts';
import ContactsFooter from './Footer';

export default {
  components: {
    ContactsHeader,
    Contacts,
    ContactsFooter,
  },
  data() {
    return {
      searchQuery: '',
      currentPage: 1,
    };
  },
  computed: {
    ...mapGetters({
      records: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
  },
  mounted() {
    this.$store.dispatch('contacts/get');
  },
  methods: {
    onInputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllContacts = !!this.searchQuery && newQuery === '';

      if (refetchAllContacts) {
        this.$store.dispatch('contacts/get');
      }
      this.searchQuery = event.target.value;
    },
    onSearchSubmit() {
      this.$store.dispatch('contacts/search', { search: this.searchQuery });
    },
    onPageChange(page) {
      this.currentPage = page;
    },
  },
};
</script>

<style lang="scss" scoped>
.contacts-page {
  display: flex;
  flex-direction: column;
  padding-top: var(--space-normal);
  width: 100%;
}
</style>
