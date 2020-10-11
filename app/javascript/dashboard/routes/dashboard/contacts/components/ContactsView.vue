<template>
  <div class="contacts-page">
    <contacts-header
      :search-query="searchQuery"
      :on-search-submit="onSearchSubmit"
      :on-input-search="onInputSearch"
    />
    <contacts :contacts="records" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ContactsHeader from './Header';
import Contacts from './Contacts';

export default {
  components: {
    ContactsHeader,
    Contacts,
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
    }),
  },
  mounted() {
    this.$store.dispatch('contacts/get');
  },
  methods: {
    onInputSearch(event) {
      this.searchQuery = event.target.value;
    },
    onSearchSubmit() {
      this.$store.dispatch('contacts/search', { search: this.searchQuery });
    },
  },
};
</script>

<style lang="scss" scoped>
.contacts-page {
  padding-top: var(--space-normal);
  width: 100%;
}
</style>
