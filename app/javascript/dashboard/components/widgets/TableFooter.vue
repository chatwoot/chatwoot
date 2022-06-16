<template>
  <footer v-if="isFooterVisible" class="footer">
    <div class="left-aligned-wrap">
      <div class="page-meta">
        <strong>{{ firstIndex }}</strong>
        - <strong>{{ lastIndex }}</strong> of
        <strong>{{ totalCount }}</strong> items
      </div>
    </div>
    <div class="right-aligned-wrap">
      <div
        v-if="totalCount"
        class="primary button-group pagination-button-group"
      >
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          class-names="goto-first"
          :is-disabled="hasFirstPage"
          @click="onFirstPage"
        >
          <fluent-icon icon="chevron-left" size="18" />
          <fluent-icon
            icon="chevron-left"
            size="18"
            class="margin-left-minus-slab"
          />
        </woot-button>
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          :is-disabled="hasPrevPage"
          @click="onPrevPage"
        >
          <fluent-icon icon="chevron-left" size="18" />
        </woot-button>
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          @click.prevent
        >
          {{ currentPage }}
        </woot-button>
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          :is-disabled="hasNextPage"
          @click="onNextPage"
        >
          <fluent-icon icon="chevron-right" size="18" />
        </woot-button>
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          class-names="goto-last"
          :is-disabled="hasLastPage"
          @click="onLastPage"
        >
          <fluent-icon icon="chevron-right" size="18" />
          <fluent-icon
            icon="chevron-right"
            size="18"
            class="margin-left-minus-slab"
          />
        </woot-button>
      </div>
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
      default: 15,
    },
    totalCount: {
      type: Number,
      default: 0,
    },
    onPageChange: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    isFooterVisible() {
      return this.totalCount && !(this.firstIndex > this.totalCount);
    },
    firstIndex() {
      const firstIndex = this.pageSize * (this.currentPage - 1) + 1;
      return firstIndex;
    },
    lastIndex() {
      const index = Math.min(this.totalCount, this.pageSize * this.currentPage);
      return index;
    },
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
    hasLastPage() {
      const isDisabled =
        this.currentPage === Math.ceil(this.totalCount / this.pageSize);
      return isDisabled;
    },
    hasFirstPage() {
      const isDisabled = this.currentPage === 1;
      return isDisabled;
    },
    hasNextPage() {
      const isDisabled =
        this.currentPage === Math.ceil(this.totalCount / this.pageSize);
      return isDisabled;
    },
    hasPrevPage() {
      const isDisabled = this.currentPage === 1;
      return isDisabled;
    },
  },
  methods: {
    onNextPage() {
      if (this.hasNextPage) return;
      const newPage = this.currentPage + 1;
      this.onPageChange(newPage);
    },
    onPrevPage() {
      if (this.hasPrevPage) return;

      const newPage = this.currentPage - 1;
      this.onPageChange(newPage);
    },
    onFirstPage() {
      if (this.hasFirstPage) return;

      const newPage = 1;
      this.onPageChange(newPage);
    },
    onLastPage() {
      if (this.hasLastPage) return;

      const newPage = Math.ceil(this.totalCount / this.pageSize);
      this.onPageChange(newPage);
    },
  },
};
</script>

<style lang="scss" scoped>
.footer {
  height: 60px;
  border-top: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--space-normal);
}
.page-meta {
  font-size: var(--font-size-mini);
}

.goto-first,
.goto-last {
  i:last-child {
    margin-left: var(--space-minus-smaller);
  }
}
</style>
