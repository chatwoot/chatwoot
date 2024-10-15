<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    required: true,
  },
  totalItems: {
    type: Number,
    required: true,
  },
  itemsPerPage: {
    type: Number,
    default: 16,
  },
});
const emit = defineEmits(['update:currentPage']);
const { t } = useI18n();

const totalPages = computed(() =>
  Math.ceil(props.totalItems / props.itemsPerPage)
);
const startItem = computed(
  () => (props.currentPage - 1) * props.itemsPerPage + 1
);
const endItem = computed(() =>
  Math.min(startItem.value + props.itemsPerPage - 1, props.totalItems)
);
const isFirstPage = computed(() => props.currentPage === 1);
const isLastPage = computed(() => props.currentPage === totalPages.value);
const changePage = newPage => {
  if (newPage >= 1 && newPage <= totalPages.value) {
    emit('update:currentPage', newPage);
  }
};

const currentPageInformation = computed(() => {
  return t('PAGINATION_FOOTER.SHOWING', {
    startItem: startItem.value,
    endItem: endItem.value,
    totalItems: props.totalItems,
  });
});

const pageInfo = computed(() => {
  return t('PAGINATION_FOOTER.CURRENT_PAGE_INFO', {
    currentPage: '',
    totalPages: totalPages.value,
  });
});
</script>

<template>
  <div
    class="flex justify-between h-12 w-full max-w-[957px] mx-auto bg-slate-25 dark:bg-slate-800/50 rounded-xl py-2 px-3 items-center"
  >
    <div class="flex items-center gap-3">
      <span
        class="min-w-0 text-sm font-normal line-clamp-1 text-slate-600 dark:text-slate-300"
      >
        {{ currentPageInformation }}
      </span>
    </div>
    <div class="flex items-center gap-2">
      <Button
        icon="chevrons-lucide-left"
        icon-lib="lucide"
        variant="ghost"
        size="sm"
        :disabled="isFirstPage"
        @click="changePage(1)"
      />
      <Button
        icon="chevron-lucide-left"
        icon-lib="lucide"
        variant="ghost"
        size="sm"
        :disabled="isFirstPage"
        @click="changePage(currentPage - 1)"
      />
      <div
        class="inline-flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400"
      >
        <span
          class="px-3 tabular-nums py-0.5 bg-white dark:bg-slate-900 rounded-md"
        >
          {{ currentPage }}
        </span>
        <span>{{ pageInfo }}</span>
      </div>
      <Button
        icon="chevron-lucide-right"
        icon-lib="lucide"
        variant="ghost"
        size="sm"
        :disabled="isLastPage"
        @click="changePage(currentPage + 1)"
      />
      <Button
        icon="chevrons-lucide-right"
        icon-lib="lucide"
        variant="ghost"
        size="sm"
        :disabled="isLastPage"
        @click="changePage(totalPages)"
      />
    </div>
  </div>
</template>
