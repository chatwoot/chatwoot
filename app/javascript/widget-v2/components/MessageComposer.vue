<script setup>
import { computed, defineAsyncComponent, nextTick, ref } from 'vue';
import { onClickOutside } from '@vueuse/core';
import { useConfigStore } from 'widget-v2/stores/config';

const props = defineProps({
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['send', 'attach', 'typingOn', 'typingOff']);

// The emoji set is ~170 KB of JSON; keep it out of the widget's initial load
// and fetch it only when someone opens the picker.
const EmojiPicker = defineAsyncComponent(
  () => import('widget-v2/components/EmojiPicker.vue')
);

// Attachments and emoji are per-inbox toggles in the dashboard.
const configStore = useConfigStore();
const features = computed(() => configStore.channel.enabled_features || []);
const allowAttachments = computed(() => features.value.includes('attachments'));
const allowEmoji = computed(() => features.value.includes('emoji_picker'));

const content = ref('');
const textareaRef = ref(null);
const fileInputRef = ref(null);
const composerRef = ref(null);
// null | 'menu' | 'emoji' — the plus button opens the menu, which opens the
// picker; only one popover is ever on screen.
const popover = ref(null);

onClickOutside(composerRef, () => {
  popover.value = null;
});

const MAX_HEIGHT = 128;
let typingTimer = null;
const TYPING_DEBOUNCE = 2000;

const resize = () => {
  const el = textareaRef.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = `${Math.min(el.scrollHeight, MAX_HEIGHT)}px`;
};

const onInput = () => {
  resize();

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
  if (event.key === 'Escape' && popover.value) {
    popover.value = null;
    return;
  }
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

const pickFile = () => {
  popover.value = null;
  fileInputRef.value.click();
};

const insertEmoji = async emoji => {
  const el = textareaRef.value;
  const caret = el?.selectionStart ?? content.value.length;
  content.value =
    content.value.slice(0, caret) + emoji + content.value.slice(caret);
  popover.value = null;

  // Put the caret back after the emoji so typing continues where it left off.
  await nextTick();
  el?.focus();
  el?.setSelectionRange(caret + emoji.length, caret + emoji.length);
  resize();
};
</script>

<template>
  <div
    ref="composerRef"
    class="glass-layer relative px-4 pb-4 pt-2 bg-cw-solid"
  >
    <EmojiPicker
      v-if="popover === 'emoji'"
      class="mx-4"
      @select="insertEmoji"
    />

    <div
      v-else-if="popover === 'menu'"
      class="surface-card absolute bottom-full start-4 z-20 mb-2 w-44 p-1"
    >
      <button
        v-if="allowEmoji"
        type="button"
        class="flex items-center w-full gap-2 px-2 py-2 text-sm text-cw-text rounded-token-sm hover:bg-cw-muted outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        @click="popover = 'emoji'"
      >
        <span class="i-ph-smiley text-lg text-cw-text-muted" />
        {{ $t('CONVERSATION.ADD_EMOJI') }}
      </button>
      <button
        v-if="allowAttachments"
        type="button"
        class="flex items-center w-full gap-2 px-2 py-2 text-sm text-cw-text rounded-token-sm hover:bg-cw-muted outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        @click="pickFile"
      >
        <span class="i-ph-paperclip text-lg text-cw-text-muted" />
        {{ $t('CONVERSATION.ATTACH') }}
      </button>
    </div>

    <div
      class="flex items-end gap-1 p-1.5 rounded-token border border-cw-border bg-cw-solid shadow-sm transition-shadow focus-within:ring-[3px] focus-within:ring-cw-ring focus-within:border-transparent"
    >
      <button
        v-if="allowEmoji || allowAttachments"
        type="button"
        class="flex items-center justify-center w-8 h-8 shrink-0 rounded-full transition-colors outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :class="
          popover
            ? 'bg-cw-muted text-cw-text'
            : 'text-cw-text-faint hover:text-cw-text-muted hover:bg-cw-muted'
        "
        :aria-label="$t('CONVERSATION.ADD')"
        :aria-expanded="Boolean(popover)"
        @click="popover = popover ? null : 'menu'"
      >
        <span class="i-ph-plus text-lg" />
      </button>
      <input
        ref="fileInputRef"
        type="file"
        class="hidden"
        @change="onFileChange"
      />

      <!-- 16px text on 24px leading plus py-1 is exactly the 32px button box,
           so an empty composer lines all three controls up on one row. -->
      <textarea
        ref="textareaRef"
        v-model="content"
        rows="1"
        :placeholder="placeholder || $t('CONVERSATION.PLACEHOLDER')"
        :disabled="disabled"
        class="flex-1 max-h-32 py-1 px-1 text-base leading-6 bg-transparent text-cw-text placeholder:text-cw-text-faint resize-none outline-none border-none"
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
