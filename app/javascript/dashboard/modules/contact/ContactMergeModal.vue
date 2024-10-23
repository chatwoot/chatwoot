<script>
import { useAlert, useTrack } from 'dashboard/composables';
import MergeContact from 'dashboard/modules/contact/components/MergeContact.vue';

import ContactAPI from 'dashboard/api/contacts';

import { mapGetters } from 'vuex';
import { CONTACTS_EVENTS } from '../../helper/AnalyticsHelper/events';

export default {
  components: { MergeContact },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    primaryContact: {
      type: Object,
      required: true,
    },
  },
  emits: ['close', 'update:show'],
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
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
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
        useAlert(this.$t('MERGE_CONTACTS.SEARCH.ERROR_MESSAGE'));
      } finally {
        this.isSearching = false;
      }
    },
    async onMergeContacts(parentContactId) {
      useTrack(CONTACTS_EVENTS.MERGED_CONTACTS);
      try {
        await this.$store.dispatch('contacts/merge', {
          childId: this.primaryContact.id,
          parentId: parentContactId,
        });
        useAlert(this.$t('MERGE_CONTACTS.FORM.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        useAlert(this.$t('MERGE_CONTACTS.FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('MERGE_CONTACTS.TITLE')"
      :header-content="$t('MERGE_CONTACTS.DESCRIPTION')"
    />

    <MergeContact
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
