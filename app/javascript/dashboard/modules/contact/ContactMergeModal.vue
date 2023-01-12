<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('MERGE_CONTACTS.TITLE')"
      :header-content="$t('MERGE_CONTACTS.DESCRIPTION')"
    />

    <merge-contact
      :primary-contact="primaryContact"
      :is-searching="isSearching"
      :is-merging="uiFlags.isMerging"
      :search-results="searchResults"
      @search="onContactSearch"
      @cancel="onClose"
      @submit="onMergeContacts"
    />
  </woot-modal>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import MergeContact from 'dashboard/modules/contact/components/MergeContact';

import ContactAPI from 'dashboard/api/contacts';

import { mapGetters } from 'vuex';
import { CONTACTS_EVENTS } from '../../helper/AnalyticsHelper/events';

export default {
  components: { MergeContact },
  mixins: [alertMixin],
  props: {
    primaryContact: {
      type: Object,
      required: true,
    },
    show: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isSearching: false,
      searchResults: [],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    async onContactSearch(query) {
      this.isSearching = true;
      this.searchResults = [];

      try {
        const {
          data: { payload },
        } = await ContactAPI.search(query);
        this.searchResults = payload.filter(
          contact => contact.id !== this.primaryContact.id
        );
      } catch (error) {
        this.showAlert(this.$t('MERGE_CONTACTS.SEARCH.ERROR_MESSAGE'));
      } finally {
        this.isSearching = false;
      }
    },
    async onMergeContacts(childContactId) {
      this.$track(CONTACTS_EVENTS.MERGED_CONTACTS);
      try {
        await this.$store.dispatch('contacts/merge', {
          childId: childContactId,
          parentId: this.primaryContact.id,
        });
        this.showAlert(this.$t('MERGE_CONTACTS.FORM.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        this.showAlert(this.$t('MERGE_CONTACTS.FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped></style>
