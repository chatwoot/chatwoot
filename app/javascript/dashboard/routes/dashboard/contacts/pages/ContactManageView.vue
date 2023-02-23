<template>
  <div class="view-box columns bg-white">
    <settings-header
      button-route="new"
      :header-title="contact.name"
      show-back-button
      :back-button-label="$t('CONTACT_PROFILE.BACK_BUTTON')"
      :back-url="backUrl"
      :show-new-button="false"
    >
      <thumbnail
        v-if="contact.thumbnail"
        :src="contact.thumbnail"
        :username="contact.name"
        size="32px"
        class="margin-right-1"
      />
    </settings-header>

    <div
      v-if="uiFlags.isFetchingItem"
      class="text-center p-normal fs-default h-full"
    >
      <spinner size="" />
      <span>{{ $t('CONTACT_PROFILE.LOADING') }}</span>
    </div>
    <div
      v-else-if="contact.id"
      class="overflow-hidden column contact--dashboard-content"
    >
      <div class="row h-full">
        <contact-info-panel
          :show-close-button="false"
          :show-avatar="false"
          :contact="contact"
        />
        <div class="small-12 medium-9 h-full">
          <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
            <woot-tabs-item
              v-for="tab in tabs"
              :key="tab.key"
              :name="tab.name"
              :show-badge="false"
            />
          </woot-tabs>
          <div class="tab-content overflow-auto">
            <contact-notes
              v-if="selectedTabIndex === 0"
              :contact-id="Number(contactId)"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactInfoPanel from '../components/ContactInfoPanel.vue';
import ContactNotes from 'dashboard/modules/notes/NotesOnContactPage';
import SettingsHeader from '../../settings/SettingsHeader.vue';
import Spinner from 'shared/components/Spinner';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

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

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.left {
  border-right: 1px solid var(--color-border);
  overflow: auto;
}

.right {
  padding: var(--space-normal);
}

.tab-content {
  background: var(--color-background-light);
  height: calc(100% - 40px);
  padding: var(--space-normal);
}
</style>
