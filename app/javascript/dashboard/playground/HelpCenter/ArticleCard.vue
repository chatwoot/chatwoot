<script setup>
import { computed } from 'vue';
import CardLayout from './components/CardLayout.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    required: true,
  },
  author: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    required: true,
  },
  views: {
    type: Number,
    required: true,
  },
  updatedAt: {
    type: String,
    required: true,
  },
});

const statusTextColor = computed(() => {
  switch (props.status) {
    case 'archived':
      return 'text-slate-600 dark:text-slate-200';
    case 'draft':
      return 'text-amber-500 dark:text-amber-400';
    default:
      return 'text-teal-500 dark:text-teal-400';
  }
});

const statusText = computed(() => {
  switch (props.status) {
    case 'archived':
      return 'Archived';
    case 'draft':
      return 'Draft';
    default:
      return 'Published';
  }
});
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout>
    <template #header>
      <div class="flex justify-between gap-1">
        <span class="text-base text-slate-900 dark:text-slate-50 line-clamp-1">
          {{ title }}
        </span>
        <span
          class="text-xs bg-slate-100 text-center h-6 inline-flex items-center justify-center dark:bg-slate-800 rounded-md border-px border-transparent px-2 py-0.5"
          :class="statusTextColor"
        >
          {{ statusText }}
        </span>
      </div>
    </template>
    <template #footer>
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1">
            <div class="w-4 h-4 rounded-full bg-slate-200 dark:bg-slate-700" />
            <span class="text-sm text-slate-500 dark:text-slate-400">
              {{ author }}
            </span>
          </div>
          <span
            class="block text-sm whitespace-nowrap text-slate-500 dark:text-slate-400"
          >
            {{ category }}
          </span>
          <div
            class="inline-flex items-center gap-1 text-slate-500 dark:text-slate-400 whitespace-nowrap"
          >
            <FluentIcon icon="eye-show" size="18" />
            <span class="text-sm"> {{ views }} views </span>
          </div>
        </div>
        <span class="text-sm text-slate-600 dark:text-slate-400 line-clamp-1">
          {{ updatedAt }}
        </span>
      </div>
    </template>
  </CardLayout>
</template>
