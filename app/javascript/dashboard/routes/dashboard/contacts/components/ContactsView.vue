<template>
  <div class="contacts-page">
    <contacts-header />
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
  computed: {
    ...mapGetters({
      records: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('contacts/search', { search: 'w' });
  },
};
</script>

<style lang="scss" scoped>
.contacts-page {
  padding-top: var(--space-normal);
}
</style>
