<template>
  <div class="input-container">
    <div class="icon-container">
      <fluent-icon icon="search" class="icon" aria-hidden="true" />
    </div>
    <input
      ref="searchInput"
      type="search"
      :placeholder="$t('SEARCH.INPUT_PLACEHOLDER')"
      :value="searchQuery"
      @input="debounceSearch"
    />
    <div class="key-binding">
      <span>{{ $t('SEARCH.PLACEHOLDER_KEYBINDING') }}</span>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      searchQuery: '',
    };
  },
  mounted() {
    this.$refs.searchInput.focus();
    document.addEventListener('keydown', this.handler);
  },
  beforeDestroy() {
    window.removeEventListener('keydown', this.handler);
  },
  methods: {
    handler(e) {
      if (e.key === '/' && document.activeElement.tagName !== 'INPUT') {
        e.preventDefault();
        this.$refs.searchInput.focus();
      }
    },
    debounceSearch(e) {
      this.searchQuery = e.target.value;
      clearTimeout(this.debounce);
      this.debounce = setTimeout(async () => {
        if (this.searchQuery.length > 2 || this.searchQuery.match(/^[0-9]+$/)) {
          this.$emit('search', this.searchQuery);
        }
      }, 500);
    },
  },
};
</script>

<style lang="scss" scoped>
.input-container {
  position: relative;
  border-radius: var(--border-radius-normal);
  input[type='search'] {
    width: 100%;
    padding-left: calc(var(--space-large) + var(--space-small));
    margin-bottom: 0;
    padding-right: var(--space-mega);
    &:focus {
      .icon {
        color: var(--w-500) !important;
      }
    }
  }
}
.icon-container {
  padding-left: var(--space-small);
  display: flex;
  align-items: center;
  top: 0;
  bottom: 0;
  left: 0;
  position: absolute;
  .icon {
    color: var(--s-400);
  }
}
.key-binding {
  position: absolute;
  top: 0;
  bottom: 0;
  right: 0;
  padding: var(--space-small) var(--space-small) 0 var(--space-small);
  span {
    color: var(--s-400);
    font-weight: var(--font-weight-medium);
    font-size: calc(var(--space-slab) + var(--space-micro));
    padding: 0 var(--space-small);
    border: 1px solid var(--s-100);
    border-radius: var(--border-radius-normal);
    display: inline-flex;
    align-items: center;
  }
}
</style>
