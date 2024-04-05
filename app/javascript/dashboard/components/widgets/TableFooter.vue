<template>
  <footer
    v-if="isFooterVisible"
    class="bg-white dark:bg-slate-900 h-12 flex items-center justify-between px-6"
  >
    <span class="text-sm text-slate-700 dark:text-slate-200 font-medium">
      {{
        $t('GENERAL.SHOWING_RESULTS', {
          currentItemCount: `${firstIndex}-${lastIndex}`,
          totalItems: totalCount,
        })
      }}
    </span>

    <div
      v-if="totalCount"
      class="flex items-center bg-slate-50 dark:bg-slate-800 h-8 rounded-lg"
    >
      <woot-button
        size="small"
        variant="smooth"
        color-scheme="secondary"
        :is-disabled="hasFirstPage"
        class-names="dark:!bg-slate-800 !opacity-100 rounded-l-lg rounded-r-none"
        :class="
          hasFirstPage
            ? 'hover:!bg-slate-50 dark:hover:!bg-slate-800'
            : 'dark:hover:!bg-slate-700/50'
        "
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
        class-names="dark:!bg-slate-800 rounded-r-lg rounded-l-none !opacity-100"
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
  </footer>
</template>

<script>
export default {
  components: {},
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
      return this.currentPage === this.totalPages || this.totalPages === 1;
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
    buttonClass(hasPage) {
      if (hasPage) {
        return 'hover:!bg-slate-50 dark:hover:!bg-slate-800';
      }
      return 'dark:hover:!bg-slate-700/50';
    },
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
