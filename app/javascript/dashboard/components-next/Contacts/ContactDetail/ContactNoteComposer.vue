<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  contactId: { type: Number, required: true },
});

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('contactNotes/getUIFlags');

const message = ref('');
const isCreatingNote = computed(() => uiFlags.value.isCreating);

const addNote = () => {
  if (!message.value || isCreatingNote.value) return;
  store.dispatch('contactNotes/create', {
    content: message.value,
    contactId: props.contactId,
  });
  message.value = '';
};

useKeyboardEvents({
  '$mod+Enter': { action: addNote, allowOnFocusedInput: true },
});
</script>

<template>
  <Editor
    v-model="message"
    :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.PLACEHOLDER')"
    class="[&>div]:!border-n-weak [&>div]:bg-n-solid-1 [&>div]:px-4 [&>div]:py-3"
  >
    <template #actions>
      <Button
        :label="t('CONTACTS_LAYOUT.SIDEBAR.NOTES.SAVE')"
        size="sm"
        :is-loading="isCreatingNote"
        :disabled="!message || isCreatingNote"
        @click="addNote"
      />
    </template>
  </Editor>
</template>
