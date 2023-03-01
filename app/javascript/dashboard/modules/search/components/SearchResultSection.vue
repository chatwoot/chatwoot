<template>
  <section>
    <div class="label-container">
      <h3 class="text-block-title">{{ title }}</h3>
    </div>
    <slot />
    <div v-if="empty" class="empty">
      <fluent-icon icon="info" size="24px" class="icon" />
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
  },
  computed: {
    titleCase() {
      return this.title.toLowerCase();
    },
  },
};
</script>

<style scoped lang="scss">
.search-list {
  list-style: none;
  margin: 0;
  padding: var(--spacing-normal) 0;
}
.label-container {
  position: sticky;
  top: 0;
  padding: var(--space-small) 0;
  z-index: 50;
  background: var(--white);
}

.text-block-title {
  color: var(--s-600);
}
.empty {
  padding: var(--space-normal);
  background: var(--s-25);
  border-radius: var(--border-radius-medium);
  .icon {
    font-size: var(--space-two);
    color: var(--s-500);
    margin: 0 auto;
    display: block;
  }
  .empty-state__text {
    text-align: center;
    margin-top: var(--space-small);
    color: var(--s-500);
  }
}
</style>
