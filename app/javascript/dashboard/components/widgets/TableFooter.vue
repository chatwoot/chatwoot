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

const emit = defineEmits(['pageChange']);
const totalPages = computed(() => Math.ceil(props.totalCount / props.pageSize));
const firstIndex = computed(() => props.pageSize * (props.currentPage - 1) + 1);
const lastIndex = computed(() =>
  Math.min(props.totalCount, props.pageSize * props.currentPage)
);
const isFooterVisible = computed(
  () => props.totalCount && !(firstIndex.value > props.totalCount)
);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <footer
    v-if="isFooterVisible"
    class="flex items-center justify-between h-12 px-6"
  >
    <TableFooterResults
      :first-index="firstIndex"
      :last-index="lastIndex"
      :total-count="totalCount"
    />
    <TableFooterPagination
      v-if="totalCount"
      :current-page="currentPage"
      :total-pages="totalPages"
      :total-count="totalCount"
      :page-size="pageSize"
      @page-change="emit('pageChange', $event)"
    />
  </footer>
</template>
