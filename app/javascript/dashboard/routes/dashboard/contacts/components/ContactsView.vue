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
      :current-page="Number(meta.currentPage)"
      :total-count="meta.count"
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
    };
  },
  computed: {
    ...mapGetters({
      records: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
      meta: 'contacts/getMeta',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
  },
  mounted() {
    this.$store.dispatch('contacts/get', { page: 1 });
  },
  methods: {
    onInputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllContacts = !!this.searchQuery && newQuery === '';

      if (refetchAllContacts) {
        this.$store.dispatch('contacts/get', { page: 1 });
      }
      this.searchQuery = event.target.value;
    },
    onSearchSubmit() {
      this.$store.dispatch('contacts/search', {
        search: this.searchQuery,
        page: 1,
      });
    },
    onPageChange(page) {
      if (this.searchQuery) {
        this.$store.dispatch('contacts/search', {
          search: this.searchQuery,
          page,
        });
      } else {
        this.$store.dispatch('contacts/get', { page });
      }
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
