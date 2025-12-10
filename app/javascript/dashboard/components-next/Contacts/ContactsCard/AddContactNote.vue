<script setup>
import { reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  contactId: {
    type: Number,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const state = reactive({
  message: '',
});

const onAdd = async content => {
  if (!content) return;
  try {
    await store.dispatch('contactNotes/create', {
      content,
      contactId: props.contactId,
    });
    state.message = '';
    useAlert(t('CONTACTS_LAYOUT.CARD.ADD_NOTE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.CARD.ADD_NOTE.API.ERROR_MESSAGE'));
  }
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
  <div class="flex flex-col items-start gap-4 py-3">
    <span
      class="py-1 text-sm font-medium text-n-slate-12 z-10 h-6 bg-n-surface-1 inline-flex items-center gap-2"
    >
      <Icon
        icon="i-lucide-file-plus-corner"
        class="size-4 text-n-slate-11 hidden lg:block"
      />
      {{ t('CONTACTS_LAYOUT.CARD.ADD_NOTE.TITLE') }}
    </span>
    <div class="flex flex-col gap-6 lg:px-6 max-w-lg w-full">
      <Editor
        v-model="state.message"
        :placeholder="t('CONTACTS_LAYOUT.CARD.ADD_NOTE.PLACEHOLDER')"
        class="[&>div]:!border-transparent [&>div]:!px-3 [&>div]:!pb-4 [&_.ProseMirror-woot-style]:min-h-6 [&_.ProseMirror-menubar]:!relative ltr:[&_.ProseMirror-menubar]:!-left-[3px] ltr:[&_.ProseMirror-menubar]:!right-[unset] rtl:[&_.ProseMirror-menubar]:!-right-[3px] rtl:[&_.ProseMirror-menubar]:!left-[unset] [&_.ProseMirror-menubar]:!w-[unset] [&_.ProseMirror-menubar]:!top-[unset] [&_.ProseMirror-menubar-spacer]:!hidden"
      />
    </div>
  </div>
</template>
