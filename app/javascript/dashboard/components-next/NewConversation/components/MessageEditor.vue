<script setup>
import { ref, watch, computed, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  appendSignature,
  extractTextFromMarkdown,
  removeSignature,
} from 'dashboard/helper/editorHelper';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import CannedResponse from 'dashboard/components/widgets/conversation/CannedResponse.vue';

const props = defineProps({
  isEmailOrWebWidgetInbox: { type: Boolean, required: true },
  hasErrors: { type: Boolean, default: false },
  hasAttachments: { type: Boolean, default: false },
  sendWithSignature: { type: Boolean, default: false },
  messageSignature: { type: String, default: '' },
});

const { t } = useI18n();

const modelValue = defineModel({
  type: String,
  default: '',
});

const state = ref({
  hasSlashCommand: false,
  showMentions: false,
  mentionSearchKey: '',
});

const plainTextSignature = computed(() =>
  extractTextFromMarkdown(props.messageSignature)
);

watch(
  modelValue,
  newValue => {
    if (props.isEmailOrWebWidgetInbox) return;

    const bodyWithoutSignature = newValue
      ? removeSignature(newValue, plainTextSignature.value)
      : '';

    // Check if message starts with slash
    const startsWithSlash = bodyWithoutSignature.startsWith('/');

    // Update slash command and mentions state
    state.value = {
      ...state.value,
      hasSlashCommand: startsWithSlash,
      showMentions: startsWithSlash,
      mentionSearchKey: startsWithSlash ? bodyWithoutSignature.slice(1) : '',
    };
  },
  { immediate: true }
);

const hideMention = () => {
  state.value.showMentions = false;
};

const replaceText = async message => {
  // Only append signature on replace if sendWithSignature is true
  const finalMessage = props.sendWithSignature
    ? appendSignature(message, plainTextSignature.value)
    : message;

  await nextTick();
  modelValue.value = finalMessage;
};
</script>

<template>
  <div class="flex-1 h-full" :class="[!hasAttachments && 'min-h-[200px]']">
    <template v-if="isEmailOrWebWidgetInbox">
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
        enable-variables
        :show-character-count="false"
      />
    </template>
    <template v-else>
      <TextArea
        v-model="modelValue"
        :placeholder="
          t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
        "
        class="!px-0 [&>div]:!px-4 [&>div]:!border-transparent [&>div]:!bg-transparent"
        :custom-text-area-class="
          hasErrors
            ? 'placeholder:!text-n-ruby-9 dark:placeholder:!text-n-ruby-9'
            : ''
        "
        auto-height
        allow-signature
        :signature="messageSignature"
        :send-with-signature="sendWithSignature"
      >
        <CannedResponse
          v-if="state.showMentions && state.hasSlashCommand"
          v-on-clickaway="hideMention"
          class="normal-editor__canned-box"
          :search-key="state.mentionSearchKey"
          @replace="replaceText"
        />
      </TextArea>
    </template>
  </div>
</template>
