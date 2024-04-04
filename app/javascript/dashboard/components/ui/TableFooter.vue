<template>
  <footer
    v-if="isFooterVisible"
    class="bg-transparent dark:bg-transparent h-12 flex items-center justify-between px-6"
  >
    <div class="left-aligned-wrap">
      <span class="text-sm text-slate-600 dark:text-slate-200">
        {{ `Showing ${firstIndex}-${lastIndex} of ${totalCount} items` }}
      </span>
    </div>
    <div class="right-aligned-wrap">
      <div
        v-if="totalCount"
        class="primary button-group pagination-button-group"
      >
        <woot-button
          size="small"
          variant="smooth"
          color-scheme="secondary"
          class-names="goto-first"
          :is-disabled="hasFirstPage"
          class="dark:!bg-slate-800"
          @click="onFirstPage"
        >
          <fluent-icon icon="chevrons-left" size="20" icon-lib="lucide" />
        </woot-button>
        <woot-button
          size="small"
          variant="smooth"
          color-scheme="secondary"
          :is-disabled="hasPrevPage"
          class="dark:!bg-slate-800"
          @click="onPrevPage"
        >
          <fluent-icon icon="chevron-left-single" size="20" icon-lib="lucide" />
        </woot-button>

        <div
          class="flex px-3 items-center gap-3 bg-slate-50 dark:bg-slate-800 text-slate-700 dark:text-slate-100"
        >
          <span class="text-sm text-slate-800 dark:text-slate-100">
            {{ currentPage }}
          </span>
          <span>/</span>
          <span class="text-sm text-slate-600 dark:text-slate-200">
            {{ totalPages }}
          </span>
        </div>
        <woot-button
          size="small"
          variant="smooth"
          color-scheme="secondary"
          :is-disabled="hasNextPage"
          class="dark:!bg-slate-800"
          @click="onNextPage"
        >
          <fluent-icon
            icon="chevron-right-single"
            size="20"
            icon-lib="lucide"
          />
        </woot-button>
        <woot-button
          size="small"
          variant="smooth"
          color-scheme="secondary"
          class-names="goto-last"
          class="dark:!bg-slate-800"
          :is-disabled="hasLastPage"
          @click="onLastPage"
        >
          <fluent-icon icon="chevrons-right" size="20" icon-lib="lucide" />
        </woot-button>
      </div>
    </div>
  </footer>
</template>

<script>
import rtlMixin from 'shared/mixins/rtlMixin';

export default {
  components: {},
  mixins: [rtlMixin],
  props: {
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
  },
  computed: {
    totalPages() {
      return Math.ceil(this.totalCount / this.pageSize);
    },
    pageFooterIconClass() {
      return this.isRTLView ? '-mr-3' : '-ml-3';
    },
    isFooterVisible() {
      return this.totalCount && !(this.firstIndex > this.totalCount);
    },
    firstIndex() {
      return this.pageSize * (this.currentPage - 1) + 1;
    },
    lastIndex() {
      return Math.min(this.totalCount, this.pageSize * this.currentPage);
    },
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
    hasLastPage() {
      return !!Math.ceil(this.totalCount / this.pageSize);
    },
    hasFirstPage() {
      return this.currentPage === 1;
    },
    hasNextPage() {
      return this.currentPage === Math.ceil(this.totalCount / this.pageSize);
    },
    hasPrevPage() {
      return this.currentPage === 1;
    },
  },
  methods: {
    onNextPage() {
      if (this.hasNextPage) {
        return;
      }
      const newPage = this.currentPage + 1;
      this.onPageChange(newPage);
    },
    onPrevPage() {
      if (this.hasPrevPage) {
        return;
      }
      const newPage = this.currentPage - 1;
      this.onPageChange(newPage);
    },
    onFirstPage() {
      if (this.hasFirstPage) {
        return;
      }
      const newPage = 1;
      this.onPageChange(newPage);
    },
    onLastPage() {
      if (this.hasLastPage) {
        return;
      }
      const newPage = Math.ceil(this.totalCount / this.pageSize);
      this.onPageChange(newPage);
    },
    onPageChange(page) {
      this.$emit('page-change', page);
    },
  },
};
</script>

<style lang="scss" scoped>
.goto-first,
.goto-last {
  i:last-child {
    @apply -ml-1;
  }
}
</style>
