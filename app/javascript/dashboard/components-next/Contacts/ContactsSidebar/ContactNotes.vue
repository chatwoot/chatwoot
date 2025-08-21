<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactNoteItem from './components/ContactNoteItem.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const state = reactive({
  message: '',
});

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

const onAdd = content => {
  if (!content) return;
  const { contactId } = route.params;
  store.dispatch('contactNotes/create', { content, contactId });
  state.message = '';
};

const onDelete = noteId => {
  if (!noteId) return;
  const { contactId } = route.params;
  store.dispatch('contactNotes/delete', { noteId, contactId });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: () => onAdd(state.message),
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div class="flex flex-col gap-6 py-6">
    <Editor
      v-model="state.message"
      :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
      focus-on-mount
      class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4 px-6"
    >
      <template #actions>
        <div class="flex items-center gap-3">
          <Button
            variant="link"
            color="blue"
            size="sm"
            :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE')"
            class="hover:no-underline"
            :is-loading="isCreatingNote"
            :disabled="!state.message || isCreatingNote"
            @click="onAdd(state.message)"
          />
        </div>
      </template>
    </Editor>
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
  </div>
</template>
