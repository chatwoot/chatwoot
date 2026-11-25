<script setup>
import { ref, computed, watch, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import WootWriter from 'dashboard/components/widgets/WootWriter/Editor.vue';
import { useAlert } from 'dashboard/composables';
import {
  splitFilesBySize,
  usableFilesFromTransfer,
} from 'dashboard/helper/pastedFiles';

const props = defineProps({
  disabled: {
    type: Boolean,
    default: false,
  },
  placeholder: {
    type: String,
    default: '',
  },
  initialContent: {
    type: String,
    default: '',
  },
  editingMessage: {
    type: Object,
    default: null,
  },
  showPoll: {
    type: Boolean,
    default: true,
  },
  showAlsoSendInChannel: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'send',
  'typing',
  'draftUpdate',
  'createPoll',
  'cancelEdit',
]);

const alsoSendInChannel = ref(false);

const { t } = useI18n();

const editorRef = ref(null);
const fileInputRef = ref(null);
const editorContent = ref(props.initialContent);
const attachedFiles = ref([]);
const isMentionMenuOpen = ref(false);
const isConversationMenuOpen = ref(false);
const isDragging = ref(false);

let draftTimer = null;
let dragCounter = 0;

const canSend = computed(() => {
  return (
    (editorContent.value.trim().length > 0 || attachedFiles.value.length > 0) &&
    !props.disabled
  );
});

function cancelEdit() {
  editorContent.value = '';
  attachedFiles.value = [];
  emit('cancelEdit');
}

watch(
  () => props.editingMessage,
  msg => {
    if (msg) {
      editorContent.value = msg.content || '';
    }
  },
  { immediate: true }
);

watch(editorContent, newContent => {
  if (draftTimer) clearTimeout(draftTimer);
  draftTimer = setTimeout(() => {
    emit('draftUpdate', newContent);
  }, 3000);
});

function focusEditor() {
  editorRef.value?.$el?.querySelector('.ProseMirror')?.focus();
}

function insertMentionTrigger(char) {
  editorRef.value?.insertMentionTrigger?.(char);
}

function handleSend() {
  if (!canSend.value) return;
  const content = editorContent.value.trim();
  const files = [...attachedFiles.value];
  editorContent.value = '';
  attachedFiles.value = [];
  if (draftTimer) {
    clearTimeout(draftTimer);
    draftTimer = null;
  }
  emit('draftUpdate', '');
  emit('send', content, {
    alsoSendInChannel: alsoSendInChannel.value,
    files,
  });
  setTimeout(() => focusEditor(), 200);
}

function handleToggleUserMention(isOpen) {
  isMentionMenuOpen.value = isOpen;
}

function handleToggleConversationMention(isOpen) {
  isConversationMenuOpen.value = isOpen;
}

function handleKeyDown(event) {
  if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
    if (isMentionMenuOpen.value || isConversationMenuOpen.value) return;
    event.preventDefault();
    event.stopPropagation();
    handleSend();
    return;
  }
  if (event.key === 'Escape' && props.editingMessage) {
    cancelEdit();
  }
}

function handleTypingOn() {
  emit('typing');
}

function openFilePicker() {
  fileInputRef.value?.click();
}

function handleFileChange(event) {
  // A file chosen in the picker was chosen on purpose, so an empty one is always worth a word:
  // there is no rich-copy artifact to confuse it with, and this was the one path that attached
  // a zero-byte file and let the send carry it (internal chat builds attachments outside
  // Messages::MessageBuilder, so nothing refuses it on the server either).
  const { files, empty } = splitFilesBySize(event.target.files);
  if (empty.length) useAlert(t('CONVERSATION.FILE_IS_EMPTY'));

  attachedFiles.value = [...attachedFiles.value, ...files];
  if (fileInputRef.value) fileInputRef.value.value = '';
}

function removeFile(index) {
  attachedFiles.value.splice(index, 1);
}

// Paste and drop share the rule with the conversation composer: empty files are dropped, and
// the refusal is said out loud only when the transfer carried no text, which is what tells a
// genuine empty file apart from the invalid zero-byte attachment a rich copy brings along.
// Returns what it took, so a caller can tell "I handled this" from "there was nothing to take".
function addFiles(transfer) {
  const { files, shouldAlertEmpty } = usableFilesFromTransfer(transfer);
  if (shouldAlertEmpty) useAlert(t('CONVERSATION.FILE_IS_EMPTY'));
  if (!files.length) return false;

  attachedFiles.value = [...attachedFiles.value, ...files];
  return true;
}

// The paste is taken over only when something is actually attached. A rich copy carries its
// zero-byte artifact beside the text the person meant to paste, and cancelling the paste for
// that artifact attaches nothing in its place. The text still arrives today because the editor's
// own handler runs before this one, which is ordering rather than a decision made here.
function handlePaste(event) {
  if (!event.clipboardData?.files?.length) return;
  if (!addFiles(event.clipboardData)) return;

  event.preventDefault();
}

function hasFileDrag(event) {
  return event.dataTransfer?.types?.includes('Files');
}

function handleDragEnter(event) {
  if (!hasFileDrag(event)) return;
  event.preventDefault();
  dragCounter += 1;
  isDragging.value = true;
}

function handleDragOver(event) {
  if (!hasFileDrag(event)) return;
  event.preventDefault();
}

function handleDragLeave(event) {
  if (!hasFileDrag(event)) return;
  event.preventDefault();
  dragCounter -= 1;
  if (dragCounter <= 0) {
    dragCounter = 0;
    isDragging.value = false;
  }
}

function handleDrop(event) {
  if (!hasFileDrag(event)) return;
  event.preventDefault();
  dragCounter = 0;
  isDragging.value = false;
  addFiles(event.dataTransfer);
}

function filePreviewUrl(file) {
  return URL.createObjectURL(file);
}

function formatFileSize(file) {
  const bytes = file.size || 0;
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${Math.round(bytes / k ** i)} ${sizes[i]}`;
}

function focus() {
  focusEditor();
}

function setContent(content) {
  editorContent.value = content;
}

function getContent() {
  return editorContent.value;
}

onBeforeUnmount(() => {
  if (draftTimer) {
    clearTimeout(draftTimer);
    draftTimer = null;
    // Flush pending draft before unmounting
    emit('draftUpdate', editorContent.value);
  }
});

defineExpose({ focus, setContent, getContent });
</script>

<template>
  <div
    class="relative border-t border-n-slate-5 bg-n-solid-2 px-4 py-3"
    @paste="handlePaste"
    @dragenter="handleDragEnter"
    @dragover="handleDragOver"
    @dragleave="handleDragLeave"
    @drop="handleDrop"
  >
    <transition name="modal-fade">
      <div
        v-show="isDragging"
        class="pointer-events-none absolute inset-0 z-20 m-2 flex flex-col items-center justify-center gap-1 rounded-lg border-2 border-dashed border-n-brand bg-n-solid-2/90 text-n-brand"
      >
        <Icon icon="i-lucide-upload-cloud" class="size-6" />
        <span class="text-sm font-medium">
          {{ t('INTERNAL_CHAT.MESSAGE.DRAG_DROP') }}
        </span>
      </div>
    </transition>
    <div
      v-if="editingMessage"
      class="flex items-center justify-between border-b border-n-slate-5 px-3 py-1.5 text-xs text-n-brand"
    >
      <span class="flex items-center gap-1">
        <Icon icon="i-lucide-pencil" class="size-3" />
        {{ t('INTERNAL_CHAT.MESSAGE.EDITING') }}
      </span>
      <button class="text-n-slate-11 hover:text-n-slate-12" @click="cancelEdit">
        <Icon icon="i-lucide-x" class="size-3.5" />
      </button>
    </div>
    <label
      v-if="showAlsoSendInChannel"
      class="flex cursor-pointer items-center gap-1.5 px-1 pb-1 text-xs text-n-slate-10"
    >
      <input
        v-model="alsoSendInChannel"
        type="checkbox"
        class="rounded border-n-slate-6"
      />
      {{ t('INTERNAL_CHAT.THREAD.ALSO_SEND_IN_CHANNEL') }}
    </label>
    <!-- Attached files preview -->
    <div v-if="attachedFiles.length" class="mb-1 flex flex-col gap-1 px-1">
      <div
        v-for="(file, index) in attachedFiles"
        :key="index"
        class="flex w-full items-center gap-1.5 rounded-md bg-n-slate-3 p-1.5 sm:w-60"
      >
        <div class="flex-shrink-0">
          <img
            v-if="file.type?.startsWith('image/')"
            :src="filePreviewUrl(file)"
            class="size-8 rounded object-cover"
          />
          <span v-else class="flex size-8 items-center justify-center text-lg">
            📄
          </span>
        </div>
        <div class="min-w-0 flex-1">
          <div class="truncate text-xs font-medium text-n-slate-12">
            {{ file.name }}
          </div>
          <div class="text-[10px] text-n-slate-10">
            {{ formatFileSize(file) }}
          </div>
        </div>
        <button
          type="button"
          class="flex-shrink-0 rounded p-1 text-n-slate-10 hover:bg-n-alpha-2 hover:text-n-ruby-11"
          @click="removeFile(index)"
        >
          <Icon icon="i-lucide-x" class="size-4" />
        </button>
      </div>
    </div>
    <div
      class="flex items-end gap-2 rounded-lg border border-n-slate-6 bg-n-solid-1 px-3 py-2"
      @keydown.capture="handleKeyDown"
    >
      <div class="flex-1 min-w-0">
        <WootWriter
          ref="editorRef"
          v-model:model-value="editorContent"
          channel-type="Context::Default"
          :placeholder="placeholder || t('INTERNAL_CHAT.MESSAGE.PLACEHOLDER')"
          enable-suggestions
          enable-mention-dropdown
          enable-conversation-mention
          :enable-variables="false"
          :enable-canned-responses="false"
          :enable-captain-tools="false"
          :enable-copilot="false"
          :allow-signature="false"
          focus-on-mount
          @typing-on="handleTypingOn"
          @toggle-user-mention="handleToggleUserMention"
          @toggle-conversation-mention="handleToggleConversationMention"
        />
      </div>
      <input
        ref="fileInputRef"
        type="file"
        multiple
        class="hidden"
        @change="handleFileChange"
      />
      <button
        type="button"
        class="flex-shrink-0 flex items-center justify-center rounded-lg p-2 md:p-1.5 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 transition-colors"
        :title="t('INTERNAL_CHAT.MESSAGE.UPLOAD_FILE')"
        @click="openFilePicker"
      >
        <Icon icon="i-lucide-paperclip" class="size-4" />
      </button>
      <!-- Mention shortcuts are hidden on the narrowest screens: they only type
      a character the on-screen keyboard already offers, and the room they take
      is worth more to the editor itself. -->
      <button
        type="button"
        class="flex-shrink-0 hidden sm:flex items-center justify-center rounded-lg p-2 md:p-1.5 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 transition-colors"
        :title="t('INTERNAL_CHAT.MESSAGE.MENTION_USER')"
        @click="insertMentionTrigger('@')"
      >
        <Icon icon="i-lucide-at-sign" class="size-4" />
      </button>
      <button
        type="button"
        class="flex-shrink-0 hidden sm:flex items-center justify-center rounded-lg p-2 md:p-1.5 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 transition-colors"
        :title="t('INTERNAL_CHAT.MESSAGE.MENTION_CONVERSATION')"
        @click="insertMentionTrigger('#')"
      >
        <Icon icon="i-lucide-hash" class="size-4" />
      </button>
      <button
        v-if="showPoll"
        type="button"
        class="flex-shrink-0 flex items-center justify-center rounded-lg p-2 md:p-1.5 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 transition-colors"
        :title="t('INTERNAL_CHAT.POLL.CREATE')"
        @click="emit('createPoll')"
      >
        <Icon icon="i-lucide-bar-chart-2" class="size-4" />
      </button>
      <button
        type="button"
        class="flex-shrink-0 flex items-center justify-center rounded-lg p-2 md:p-1.5 transition-colors"
        :class="
          canSend
            ? 'bg-n-brand text-white hover:opacity-90'
            : 'text-n-slate-9 cursor-not-allowed'
        "
        :disabled="!canSend"
        :title="t('INTERNAL_CHAT.MESSAGE.SEND')"
        @click="handleSend"
      >
        <Icon icon="i-lucide-send-horizontal" class="size-4" />
      </button>
    </div>
  </div>
</template>
