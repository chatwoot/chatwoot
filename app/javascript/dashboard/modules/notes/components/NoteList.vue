<template>
  <div>
    <add-note @add="onAddNote" />
    <contact-note
      v-for="note in notes"
      :id="note.id"
      :key="note.id"
      :note="note.content"
      :user="note.user"
      :created-at="note.created_at"
      :thumbnail="note.user.thumbnail"
      @edit="onEditNote"
      @delete="onDeleteNote"
    />
  </div>
</template>

<script>
import ContactNote from './ContactNote';
import AddNote from './AddNote';

export default {
  components: {
    ContactNote,
    AddNote,
  },

  props: {
    notes: {
      type: Array,
      default: () => [],
    },
  },

  methods: {
    onAddNote(value) {
      this.$emit('add', value);
    },
    onEditNote(value) {
      this.$emit('edit', value);
    },
    onDeleteNote(value) {
      this.$emit('delete', value);
    },
  },
};
</script>
