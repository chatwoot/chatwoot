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
      @edit="onEditNote"
      @delete="onDeleteNote"
    />

    <woot-loading-state
      v-if="isFetching"
      :message="$t('NOTES.FETCHING_NOTES')"
    />
    <div v-else-if="!notes.length" class="text-center p-normal fs-default">
      <span>{{ $t('NOTES.NOT_AVAILABLE') }}</span>
    </div>
  </div>
</template>

<script>
import AddNote from './AddNote.vue';
import ContactNote from './ContactNote.vue';

export default {
  components: {
    AddNote,
    ContactNote,
  },

  props: {
    notes: {
      type: Array,
      default: () => [],
    },
    isFetching: {
      type: Boolean,
      default: false,
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
