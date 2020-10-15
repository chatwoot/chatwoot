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
      <div class="primary button-group pagination-button-group">
        <button class="button small goto-first">
          <i class="ion-chevron-left" />
          <i class="ion-chevron-left" />
        </button>
        <button class="button small">
          <i class="ion-chevron-left" />
        </button>
        <button class="button">
          {{ currentPage }}
        </button>
        <button class="button small">
          <i class="ion-chevron-right" />
        </button>
        <button class="button small goto-last">
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
    firstIndex: {
      type: Number,
      default: 1,
    },
    lastIndex: {
      type: Number,
      default: 20,
    },
    currentPage: {
      type: Number,
      default: 1,
    },
    pageSize: {
      type: Number,
      default: 20,
    },
    totalCount: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
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

    &:hover {
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

    &.goto-first,
    &.goto-last {
      i:last-child {
        margin-left: var(--space-minus-smaller);
      }
    }
  }
}
</style>
