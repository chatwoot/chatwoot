<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import MobileBackButton from './MobileBackButton.vue';

const props = defineProps({
  name: {
    type: String,
    default: '',
  },
  avatar: {
    type: String,
    default: '',
  },
  status: {
    type: String,
    default: 'open',
  },
});

const emit = defineEmits(['back', 'refresh', 'openActions']);

const statusIcon = computed(() => {
  if (props.status === 'resolved') return 'i-lucide-check-check';
  if (props.status === 'pending') return 'i-lucide-circle-dot-dashed';
  if (props.status === 'snoozed') return 'i-lucide-moon-star';
  return 'i-lucide-refresh-cw';
});
</script>

<template>
  <header
    class="flex items-center justify-between gap-3 border-b border-n-weak bg-white px-3 py-2 pt-[env(safe-area-inset-top)] dark:bg-n-background"
  >
    <div class="flex min-w-0 flex-1 items-center gap-2">
      <MobileBackButton @click="emit('back')" />
      <Avatar :src="avatar" :name="name" :size="34" class="shrink-0" />
      <h2 class="truncate text-[1.05rem] font-semibold text-n-slate-12">
        {{ name }}
      </h2>
    </div>

    <div class="flex items-center gap-3 text-n-slate-11">
      <button
        class="flex size-9 items-center justify-center rounded-full active:bg-n-alpha-2"
        @click="emit('refresh')"
      >
        <span class="size-5" :class="statusIcon" />
      </button>
      <button
        class="flex size-9 items-center justify-center rounded-full active:bg-n-alpha-2"
        @click="emit('openActions')"
      >
        <span class="i-lucide-ellipsis size-5" />
      </button>
    </div>
  </header>
</template>
