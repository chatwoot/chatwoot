<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useEventListener } from '@vueuse/core';
import { Dropdown } from 'floating-vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import EmojiPicker from 'shared/components/emoji/EmojiPicker.vue';

const props = defineProps({
  alignment: {
    type: String,
    default: 'right',
    validator: value => ['left', 'right'].includes(value),
  },
  currentUserEmoji: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['select', 'update:open']);

const { t } = useI18n();

const QUICK_EMOJIS = [
  { emoji: '👍', labelKey: 'CONVERSATION.REACTIONS.QUICK.THUMBS_UP' },
  { emoji: '❤️', labelKey: 'CONVERSATION.REACTIONS.QUICK.HEART' },
  { emoji: '😂', labelKey: 'CONVERSATION.REACTIONS.QUICK.JOY' },
  { emoji: '😮', labelKey: 'CONVERSATION.REACTIONS.QUICK.SURPRISED' },
  { emoji: '😢', labelKey: 'CONVERSATION.REACTIONS.QUICK.SAD' },
  { emoji: '🙏', labelKey: 'CONVERSATION.REACTIONS.QUICK.PRAY' },
  { emoji: '🔥', labelKey: 'CONVERSATION.REACTIONS.QUICK.FIRE' },
  { emoji: '🎉', labelKey: 'CONVERSATION.REACTIONS.QUICK.PARTY' },
];

const isOpen = ref(false);
const showFullPicker = ref(false);

function close() {
  isOpen.value = false;
  showFullPicker.value = false;
}

function toggle() {
  if (isOpen.value) {
    close();
  } else {
    isOpen.value = true;
  }
}

function pickEmoji(emoji) {
  if (!emoji) return;
  emit('select', emoji);
  close();
}

// EmojiPicker emits `select` with { type, value, emoji }; unwrap to the emoji string.
function onSelectEmoji({ value }) {
  pickEmoji(value);
}

function openFullPicker() {
  showFullPicker.value = true;
}

watch(isOpen, value => emit('update:open', value));

// Switching apps / Alt-Tab fires window blur but not a click event, so
// the dropdown's auto-hide cannot reach it. Without this the picker stays
// open in the background and reappears on next hover.
useEventListener(window, 'blur', close);

// Close the picker when the message list scrolls so the popover does not
// drift visually away from the anchoring message.
onMounted(() => emitter.on(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL, close));
onBeforeUnmount(() => emitter.off(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL, close));
</script>

<template>
  <Dropdown
    :shown="isOpen"
    :triggers="[]"
    auto-hide
    theme="naked-popover"
    :placement="props.alignment === 'right' ? 'top-end' : 'top-start'"
    :distance="8"
    popper-class="[&_.v-popper\_\_arrow-container]:hidden"
    @apply-hide="close"
  >
    <button
      type="button"
      class="flex items-center justify-center rounded-full p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
      :title="t('CONVERSATION.REACTIONS.ADD_REACTION')"
      :aria-label="t('CONVERSATION.REACTIONS.ADD_REACTION')"
      :aria-expanded="isOpen"
      aria-haspopup="dialog"
      @click="toggle"
    >
      <Icon icon="i-lucide-smile-plus" class="size-4" />
    </button>
    <template #popper>
      <div
        v-if="!showFullPicker"
        class="flex w-max items-center gap-1 rounded-full border border-n-slate-6 bg-n-solid-2 p-1 shadow-lg"
      >
        <button
          v-for="item in QUICK_EMOJIS"
          :key="item.labelKey"
          type="button"
          class="flex size-7 items-center justify-center rounded-full text-base hover:bg-n-alpha-2"
          :class="{
            'ring-2 ring-n-brand bg-n-alpha-2': item.emoji === currentUserEmoji,
          }"
          :title="
            item.emoji === currentUserEmoji
              ? t('CONVERSATION.REACTIONS.CLICK_TO_REMOVE')
              : t(item.labelKey)
          "
          :aria-label="
            item.emoji === currentUserEmoji
              ? t('CONVERSATION.REACTIONS.CLICK_TO_REMOVE')
              : t(item.labelKey)
          "
          :aria-pressed="item.emoji === currentUserEmoji"
          @click="pickEmoji(item.emoji)"
        >
          {{ item.emoji }}
        </button>
        <button
          type="button"
          class="flex size-7 items-center justify-center rounded-full text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
          :title="t('CONVERSATION.REACTIONS.MORE_EMOJIS')"
          :aria-label="t('CONVERSATION.REACTIONS.MORE_EMOJIS')"
          @click="openFullPicker"
        >
          <Icon icon="i-lucide-plus" class="size-4" />
        </button>
      </div>
      <EmojiPicker
        v-else
        class="!static !top-auto !right-auto !left-auto [&::before]:hidden"
        @select="onSelectEmoji"
      />
    </template>
  </Dropdown>
</template>
