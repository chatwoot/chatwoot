<template>
  <div class="input-container" :class="{ 'is-focused': isInputFocused }">
    <div class="icon-container">
      <fluent-icon icon="search" class="icon" aria-hidden="true" />
    </div>
    <input
      ref="searchInput"
      type="search"
      class="dark:bg-slate-900"
      :placeholder="$t('SEARCH.INPUT_PLACEHOLDER')"
      :value="searchQuery"
      @focus="onFocus"
      @blur="onBlur"
      @input="debounceSearch"
    />
    <woot-label
      :title="$t('SEARCH.PLACEHOLDER_KEYBINDING')"
      :show-close="false"
      small
      class="helper-label"
    />
  </div>
</template>

<script>
export default {
  data() {
    return {
      searchQuery: '',
      isInputFocused: false,
    };
  },
  mounted() {
    this.$refs.searchInput.focus();
    document.addEventListener('keydown', this.handler);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handler);
  },
  methods: {
    handler(e) {
      if (e.key === '/' && document.activeElement.tagName !== 'INPUT') {
        e.preventDefault();
        this.$refs.searchInput.focus();
      } else if (
        e.key === 'Escape' &&
        document.activeElement.tagName === 'INPUT'
      ) {
        e.preventDefault();
        this.$refs.searchInput.blur();
      }
    },
    debounceSearch(e) {
      this.searchQuery = e.target.value;
      clearTimeout(this.debounce);
      this.debounce = setTimeout(async () => {
        if (this.searchQuery.length > 2 || this.searchQuery.match(/^[0-9]+$/)) {
          this.$emit('search', this.searchQuery);
        } else {
          this.$emit('search', '');
        }
      }, 500);
    },
    onFocus() {
      this.isInputFocused = true;
    },
    onBlur() {
      this.isInputFocused = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.input-container {
  transition: border-bottom 0.2s ease-in-out;
  @apply relative flex items-center py-2 px-4 h-14 gap-2 rounded-sm border border-solid border-slate-100 dark:border-slate-800;

  input[type='search'] {
    @apply w-full m-0 shadow-none border-transparent active:border-transparent active:shadow-none hover:border-transparent hover:shadow-none focus:border-transparent focus:shadow-none;
  }

  &.is-focused {
    @apply border-woot-100 dark:border-woot-600;

    .icon {
      color: var(--w-400);
      @apply text-woot-400 dark:text-woot-500;
    }
  }
}
.icon-container {
  @apply flex items-center;
  .icon {
    @apply text-slate-400;
  }
}

.helper-label {
  @apply m-0 whitespace-nowrap;
}
</style>
