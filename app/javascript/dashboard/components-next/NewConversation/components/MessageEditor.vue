<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  hasErrors: { type: Boolean, default: false },
  sendWithSignature: { type: Boolean, default: false },
  messageSignature: { type: String, default: '' },
  channelType: { type: String, default: '' },
  medium: { type: String, default: '' },
});

const editorKey = computed(() => `editor-${props.channelType}-${props.medium}`);

const { t } = useI18n();

const modelValue = defineModel({
  type: String,
  default: '',
});
</script>

<template>
  <div class="flex-1 h-full">
    <Editor
      v-model="modelValue"
      :editor-key="editorKey"
      :placeholder="
        t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
      "
      class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4 [&>div]:!bg-transparent h-full [&_.ProseMirror-woot-style]:!max-h-[12.5rem] [&_.ProseMirror-woot-style]:!min-h-[10rem] [&_.ProseMirror-menubar]:!pt-0 [&_.mention--box]:-top-[7.5rem] [&_.mention--box]:bottom-[unset]"
      :class="
        hasErrors
          ? '[&_.empty-node]:before:!text-n-ruby-9 [&_.empty-node]:dark:before:!text-n-ruby-9'
          : ''
      "
      enable-variables
      :show-character-count="false"
      :signature="messageSignature"
      allow-signature
      :send-with-signature="sendWithSignature"
      :channel-type="channelType"
      :medium="medium"
    />
  </div>
</template>
