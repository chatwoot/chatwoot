<template>
  <div class="search-input--wrap">
    <div class="search-icon--wrap">
      <fluent-icon icon="search" class="search-icon" />
    </div>
    <input
      v-model="searchValue"
      class="search-input"
      placeholder="Search for articles"
    />
  </div>
</template>

<script>
export default {
  props: {
    searchValue: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss" scoped>
.search-input--wrap {
  display: flex;
  padding: var(--space-small) var(--space-zero);
  width: 100%;
}

.search-input {
  width: 100%;
  height: 3.6rem;
  border-radius: var(--border-radius-normal);
  background: var(--s-50);
  font-size: var(--font-size-small);
  padding: var(--space-small) var(--space-small) var(--space-small)
    var(--space-large);
  border: 1px solid var(--s-100);

  &:focus {
    border-color: var(--w-500);
  }
}

.search-icon--wrap {
  position: relative;
}

.search-icon {
  position: absolute;
  color: var(--s-200);
  top: var(--space-small);
  left: var(--space-small);
}
</style>
