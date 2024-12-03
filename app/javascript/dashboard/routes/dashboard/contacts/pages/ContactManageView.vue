<script>
import { mapGetters } from 'vuex';
import ContactInfoPanel from '../components/ContactInfoPanel.vue';
import ContactNotes from 'dashboard/modules/notes/NotesOnContactPage.vue';
import SettingsHeader from '../../settings/SettingsHeader.vue';
import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    ContactInfoPanel,
    ContactNotes,
    SettingsHeader,
    Spinner,
    Thumbnail,
  },
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
  },
  data() {
    return {
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    tabs() {
      return [
        {
          key: 0,
          name: this.$t('NOTES.HEADER.TITLE'),
        },
      ];
    },
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
    backUrl() {
      if (window.history.state?.back || window.history.length > 1) {
        return '';
      }
      return `/app/accounts/${this.$route.params.accountId}/contacts`;
    },
  },
  mounted() {
    this.fetchContactDetails();
  },
  methods: {
    onClickTabChange(index) {
      this.selectedTabIndex = index;
    },
    fetchContactDetails() {
      const { contactId: id } = this;
      this.$store.dispatch('contacts/show', { id });
    },
  },
};
</script>

<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900"
  >
    <SettingsHeader
      button-route="new"
      :header-title="contact.name"
      show-back-button
      :back-button-label="$t('CONTACT_PROFILE.BACK_BUTTON')"
      :back-url="backUrl"
      :show-new-button="false"
    >
      <Thumbnail
        v-if="contact.thumbnail"
        :src="contact.thumbnail"
        :username="contact.name"
        size="32px"
        class="mr-2 rtl:mr-0 rtl:ml-2"
      />
    </SettingsHeader>

    <div v-if="uiFlags.isFetchingItem" class="text-center p-4 text-base h-full">
      <Spinner size="" />
      <span>{{ $t('CONTACT_PROFILE.LOADING') }}</span>
    </div>
    <div v-else-if="contact.id" class="overflow-hidden flex-1 min-w-0">
      <div class="flex flex-wrap ml-auto mr-auto max-w-full h-full">
        <ContactInfoPanel
          :show-close-button="false"
          :show-avatar="false"
          :contact="contact"
        />
        <div class="w-3/4 h-full">
          <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
            <woot-tabs-item
              v-for="(tab, index) in tabs"
              :key="tab.key"
              :index="index"
              :name="tab.name"
              :show-badge="false"
            />
          </woot-tabs>
          <div
            class="bg-slate-25 dark:bg-slate-800 h-[calc(100%-40px)] p-4 overflow-auto"
          >
            <ContactNotes
              v-if="selectedTabIndex === 0"
              :contact-id="Number(contactId)"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
