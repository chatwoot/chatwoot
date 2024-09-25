<script setup>
import CardLayout from './components/CardLayout.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

defineProps({
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
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout>
    <template #header>
      <div class="flex gap-2">
        <div class="flex justify-between">
          <div class="flex items-center justify-start gap-2">
            <span
              class="text-base text-slate-900 dark:text-slate-50 line-clamp-1"
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
      <span class="text-sm text-slate-500 dark:text-slate-400 line-clamp-3">
        {{ description }}
      </span>
    </template>
  </CardLayout>
</template>
