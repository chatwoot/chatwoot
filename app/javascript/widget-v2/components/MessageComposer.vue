<script setup>
import { ref } from 'vue';

const props = defineProps({
  placeholder: { type: String, default: '' },
  allowAttachments: { type: Boolean, default: true },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['send', 'attach', 'typingOn', 'typingOff']);

const content = ref('');
const textareaRef = ref(null);
const fileInputRef = ref(null);

let typingTimer = null;
const TYPING_DEBOUNCE = 2000;

const onInput = () => {
  const el = textareaRef.value;
  if (el) {
    el.style.height = 'auto';
    el.style.height = `${Math.min(el.scrollHeight, 120)}px`;
  }

  if (!typingTimer) emit('typingOn');
  clearTimeout(typingTimer);
  typingTimer = setTimeout(() => {
    typingTimer = null;
    emit('typingOff');
  }, TYPING_DEBOUNCE);
};

const send = () => {
  const trimmed = content.value.trim();
  if (!trimmed || props.disabled) return;
  emit('send', trimmed);
  content.value = '';
  if (textareaRef.value) textareaRef.value.style.height = 'auto';
};

const onKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    send();
  }
};

const onFileChange = event => {
  const [file] = event.target.files;
  if (file) emit('attach', file);
  event.target.value = '';
};
</script>

<template>
  <div class="glass-layer px-4 pb-4 pt-2 bg-cw-solid">
    <div
      class="flex items-end gap-1 p-1.5 rounded-token border border-cw-border bg-cw-solid shadow-sm transition-shadow focus-within:ring-[3px] focus-within:ring-cw-ring focus-within:border-transparent"
    >
      <button
        v-if="allowAttachments"
        type="button"
        class="flex items-center justify-center w-8 h-8 shrink-0 rounded-full text-cw-text-faint hover:text-cw-text-muted hover:bg-cw-muted outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :aria-label="$t('CONVERSATION.ATTACH')"
        @click="fileInputRef.click()"
      >
        <span class="i-ph-plus text-lg" />
      </button>
      <input
        ref="fileInputRef"
        type="file"
        class="hidden"
        @change="onFileChange"
      />

      <textarea
        ref="textareaRef"
        v-model="content"
        rows="1"
        :placeholder="placeholder || $t('CONVERSATION.PLACEHOLDER')"
        :disabled="disabled"
        class="flex-1 max-h-32 py-1.5 px-1 text-base bg-transparent text-cw-text placeholder:text-cw-text-faint resize-none outline-none border-none"
        @input="onInput"
        @keydown="onKeydown"
        @blur="emit('typingOff')"
      />

      <button
        type="button"
        class="flex items-center justify-center w-8 h-8 shrink-0 rounded-full transition-colors outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :class="
          content.trim()
            ? 'bg-cw-primary text-cw-primary-foreground hover:bg-cw-primary-strong'
            : 'text-cw-text-faint'
        "
        :disabled="!content.trim() || disabled"
        :aria-label="$t('CONVERSATION.SEND')"
        @click="send"
      >
        <span class="i-ph-arrow-up text-lg" />
      </button>
    </div>
  </div>
</template>
