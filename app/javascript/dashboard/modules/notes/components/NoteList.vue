<script>
import AddNote from './AddNote.vue';
import ContactNote from './ContactNote.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    AddNote,
    ContactNote,
    Spinner,
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
  emits: ['add', 'edit', 'delete'],

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

<template>
  <div>
    <AddNote @add="onAddNote" />
    <ContactNote
      v-for="note in notes"
      :id="note.id"
      :key="note.id"
      :note="note.content"
      :user="note.user"
      :created-at="note.created_at"
      @edit="onEditNote"
      @delete="onDeleteNote"
    />

    <div v-if="isFetching" class="text-center p-4 text-base">
      <Spinner size="" />
      <span>{{ $t('NOTES.FETCHING_NOTES') }}</span>
    </div>
    <div v-else-if="!notes.length" class="text-center p-4 text-base">
      <span>{{ $t('NOTES.NOT_AVAILABLE') }}</span>
    </div>
  </div>
</template>
