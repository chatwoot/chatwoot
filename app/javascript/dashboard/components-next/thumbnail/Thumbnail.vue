<script setup>
import { computed } from 'vue';
import { removeEmoji } from 'shared/helpers/emoji';

import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const props = defineProps({
  author: {
    type: Object,
    default: null,
  },
  name: {
    type: String,
    default: '',
  },
  src: {
    type: String,
    default: '',
  },
  size: {
    type: Number,
    default: 16,
  },
});

const authorInitial = computed(() => {
  if (!props.name) return '';
  const name = removeEmoji(props.name);
  const words = name.split(/\s+/);

  if (words.length === 1) {
    return name.substring(0, 2).toUpperCase();
  }

  return words
    .slice(0, 2)
    .map(word => word[0])
    .join('')
    .toUpperCase();
});
</script>

<template>
  <div
    class="rounded-full bg-slate-100 dark:bg-slate-700/50"
    :style="{ width: `${size}px`, height: `${size}px` }"
  >
    <div v-if="author">
      <img
        v-if="src"
        :src="src"
        :alt="name"
        class="w-full h-full rounded-full"
      />
      <span
        v-else-if="name"
        class="flex items-center justify-center font-medium text-xxs text-slate-500 dark:text-slate-400"
      >
        {{ authorInitial }}
      </span>
    </div>
    <div
      v-else
      class="flex items-center justify-center w-4 h-4 rounded-full bg-slate-100 dark:bg-slate-700/50"
    >
      <FluentIcon
        icon="person"
        type="filled"
        size="10"
        class="text-woot-500 dark:text-woot-400"
      />
    </div>
  </div>
</template>
