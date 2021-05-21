<template>
  <div class="wrap">
    <div class="left">
      <contact-panel v-if="!uiFlags.isFetchingItem" :contact="contact" />
    </div>
    <div class="center"></div>
    <div class="right">
      <note-list :notes="notes" @add="onAddNote" @delete="onDeleteNote" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactPanel from './ContactPanel';
import NoteList from 'dashboard/routes/dashboard/contacts/components/NoteList';

export default {
  components: {
    ContactPanel,
    NoteList,
  },
  props: {
    contactId: {
      type: [String, Number],
      default: 0,
    },
  },
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      noteUiFlags: 'contactNotes/getUIFlags',
      notes: 'contactNotes/getAllNotes',
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
    this.getContactDetails();
  },
  methods: {
    getContactDetails() {
      if (this.contactId) {
        this.$store.dispatch('contacts/show', { id: this.contactId });
      }
    },
    onAddNote(content) {
      this.$store.dispatch('contactNotes/create', { content });
    },
    onDeleteNote(id) {
      debugger;
      this.$store.dispatch('contactNotes/delete', id);
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/mixins';

.wrap {
  @include three-column-grid(27.2rem);
  background: var(--color-background);
  border-top: 1px solid var(--color-border);
}

.center {
  border-right: 1px solid var(--color-border);
  border-left: 1px solid var(--color-border);
}

.right {
  /* background: white; */
  padding: var(--space-normal);
}
</style>
