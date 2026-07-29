<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ContactNoteItem from './components/ContactNoteItem.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const noteContent = ref('');
const dialogRef = ref(null);

const currentUser = useMapGetter('getCurrentUser');
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const isCreatingNote = computed(() => uiFlags.value.isCreating);
const notes = computed(() => notesByContact.value(route.params.contactId));

const getWrittenBy = note => {
  const isCurrentUser = note?.user?.id === currentUser.value.id;
  return isCurrentUser
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : note?.user?.name || 'Bot';
};

const openCreateModal = () => {
  noteContent.value = '';
  dialogRef.value?.open();
};

const closeCreateModal = () => {
  noteContent.value = '';
  dialogRef.value?.close();
};

const onAdd = async () => {
  if (!noteContent.value || isCreatingNote.value) return;
  const { contactId } = route.params;
  await store.dispatch('contactNotes/create', {
    content: noteContent.value,
    contactId,
  });
  noteContent.value = '';
  closeCreateModal();
};

const onDelete = noteId => {
  if (!noteId) return;
  const { contactId } = route.params;
  store.dispatch('contactNotes/delete', { noteId, contactId });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: onAdd,
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between px-6">
      <Button
        size="sm"
        icon="i-lucide-plus"
        :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE')"
        :disabled="isFetchingNotes"
        @click="openCreateModal"
      />
    </div>

    <div
      v-if="isFetchingNotes"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="notes.length > 0">
      <ContactNoteItem
        v-for="note in notes"
        :key="note.id"
        class="mx-6 py-4"
        :note="note"
        :written-by="getWrittenBy(note)"
        allow-delete
        @delete="onDelete"
      />
    </div>
    <p v-else class="px-6 py-6 text-sm leading-6 text-center text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EMPTY_STATE') }}
    </p>

    <Dialog
      ref="dialogRef"
      type="edit"
      width="lg"
      :title="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE')"
      :confirm-button-label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE')"
      :disable-confirm-button="!noteContent || isCreatingNote"
      :is-loading="isCreatingNote"
      @confirm="onAdd"
      @close="noteContent = ''"
    >
      <Editor
        v-model="noteContent"
        focus-on-mount
        :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
        class="[&>div]:!border-transparent [&>div]:px-3 [&>div]:py-2"
      />
    </Dialog>
  </div>
</template>
