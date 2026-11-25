<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { QUICK_EMOJIS, findOwnReaction } from './reactions';

const props = defineProps({
  reactions: {
    type: Array,
    default: () => [],
  },
  currentUserId: {
    type: Number,
    default: null,
  },
});

const emit = defineEmits(['select', 'remove', 'close']);

const { t } = useI18n();

const isOpen = ref(false);

function toggle() {
  isOpen.value = !isOpen.value;
}

function selectEmoji(emoji) {
  const existingReaction = findOwnReaction(
    props.reactions,
    emoji,
    props.currentUserId
  );
  if (existingReaction) {
    emit('remove', existingReaction.id);
  } else {
    emit('select', emoji);
  }
  isOpen.value = false;
}

function close() {
  isOpen.value = false;
  emit('close');
}
</script>

<template>
  <div class="relative">
    <button
      class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
      @click="toggle"
    >
      <Icon icon="i-lucide-smile-plus" class="size-4" />
    </button>
    <div
      v-if="isOpen"
      v-on-click-outside="close"
      class="absolute bottom-full right-0 z-50 mb-1 grid w-max max-w-[11rem] grid-cols-4 gap-1 rounded-lg border border-n-slate-6 bg-n-solid-2 p-2 shadow-lg"
    >
      <button
        v-for="item in QUICK_EMOJIS"
        :key="item.labelKey"
        class="flex items-center justify-center rounded p-1 text-base hover:bg-n-alpha-2"
        :title="t(`INTERNAL_CHAT.REACTIONS.${item.labelKey}`)"
        @click="selectEmoji(item.emoji)"
      >
        {{ item.emoji }}
      </button>
    </div>
  </div>
</template>
