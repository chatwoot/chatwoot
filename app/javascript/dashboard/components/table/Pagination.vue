<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';

const props = defineProps({
  table: {
    type: Object,
    required: true,
  },
  defaultPageSize: {
    type: Number,
    default: 10,
  },
  showPageSizeSelector: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['pageSizeChange']);
const { t } = useI18n();

const pageSizeOptions = [
  {
    label: `${t('REPORT.PAGINATION.PER_PAGE_TEMPLATE', { size: 10 })}`,
    value: 10,
  },
  {
    label: `${t('REPORT.PAGINATION.PER_PAGE_TEMPLATE', { size: 20 })}`,
    value: 20,
  },
  {
    label: `${t('REPORT.PAGINATION.PER_PAGE_TEMPLATE', { size: 50 })}`,
    value: 50,
  },
  {
    label: `${t('REPORT.PAGINATION.PER_PAGE_TEMPLATE', { size: 100 })}`,
    value: 100,
  },
];

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

const currentPageSize = computed({
  get() {
    return props.table.getState().pagination.pageSize;
  },
  set(newValue) {
    props.table.setPageSize(Number(newValue));
    emit('pageSizeChange', Number(newValue));
  },
});

onMounted(() => {
  if (
    props.showPageSizeSelector &&
    props.defaultPageSize &&
    props.defaultPageSize !== 10
  ) {
    props.table.setPageSize(props.defaultPageSize);
  }
});
</script>

<template>
  <div class="flex items-center justify-between">
    <div class="flex flex-1 items-center gap-2 justify-between">
      <p class="text-sm truncate text-n-slate-11 mb-0">
        {{ $t('REPORT.PAGINATION.RESULTS', { start, end, total }) }}
      </p>
      <div class="flex items-center gap-2">
        <FilterSelect
          v-if="showPageSizeSelector"
          v-model="currentPageSize"
          variant="outline"
          hide-icon
          class="[&>button]:text-n-slate-11 [&>button]:hover:text-n-slate-12 [&>button]:h-6"
          :options="pageSizeOptions"
        />
        <nav class="isolate inline-flex items-center gap-1.5">
          <Button
            icon="i-lucide-chevrons-left"
            ghost
            slate
            sm
            class="!size-6"
            :disabled="!table.getCanPreviousPage()"
            @click="table.setPageIndex(0)"
          />
          <Button
            icon="i-lucide-chevron-left"
            ghost
            slate
            sm
            class="!size-6"
            :disabled="!table.getCanPreviousPage()"
            @click="table.previousPage()"
          />
          <Button
            v-for="page in visiblePages"
            :key="page"
            xs
            outline
            :color="page == currentPage ? 'blue' : 'slate'"
            class="!h-6 min-w-6"
            @click="table.setPageIndex(page - 1)"
          >
            <span
              class="text-center"
              :class="{ 'text-n-brand': page == currentPage }"
            >
              {{ page }}
            </span>
          </Button>
          <Button
            icon="i-lucide-chevron-right"
            ghost
            slate
            sm
            class="!size-6"
            :disabled="!table.getCanNextPage()"
            @click="table.nextPage()"
          />
          <Button
            icon="i-lucide-chevrons-right"
            ghost
            slate
            sm
            class="!size-6"
            :disabled="!table.getCanNextPage()"
            @click="table.setPageIndex(table.getPageCount() - 1)"
          />
        </nav>
      </div>
    </div>
  </div>
</template>
