<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const { formatMessage } = useMessageFormatter();

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
    : note.user.name;
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
      <div
        v-for="note in notes"
        :key="note.id"
        class="flex flex-col gap-2 px-6 py-2 border-b border-n-strong group/note"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-1.5 py-2.5 min-w-0">
            <Avatar
              :name="note.user.name"
              :src="note.user.thumbnail"
              :size="16"
              rounded-full
            />
            <div class="min-w-0 truncate">
              <span
                class="inline-flex items-center gap-1 text-sm text-n-slate-11"
              >
                <span class="font-medium">{{ getWrittenBy(note) }}</span>
                {{ $t('CONTACTS_LAYOUT.SIDEBAR.NOTES.WROTE') }}
                <span class="font-medium">{{
                  dynamicTime(note.createdAt)
                }}</span>
              </span>
            </div>
          </div>
          <Button
            variant="faded"
            color="ruby"
            size="xs"
            icon="i-lucide-trash"
            class="opacity-0 group-hover/note:opacity-100"
            @click="onDelete(note.id)"
          />
        </div>
        <p
          v-dompurify-html="formatMessage(note.content || '')"
          class="mb-0 prose-sm prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
        />
      </div>
    </div>
    <p v-else class="px-6 py-6 text-sm leading-6 text-center text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EMPTY_STATE') }}
    </p>
  </div>
</template>
