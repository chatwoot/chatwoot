<script setup>
import { computed, ref } from 'vue';
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
const hasImageLoaded = ref(false);
const imgError = ref(false);

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

const fontSize = computed(() => {
  return props.size / 2;
});

const shouldShowImage = computed(() => {
  if (!props.src) {
    return false;
  }
  if (hasImageLoaded.value) {
    return !imgError.value;
  }
  return false;
});

const onImgError = () => {
  imgError.value = true;
};

const onImgLoad = () => {
  hasImageLoaded.value = true;
};
</script>

<template>
  <div
    class="flex items-center justify-center rounded-full bg-slate-100 dark:bg-slate-700/50"
    :style="{ width: `${size}px`, height: `${size}px` }"
  >
    <div v-if="author">
      <img
        v-show="shouldShowImage"
        :src="src"
        :alt="name"
        class="w-full h-full rounded-full"
        @load="onImgLoad"
        @error="onImgError"
      />
      <span
        v-show="!shouldShowImage"
        class="flex items-center justify-center font-medium text-slate-500 dark:text-slate-400"
        :style="{ fontSize: `${fontSize}px` }"
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
