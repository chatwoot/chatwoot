<script setup>
import { watch, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ContactNoteItem from 'next/Contacts/ContactsSidebar/components/ContactNoteItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
});

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const isCreatingNote = computed(() => uiFlags.value.isCreating);
const contactId = computed(() => props.contactId);
const noteContent = ref('');
const shouldShowCreateModal = ref(false);
const notes = computed(() => {
  if (!contactId.value) {
    return [];
  }
  return notesByContact.value(contactId.value) || [];
});

const getWrittenBy = ({ user } = {}) => {
  const currentUserId = currentUser.value?.id;
  return user?.id === currentUserId
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : user?.name || t('CONVERSATION.BOT');
};

const openCreateModal = () => {
  if (!contactId.value) {
    return;
  }

  noteContent.value = '';
  shouldShowCreateModal.value = true;
};

const closeCreateModal = () => {
  shouldShowCreateModal.value = false;
  noteContent.value = '';
};

const onAdd = async () => {
  if (!contactId.value || !noteContent.value || isCreatingNote.value) {
    return;
  }

  await store.dispatch('contactNotes/create', {
    content: noteContent.value,
    contactId: contactId.value,
  });
  noteContent.value = '';
  closeCreateModal();
};

const onDelete = noteId => {
  if (!contactId.value || !noteId) {
    return;
  }

  store.dispatch('contactNotes/delete', {
    noteId,
    contactId: contactId.value,
  });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: onAdd,
    allowOnFocusedInput: true,
  },
};

useKeyboardEvents(keyboardEvents);

watch(
  contactId,
  newContactId => {
    closeCreateModal();
    if (newContactId) {
      store.dispatch('contactNotes/get', { contactId: newContactId });
    }
  },
  { immediate: true }
);
</script>

<template>
  <div>
    <div class="px-4 pt-3 pb-2">
      <NextButton
        ghost
        xs
        icon="i-lucide-plus"
        :label="$t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE')"
        :disabled="!contactId || isFetchingNotes"
        @click="openCreateModal"
      />
    </div>

    <div
      v-if="isFetchingNotes"
      class="flex items-center justify-center py-8 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div
      v-else-if="notes.length"
      class="flex flex-col max-h-[300px] overflow-y-auto"
    >
      <ContactNoteItem
        v-for="note in notes"
        :key="note.id"
        class="py-4 last-of-type:border-b-0 px-4"
        :note="note"
        :written-by="getWrittenBy(note)"
        allow-delete
        collapsible
        @delete="onDelete"
      />
    </div>
    <p v-else class="px-6 py-6 text-sm leading-6 text-center text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.CONVERSATION_EMPTY_STATE') }}
    </p>

    <woot-modal
      v-model:show="shouldShowCreateModal"
      :on-close="closeCreateModal"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <div class="flex w-full flex-col gap-6 px-6 py-6">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.ADD_NOTE') }}
        </h3>
        <Editor
          v-model="noteContent"
          focus-on-mount
          :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
          class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4"
        />
        <div class="flex items-center justify-end gap-3">
          <NextButton
            solid
            blue
            :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE')"
            :is-loading="isCreatingNote"
            :disabled="!noteContent || isCreatingNote"
            @click="onAdd"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
