<script setup>
import CardLayout from './components/CardLayout.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';
defineProps({
  locale: {
    type: String,
    required: true,
  },
  isDefault: {
    type: Boolean,
    required: true,
  },
});
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout class="ltr:pr-2 rtl:pl-2">
    <template #header>
      <div class="flex justify-between gap-2">
        <div class="flex items-center justify-start gap-2">
          <span
            class="text-base font-medium text-slate-900 dark:text-slate-50 line-clamp-1"
          >
            {{ locale }}
          </span>
          <span
            v-if="isDefault"
            class="bg-slate-100 dark:bg-slate-800 h-6 inline-flex items-center justify-center rounded-md text-xs border-px border-transparent text-woot-500 dark:text-woot-400 px-2 py-0.5"
          >
            Default
          </span>
        </div>
        <div class="flex items-center justify-end gap-1">
          <div class="flex items-center gap-4">
            <span
              class="text-sm text-slate-500 dark:text-slate-400 whitespace-nowrap"
            >
              29 articles
            </span>
            <div class="w-px h-3 bg-slate-200 dark:bg-slate-700" />
            <span
              class="text-sm text-slate-500 dark:text-slate-400 whitespace-nowrap"
            >
              5 categories
            </span>
          </div>
          <ButtonV4 variant="ghost" size="icon" icon="more-vertical" />
        </div>
      </div>
    </template>
  </CardLayout>
</template>
