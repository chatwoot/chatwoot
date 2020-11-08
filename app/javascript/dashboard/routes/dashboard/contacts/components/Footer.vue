<template>
  <footer class="footer">
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
        <button
          class="button small goto-first"
          :class="firstPageButtonClass"
          @click="onFirstPage"
        >
          <i class="ion-chevron-left" />
          <i class="ion-chevron-left" />
        </button>
        <button
          class="button small"
          :class="prevPageButtonClass"
          @click="onPrevPage"
        >
          <i class="ion-chevron-left" />
        </button>
        <button class="button" @click.prevent>
          {{ currentPage }}
        </button>
        <button
          class="button small"
          :class="nextPageButtonClass"
          @click="onNextPage"
        >
          <i class="ion-chevron-right" />
        </button>
        <button
          class="button small goto-last"
          :class="lastPageButtonClass"
          @click="onLastPage"
        >
          <i class="ion-chevron-right" />
          <i class="ion-chevron-right" />
        </button>
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
      default: 25,
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
    lastPageButtonClass() {
      const className = this.hasLastPage ? 'disabled' : '';
      return className;
    },
    hasFirstPage() {
      const isDisabled = this.currentPage === 1;
      return isDisabled;
    },
    firstPageButtonClass() {
      const className = this.hasFirstPage ? 'disabled' : '';
      return className;
    },
    hasNextPage() {
      const isDisabled =
        this.currentPage === Math.ceil(this.totalCount / this.pageSize);
      return isDisabled;
    },
    nextPageButtonClass() {
      const className = this.hasNextPage ? 'disabled' : '';
      return className;
    },
    hasPrevPage() {
      const isDisabled = this.currentPage === 1;
      return isDisabled;
    },
    prevPageButtonClass() {
      const className = this.hasPrevPage ? 'disabled' : '';
      return className;
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
.pagination-button-group {
  margin: 0;

  .button {
    background: transparent;
    border-color: var(--b-400);
    color: var(--color-body);
    margin-bottom: 0;
    margin-left: -2px;
    font-size: var(--font-size-small);
    padding: var(--space-small) var(--space-normal);

    &:hover,
    &:focus,
    &:active {
      background: var(--b-400);
      color: white;
    }

    &:first-child {
      border-top-left-radius: 3px;
      border-bottom-left-radius: 3px;
    }
    &:last-child {
      border-top-right-radius: 3px;
      border-bottom-right-radius: 3px;
    }
    &.small {
      font-size: var(--font-size-micro);
    }
    &.disabled {
      background: var(--b-300);
      color: var(--b-900);
    }

    &.goto-first,
    &.goto-last {
      i:last-child {
        margin-left: var(--space-minus-smaller);
      }
    }
  }
}
</style>
