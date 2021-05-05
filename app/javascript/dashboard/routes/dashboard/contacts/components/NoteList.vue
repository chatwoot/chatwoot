<template>
  <div>
    <div class="notelist-wrap">
      <h3 class="block-title">
        {{ $t('NOTES.HEADER.TITLE') }}
      </h3>
      <add-note @add="onAddNote" />
      <contact-note
        v-for="note in notes"
        :id="note.id"
        :key="note.id"
        :note="note.content"
        :user-name="note.user.name"
        :time-stamp="note.created_at"
        :thumbnail="note.user.thumbnail"
        @edit="onEditNote"
        @delete="onDeleteNote"
      />
      <div class="button-wrap">
        <woot-button variant="clear link" class="button" @click="onclick">
          {{ $t('NOTES.FOOTER.BUTTON') }}
          <i class="ion-arrow-right-c" />
        </woot-button>
      </div>
    </div>
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
    onclick() {
      this.$emit('show');
    },
    onAddNote(value) {
      this.$emit('addNote', value);
    },
    onEditNote(value) {
      this.$emit('editNote', value);
    },
    onDeleteNote(value) {
      this.$emit('deleteNote', value);
    },
  },
};
</script>

<style lang="scss" scoped>
.button-wrap {
  margin-top: var(--space-one);
}
</style>
