<template>
  <section class="result-section">
    <div v-if="showTitle" class="header">
      <h3 class="text-sm text-slate-800 dark:text-slate-100">{{ title }}</h3>
    </div>
    <woot-loading-state v-if="isFetching" :message="'Searching'" />
    <slot v-else />
    <div v-if="empty && !isFetching" class="empty">
      <fluent-icon icon="info" size="16px" class="icon" />
      <p class="empty-state__text">
        {{ $t('SEARCH.EMPTY_STATE', { item: titleCase, query }) }}
      </p>
    </div>
  </section>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    empty: {
      type: Boolean,
      default: false,
    },
    query: {
      type: String,
      default: '',
    },
    showTitle: {
      type: Boolean,
      default: true,
    },
    isFetching: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    titleCase() {
      return this.title.toLowerCase();
    },
  },
};
</script>

<style scoped lang="scss">
.result-section {
  @apply my-2 mx-0;
}
.search-list {
  @apply m-0 py-4 px-0 list-none;
}
.header {
  @apply sticky top-0 p-2 z-50 bg-white dark:bg-slate-900 mb-0.5;
}

.empty {
  @apply flex items-center justify-center py-6 px-4 m-2 bg-slate-25 dark:bg-slate-800 rounded-md;
  .icon {
    @apply text-slate-500 dark:text-slate-300;
  }
  .empty-state__text {
    @apply text-slate-500 dark:text-slate-300 text-center my-0 mx-2;
  }
}
</style>
