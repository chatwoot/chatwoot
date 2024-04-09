<template>
  <footer
    v-if="isFooterVisible"
    class="h-12 flex items-center justify-between px-6"
  >
    <table-footer-results
      :first-index="firstIndex"
      :last-index="lastIndex"
      :total-count="totalCount"
    />
    <table-footer-pagination
      v-if="totalCount"
      :current-page="currentPage"
      :total-pages="totalPages"
      :total-count="totalCount"
      :page-size="pageSize"
      @page-change="$emit('page-change', $event)"
    />
  </footer>
</template>

<script setup>
import { computed } from 'vue';
import TableFooterResults from './TableFooterResults.vue';
import TableFooterPagination from './TableFooterPagination.vue';
const props = defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  pageSize: {
    type: Number,
    default: 25,
  },
  totalCount: {
    type: Number,
    default: 0,
  },
});
const totalPages = computed(() => Math.ceil(props.totalCount / props.pageSize));
const firstIndex = computed(() => props.pageSize * (props.currentPage - 1) + 1);
const lastIndex = computed(() =>
  Math.min(props.totalCount, props.pageSize * props.currentPage)
);
const isFooterVisible = computed(
  () => props.totalCount && !(firstIndex.value > props.totalCount)
);
</script>
