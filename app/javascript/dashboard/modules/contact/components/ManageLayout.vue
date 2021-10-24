<template>
  <div class="wrap">
    <div class="table-actions-wrap">
      <div class="left-aligned-wrap">
        <h1 class="page-title">
          {{ contact.name }}
        </h1>
      </div>
    </div>
    <div class="row contact--dashboard-content">
      <contact-info-panel
        v-if="!uiFlags.isFetchingItem"
        :show-avatar="false"
        :contact="contact"
      />
      <div class="medium-9">
        <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
          <woot-tabs-item
            v-for="tab in tabs"
            :key="tab.key"
            :name="tab.name"
            :show-badge="false"
          />
        </woot-tabs>
        <div class="tab-content">
          <contact-notes
            v-if="selectedTabIndex === 0"
            :contact-id="Number(contactId)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactNotes from 'dashboard/modules/notes/NotesOnContactPage';
import ContactInfoPanel from '../../../routes/dashboard/contacts/components/ContactInfoPanel.vue';

export default {
  components: {
    ContactInfoPanel,
    ContactNotes,
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

.wrap {
  height: 100%;
}
.left {
  border-right: 1px solid var(--color-border);
  overflow: auto;
}

.right {
  padding: var(--space-normal);
}

.tab-content {
  padding: var(--space-normal);
  background: var(--color-background-light);
  height: 100%;
}

.contact--dashboard-content {
  height: 100%;
}
</style>
