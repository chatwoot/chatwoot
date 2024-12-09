<script setup>
import { computed } from 'vue';
const props = defineProps({
  table: {
    type: Object,
    required: true,
  },
});

const getFormattedPages = (start, end) => {
  const formatter = new Intl.NumberFormat(navigator.language);
  return Array.from({ length: end - start + 1 }, (_, i) =>
    formatter.format(start + i)
  );
};

const currentPage = computed(() => {
  return props.table.getState().pagination.pageIndex + 1;
});

const totalPages = computed(() => {
  return props.table.getPageCount();
});

const visiblePages = computed(() => {
  if (totalPages.value <= 3) return getFormattedPages(1, totalPages.value);
  if (currentPage.value === 1) return getFormattedPages(1, 3);
  if (currentPage.value === totalPages.value) {
    return getFormattedPages(totalPages.value - 2, totalPages.value);
  }

  return getFormattedPages(currentPage.value - 1, currentPage.value + 1);
});

const total = computed(() => {
  return props.table.getRowCount();
});

const start = computed(() => {
  const { pagination } = props.table.getState();
  return pagination.pageIndex * pagination.pageSize + 1;
});

const end = computed(() => {
  const { pagination } = props.table.getState();
  return Math.min(
    (pagination.pageIndex + 1) * pagination.pageSize,
    total.value
  );
});
</script>

<template>
  <div class="flex items-center justify-between">
    <div class="flex flex-1 items-center justify-between">
      <div>
        <p class="text-sm text-n-slate-11 mb-0">
          {{ $t('REPORT.PAGINATION.RESULTS', { start, end, total }) }}
        </p>
      </div>
      <nav class="isolate inline-flex gap-1">
        <woot-button
          :disabled="!table.getCanPreviousPage()"
          variant="clear"
          class="h-8 border-0 flex items-center"
          color-scheme="secondary"
          @click="table.setPageIndex(0)"
        >
          <span class="i-lucide-chevrons-left size-3" aria-hidden="true" />
        </woot-button>
        <woot-button
          variant="clear"
          class="h-8 border-0 flex items-center"
          color-scheme="secondary"
          :disabled="!table.getCanPreviousPage()"
          @click="table.previousPage()"
        >
          <span class="i-lucide-chevron-left size-3" aria-hidden="true" />
        </woot-button>
        <woot-button
          v-for="page in visiblePages"
          :key="page"
          variant="clear"
          class="h-8 flex items-center justify-center text-xs leading-none text-center"
          :class="page == currentPage ? 'border-n-brand' : 'border-slate-50'"
          color-scheme="secondary"
          @click="table.setPageIndex(page - 1)"
        >
          <span
            class="text-center"
            :class="{ 'text-n-brand': page == currentPage }"
          >
            {{ page }}
          </span>
        </woot-button>
        <woot-button
          :disabled="!table.getCanNextPage()"
          variant="clear"
          class="h-8 border-0 flex items-center"
          color-scheme="secondary"
          @click="table.nextPage()"
        >
          <span class="i-lucide-chevron-right size-3" aria-hidden="true" />
        </woot-button>
        <woot-button
          :disabled="!table.getCanNextPage()"
          variant="clear"
          class="h-8 border-0 flex items-center"
          color-scheme="secondary"
          @click="table.setPageIndex(table.getPageCount() - 1)"
        >
          <span class="i-lucide-chevrons-right size-3" aria-hidden="true" />
        </woot-button>
      </nav>
    </div>
  </div>
</template>
