<script setup>
import { defineAsyncComponent, ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useFileUpload } from 'dashboard/composables/useFileUpload';
import { vOnClickOutside } from '@vueuse/components';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import FileUpload from 'vue-upload-component';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import WhatsAppOptions from './WhatsAppOptions.vue';

const props = defineProps({
  attachedFiles: { type: Array, default: () => [] },
  isWhatsappInbox: { type: Boolean, default: false },
  isEmailOrWebWidgetInbox: { type: Boolean, default: false },
  isTwilioSmsInbox: { type: Boolean, default: false },
  messageTemplates: { type: Array, default: () => [] },
  channelType: { type: String, default: '' },
  isLoading: { type: Boolean, default: false },
  disableSendButton: { type: Boolean, default: false },
  hasSelectedInbox: { type: Boolean, default: false },
  hasNoInbox: { type: Boolean, default: false },
  isDropdownActive: { type: Boolean, default: false },
  messageSignature: { type: String, default: '' },
});

const emit = defineEmits([
  'discard',
  'sendMessage',
  'sendWhatsappMessage',
  'insertEmoji',
  'addSignature',
  'removeSignature',
  'attachFile',
]);

const { t } = useI18n();

const uploadAttachment = ref(null);
const isEmojiPickerOpen = ref(false);

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

const signatureToApply = computed(() =>
  props.isEmailOrWebWidgetInbox
    ? props.messageSignature
    : extractTextFromMarkdown(props.messageSignature)
);

const {
  fetchSignatureFlagFromUISettings,
  setSignatureFlagForInbox,
  isEditorHotKeyEnabled,
} = useUISettings();

const sendWithSignature = computed(() => {
  return fetchSignatureFlagFromUISettings(props.channelType);
});

const setSignature = () => {
  if (signatureToApply.value) {
    if (sendWithSignature.value) {
      emit('addSignature', signatureToApply.value);
    } else {
      emit('removeSignature', signatureToApply.value);
    }
  }
};

const toggleMessageSignature = () => {
  setSignatureFlagForInbox(props.channelType, !sendWithSignature.value);
  setSignature();
};

// Added this watch to dynamically set signature on target inbox change.
// Only targetInbox has value and is Advance Editor(used by isEmailOrWebWidgetInbox)
// Set the signature only if the inbox based flag is true
watch(
  () => props.hasSelectedInbox,
  newValue => {
    nextTick(() => {
      if (newValue && props.isEmailOrWebWidgetInbox) setSignature();
    });
  },
  { immediate: true }
);

const onClickInsertEmoji = emoji => {
  emit('insertEmoji', emoji);
};

const { onFileUpload } = useFileUpload({
  isATwilioSMSChannel: props.isTwilioSmsInbox,
  attachFile: ({ blob, file }) => {
    if (!file) return;
    const reader = new FileReader();
    reader.readAsDataURL(file.file);
    reader.onloadend = () => {
      const newFile = {
        resource: blob || file,
        isPrivate: false,
        thumb: reader.result,
        blobSignedId: blob?.signed_id,
      };
      emit('attachFile', [...props.attachedFiles, newFile]);
    };
  },
});

const sendButtonLabel = computed(() => {
  const keyCode = isEditorHotKeyEnabled('cmd_enter') ? '⌘ + ↵' : '↵';
  return t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.SEND', {
    keyCode,
  });
});

const keyboardEvents = {
  Enter: {
    action: () => {
      if (
        isEditorHotKeyEnabled('enter') &&
        !props.isWhatsappInbox &&
        !props.isDropdownActive
      ) {
        emit('sendMessage');
      }
    },
  },
  '$mod+Enter': {
    action: () => {
      if (
        isEditorHotKeyEnabled('cmd_enter') &&
        !props.isWhatsappInbox &&
        !props.isDropdownActive
      ) {
        emit('sendMessage');
      }
    },
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div
    class="flex items-center justify-between w-full h-[3.25rem] gap-2 px-4 py-3"
  >
    <div class="flex items-center gap-2">
      <WhatsAppOptions
        v-if="isWhatsappInbox"
        :message-templates="messageTemplates"
        @send-message="emit('sendWhatsappMessage', $event)"
      />
      <div
        v-if="!isWhatsappInbox && !hasNoInbox"
        v-on-click-outside="() => (isEmojiPickerOpen = false)"
        class="relative"
      >
        <Button
          icon="i-lucide-smile-plus"
          color="slate"
          size="sm"
          class="!w-10"
          @click="isEmojiPickerOpen = !isEmojiPickerOpen"
        />
        <EmojiInput
          v-if="isEmojiPickerOpen"
          class="left-0 top-full mt-1.5"
          :on-click="onClickInsertEmoji"
        />
      </div>
      <FileUpload
        v-if="isEmailOrWebWidgetInbox"
        ref="uploadAttachment"
        input-id="composeNewConversationAttachment"
        :size="4096 * 4096"
        :accept="ALLOWED_FILE_TYPES"
        multiple
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        class="p-px"
        @input-file="onFileUpload"
      >
        <Button
          icon="i-lucide-plus"
          color="slate"
          size="sm"
          class="!w-10 relative"
        />
      </FileUpload>
      <Button
        v-if="hasSelectedInbox && !isWhatsappInbox"
        icon="i-lucide-signature"
        color="slate"
        size="sm"
        class="!w-10"
        @click="toggleMessageSignature"
      />
    </div>

    <div class="flex items-center gap-2">
      <Button
        :label="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.DISCARD')"
        variant="faded"
        color="slate"
        size="sm"
        class="!text-xs font-medium"
        @click="emit('discard')"
      />
      <Button
        v-if="!isWhatsappInbox"
        :label="sendButtonLabel"
        size="sm"
        class="!text-xs font-medium"
        :disabled="isLoading || disableSendButton"
        :is-loading="isLoading"
        @click="emit('sendMessage')"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.emoji-dialog::before {
  @apply hidden;
}

// The <label> tag inside the file-upload component overlaps the button due to its position.
// This causes the button's hover state to not work, as it's positioned below the label (z-index).
// Increasing the button's z-index would break the file upload functionality.
// This style ensures the label remains clickable while preserving the button's hover effect.
:deep() {
  .file-uploads.file-uploads-html5 {
    label {
      @apply hover:cursor-pointer;
    }

    &:hover button {
      @apply dark:bg-n-solid-2 bg-n-alpha-2;
    }
  }
}
</style>
