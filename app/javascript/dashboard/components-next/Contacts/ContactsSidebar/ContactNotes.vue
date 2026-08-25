<script setup>
import { reactive, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactSidebarSection from 'dashboard/components-next/Contacts/ContactsSidebar/ContactSidebarSection.vue';
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

const searchQuery = ref('');

const filteredNotes = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return notes.value;
  return notes.value.filter(note =>
    (note.content || '').toLowerCase().includes(query)
  );
});

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
  <ContactSidebarSection
    :title="t('CONTACTS_LAYOUT.PROFILE.SECTIONS.NOTES')"
    :count="notes.length || null"
    body-class="p-0"
  >
    <div class="border-b border-n-weak">
      <Editor
        v-model="state.message"
        :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
        class="[&>div]:!border-transparent [&>div]:!bg-transparent [&>div]:px-4 [&>div]:py-3"
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
    </div>
    <div
      v-if="isFetchingNotes"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <template v-else-if="notes.length > 0">
      <div class="px-4 py-3 border-b border-n-weak">
        <div class="relative">
          <span
            class="absolute i-lucide-search size-3.5 top-2.5 left-3 text-n-slate-10"
          />
          <input
            v-model="searchQuery"
            type="search"
            :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SEARCH_PLACEHOLDER')"
            class="w-full h-8 py-2 pl-10 pr-2 text-sm border outline-none reset-base rounded-lg border-n-weak bg-n-alpha-black2 dark:bg-n-solid-2 text-n-slate-12"
          />
        </div>
      </div>
      <div class="px-4 max-h-[60vh] overflow-y-auto [&>div]:!border-b-0">
        <ContactNoteItem
          v-for="note in filteredNotes"
          :key="note.id"
          class="py-3.5"
          :note="note"
          :written-by="getWrittenBy(note)"
          allow-delete
          @delete="onDelete"
        />
        <p
          v-if="filteredNotes.length === 0"
          class="py-6 text-sm leading-6 text-center text-n-slate-11"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.NO_RESULTS') }}
        </p>
      </div>
    </template>
    <p v-else class="px-4 py-6 text-sm leading-6 text-center text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EMPTY_STATE') }}
    </p>
  </ContactSidebarSection>
</template>
