<template>
  <div class="contact-manage-view">
    <manage-layout :contact-id="contactId" />
    <create-contact :show="showCreateModal" @cancel="onToggleCreate" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ManageLayout from 'dashboard/modules/contact/components/ManageLayout';
import CreateContact from 'dashboard/routes/dashboard/conversation/contact/CreateContact';

export default {
  components: {
    CreateContact,
    ManageLayout,
  },
  props: {
    contactId: {
      type: [String, Number],
      default: 0,
    },
  },
  data() {
    return {
      searchQuery: '',
      showCreateModal: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
  },
  mounted() {},
  methods: {
    onInputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllContacts = !!this.searchQuery && newQuery === '';
      if (refetchAllContacts) {
        this.$store.dispatch('contacts/get', { page: 1 });
      }
      this.searchQuery = newQuery;
    },
    onSearchSubmit() {
      this.selectedContactId = '';
      if (this.searchQuery) {
        this.$store.dispatch('contacts/search', {
          search: this.searchQuery,
          page: 1,
        });
      }
    },
    onToggleCreate() {
      this.showCreateModal = !this.showCreateModal;
    },
  },
};
</script>

<style lang="scss" scoped>
.contact-manage-view {
  display: flex;
  flex-direction: column;
  width: 100%;
  flex: 1 1 0;
}
</style>
