<script setup>
import ContactNoteItem from '../ContactNoteItem.vue';
import notes from './fixtures';

const controls = {
  writtenBy: {
    type: 'text',
    default: 'You',
  },
};

// Example delete handler
const onDelete = noteId => {
  console.log('Note deleted:', noteId);
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactNoteItem"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Multiple Notes">
      <div class="flex flex-col border rounded-lg border-n-strong">
        <ContactNoteItem
          v-for="note in notes"
          :key="note.id"
          :note="note"
          :written-by="
            note.id === notes[1].id
              ? controls.writtenBy.default
              : note.user.name
          "
          @delete="onDelete"
        />
      </div>
    </Variant>
  </Story>
</template>
