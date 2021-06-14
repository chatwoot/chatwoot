<template>
  <div class="wrap">
    <div class="left">
      <contact-panel v-if="!uiFlags.isFetchingItem" :contact="contact" />
    </div>
    <div class="center"></div>
    <div class="right">
      <contact-notes :contact-id="Number(contactId)" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactPanel from './ContactPanel';
import ContactNotes from 'dashboard/modules/notes/NotesOnContactPage';

export default {
  components: {
    ContactPanel,
    ContactNotes,
  },
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
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
  @include three-column-grid(27.2rem);
  min-height: 0;

  background: var(--color-background-light);
  border-top: 1px solid var(--color-border);
}
.left {
  overflow: auto;
}
.center {
  border-right: 1px solid var(--color-border);
  border-left: 1px solid var(--color-border);
}

.right {
  padding: var(--space-normal);
}
</style>
