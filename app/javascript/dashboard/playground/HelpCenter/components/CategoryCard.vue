<script setup>
import { computed } from 'vue';
import CardLayout from './CardLayout.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  articlesCount: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['click']);

const description = computed(() => {
  return props.description ? props.description : 'No description added';
});

const hasDescription = computed(() => {
  return props.description.length > 0;
});

const handleClick = id => {
  emit('click', id);
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout class="group" @click="handleClick(id)">
    <template #header>
      <div class="flex gap-2">
        <div class="flex justify-between">
          <div class="flex items-center justify-start gap-2">
            <span
              class="text-base cursor-pointer group-hover:underline text-slate-900 dark:text-slate-50 line-clamp-1"
            >
              {{ title }}
            </span>
            <span
              class="inline-flex items-center justify-center h-6 px-2 py-1 text-xs text-center border rounded-lg text-slate-500 w-fit border-slate-200 dark:border-slate-800 dark:text-slate-400"
            >
              {{ articlesCount }} articles
            </span>
          </div>
          <ButtonV4
            variant="ghost"
            size="icon"
            icon="more-vertical"
            class="absolute right-2 top-2"
          />
        </div>
      </div>
    </template>
    <template #footer>
      <span
        class="text-sm line-clamp-3"
        :class="
          hasDescription
            ? 'text-slate-500 dark:text-slate-400'
            : 'text-slate-400 dark:text-slate-700'
        "
      >
        {{ description }}
      </span>
    </template>
  </CardLayout>
</template>
