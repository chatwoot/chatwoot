<script setup>
import { useI18n } from 'vue-i18n';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

defineProps({
  isEmailOrWebWidgetInbox: {
    type: Boolean,
    required: true,
  },
  hasErrors: {
    type: Boolean,
    default: false,
  },
  hasAttachments: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const modelValue = defineModel({
  type: String,
  default: '',
});
</script>

<template>
  <div
    v-if="isEmailOrWebWidgetInbox"
    class="flex-1 h-full"
    :class="!hasAttachments && 'min-h-[200px]'"
  >
    <Editor
      v-model="modelValue"
      :placeholder="
        t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
      "
      class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4 [&>div]:!bg-transparent h-full [&_.ProseMirror-woot-style]:!max-h-[200px]"
      :class="
        hasErrors
          ? '[&_.empty-node]:before:!text-n-ruby-9 [&_.empty-node]:dark:before:!text-n-ruby-9'
          : ''
      "
      :show-character-count="false"
    />
  </div>
  <div v-else class="flex-1 h-full" :class="!hasAttachments && 'min-h-[200px]'">
    <TextArea
      v-model="modelValue"
      :placeholder="
        t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
      "
      class="!px-0 [&>div]:!px-4 [&>div]:!border-transparent [&>div]:!bg-transparent"
      auto-height
      :custom-text-area-class="
        hasErrors
          ? 'placeholder:!text-n-ruby-9 dark:placeholder:!text-n-ruby-9'
          : ''
      "
    />
  </div>
</template>
