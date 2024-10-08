<script setup>
import ButtonV4 from 'dashboard/playground/components/Button.vue';
import { computed } from 'vue';

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

const emit = defineEmits(['update:currentPage', 'update:itemsPerPage']);

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

const changeItemsPerPage = newItemsPerPage => {
  emit('update:itemsPerPage', newItemsPerPage);
};
</script>

<!-- TODO: Use i18n -->
<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div
    class="flex justify-between h-12 w-full max-w-[957px] mx-auto bg-slate-25 dark:bg-slate-800/50 rounded-xl py-2 px-3 items-center"
  >
    <div class="flex items-center gap-3">
      <ButtonV4
        icon="chevron-lucide-down"
        icon-lib="lucide"
        icon-position="right"
        variant="secondary"
        size="sm"
        class="font-normal rounded-md"
        :label="`${itemsPerPage} / page`"
        @click="changeItemsPerPage(itemsPerPage === 16 ? 32 : 16)"
      />
      <span class="text-base font-normal text-slate-500 dark:text-slate-400">
        Showing {{ startItem }} - {{ endItem }} of {{ totalItems }} items
      </span>
    </div>
    <div class="flex items-center gap-2">
      <ButtonV4
        icon="chevrons-lucide-left"
        icon-lib="lucide"
        variant="ghost"
        size="sm"
        :disabled="isFirstPage"
        @click="changePage(1)"
      />
      <ButtonV4
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
        <span class="px-3 py-0.5 bg-white dark:bg-slate-900 rounded-md">{{
          currentPage
        }}</span>
        <span>of</span>
        <span>{{ totalPages }}</span>
        <span>pages</span>
      </div>
      <ButtonV4
        icon="chevron-lucide-right"
        icon-lib="lucide"
        variant="ghost"
        size="sm"
        :disabled="isLastPage"
        @click="changePage(currentPage + 1)"
      />
      <ButtonV4
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
