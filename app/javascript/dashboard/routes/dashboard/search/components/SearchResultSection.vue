<template>
  <section>
    <div class="label-container">
      <p>{{ title }}</p>
    </div>
    <slot />
    <div v-if="empty" class="empty">
      <fluent-icon icon="info" size="32px" class="icon" />
      <p class="empty-state__text">
        {{ $t('SEARCH.EMPTY_STATE') }}
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
  padding: var(--space-small);
  background-color: var(--s-25);
  z-index: 50;
  border-bottom-width: 1px;
  border-top-width: 1px;
  border-color: #dbdbdb;
  border-style: solid;
  border-left: 0;
  border-right: 0;
  p {
    font-size: var(--font-size-small);
    color: var(--b-600);
    margin: 0;
  }
}
.empty {
  padding: var(--space-normal);
  .icon {
    font-size: 2rem;
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
