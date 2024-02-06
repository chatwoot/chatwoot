<template>
  <note-list
    :is-fetching="uiFlags.isFetching"
    :notes="notes"
    @add="onAdd"
    @delete="onDelete"
  />
</template>

<script>
import { mapGetters } from 'vuex';
import NoteList from './components/NoteList.vue';

export default {
  components: {
    NoteList,
  },
  props: {
    contactId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters({ uiFlags: 'contactNotes/getUIFlags' }),
    notes() {
      return this.$store.getters['contactNotes/getAllNotesByContact'](
        this.contactId
      );
    },
  },
  mounted() {
    this.fetchContactNotes();
  },
  methods: {
    fetchContactNotes() {
      const { contactId } = this;
      if (contactId) this.$store.dispatch('contactNotes/get', { contactId });
    },
    onAdd(content) {
      const { contactId } = this;
      this.$store.dispatch('contactNotes/create', { content, contactId });
    },
    onDelete(noteId) {
      const { contactId } = this;
      this.$store.dispatch('contactNotes/delete', { noteId, contactId });
    },
  },
};
</script>
