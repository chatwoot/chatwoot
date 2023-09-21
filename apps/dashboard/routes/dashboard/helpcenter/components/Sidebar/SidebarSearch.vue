<template>
  <div class="search-input--wrap">
    <div class="search-icon--wrap">
      <fluent-icon icon="search" size="18" class="search-icon" />
    </div>
    <input
      v-model="searchValue"
      class="search-input"
      :placeholder="$t('HELP_CENTER.SIDEBAR.SEARCH.PLACEHOLDER')"
      @input="onSearch"
    />
  </div>
</template>

<script>
export default {
  data() {
    return {
      searchValue: '',
    };
  },
  methods: {
    onSearch(e) {
      this.$emit('input', e.target.value);
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
  height: var(--space-large);
  border-radius: var(--border-radius-normal);
  background: var(--s-25);
  font-size: var(--font-size-small);
  padding: var(--space-small) var(--space-small) var(--space-small)
    var(--space-large);
  border: 1px solid var(--s-50);

  &:focus {
    border-color: var(--w-500);
  }
}

.search-icon--wrap {
  position: relative;
}

.search-icon {
  position: absolute;
  color: var(--s-500);
  top: var(--space-small);
  left: var(--space-small);
}
</style>
