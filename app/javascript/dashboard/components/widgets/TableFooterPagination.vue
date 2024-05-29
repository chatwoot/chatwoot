<template>
  <div class="flex items-center bg-slate-50 dark:bg-slate-800 h-8 rounded-lg">
    <woot-button
      size="small"
      variant="smooth"
      color-scheme="secondary"
      :is-disabled="hasFirstPage"
      class-names="dark:!bg-slate-800 !opacity-100 ltr:rounded-l-lg ltr:rounded-r-none rtl:rounded-r-lg rtl:rounded-l-none"
      :class="buttonClass(hasFirstPage)"
      @click="onFirstPage"
    >
      <fluent-icon
        icon="chevrons-left"
        size="20"
        icon-lib="lucide"
        :class="hasFirstPage && 'opacity-40'"
      />
    </woot-button>
    <div class="bg-slate-75 dark:bg-slate-700/50 w-px rounded-sm h-4" />
    <woot-button
      size="small"
      variant="smooth"
      color-scheme="secondary"
      :is-disabled="hasPrevPage"
      class-names="dark:!bg-slate-800 !opacity-100 rounded-none"
      :class="buttonClass(hasPrevPage)"
      @click="onPrevPage"
    >
      <fluent-icon
        icon="chevron-left-single"
        size="20"
        icon-lib="lucide"
        :class="hasPrevPage && 'opacity-40'"
      />
    </woot-button>

    <div
      class="flex px-3 items-center gap-3 tabular-nums bg-slate-50 dark:bg-slate-800 text-slate-700 dark:text-slate-100"
    >
      <span class="text-sm text-slate-800 dark:text-slate-75">
        {{ currentPage }}
      </span>
      <span class="text-slate-600 dark:text-slate-500">/</span>
      <span class="text-sm text-slate-600 dark:text-slate-500">
        {{ totalPages }}
      </span>
    </div>
    <woot-button
      size="small"
      variant="smooth"
      color-scheme="secondary"
      :is-disabled="hasNextPage"
      class-names="dark:!bg-slate-800 !opacity-100 rounded-none"
      :class="buttonClass(hasNextPage)"
      @click="onNextPage"
    >
      <fluent-icon
        icon="chevron-right-single"
        size="20"
        icon-lib="lucide"
        :class="hasNextPage && 'opacity-40'"
      />
    </woot-button>
    <div class="bg-slate-75 dark:bg-slate-700/50 w-px rounded-sm h-4" />
    <woot-button
      size="small"
      variant="smooth"
      color-scheme="secondary"
      class-names="dark:!bg-slate-800 !opacity-100 ltr:rounded-r-lg ltr:rounded-l-none rtl:rounded-l-lg rtl:rounded-r-none"
      :class="buttonClass(hasLastPage)"
      :is-disabled="hasLastPage"
      @click="onLastPage"
    >
      <fluent-icon
        icon="chevrons-right"
        size="20"
        icon-lib="lucide"
        :class="hasLastPage && 'opacity-40'"
      />
    </woot-button>
  </div>
</template>

<script setup>
import { computed } from 'vue';

// Props
const props = defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  totalCount: {
    type: Number,
    default: 0,
  },
  totalPages: {
    type: Number,
    default: 0,
  },
});

const hasLastPage = computed(
  () => props.currentPage === props.totalPages || props.totalPages === 1
);
const hasFirstPage = computed(() => props.currentPage === 1);
const hasNextPage = computed(() => props.currentPage === props.totalPages);
const hasPrevPage = computed(() => props.currentPage === 1);

const emit = defineEmits(['page-change']);

function buttonClass(hasPage) {
  if (hasPage) {
    return 'hover:!bg-slate-50 dark:hover:!bg-slate-800';
  }
  return 'dark:hover:!bg-slate-700/50';
}

function onPageChange(newPage) {
  emit('page-change', newPage);
}

const onNextPage = () => {
  if (!onNextPage.value) {
    onPageChange(props.currentPage + 1);
  }
};
const onPrevPage = () => {
  if (!hasPrevPage.value) {
    onPageChange(props.currentPage - 1);
  }
};
const onFirstPage = () => {
  if (!hasFirstPage.value) {
    onPageChange(1);
  }
};
const onLastPage = () => {
  if (!hasLastPage.value) {
    onPageChange(props.totalPages);
  }
};
</script>
