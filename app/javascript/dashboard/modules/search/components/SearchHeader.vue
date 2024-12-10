<script>
export default {
  emits: ['search'],

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
  unmounted() {
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

<template>
  <div
    class="input-container transition-[border-bottom] duration-[0.2s] ease-[ease-in-out] relative flex items-center py-2 px-4 h-14 gap-2 rounded-sm border border-solid"
    :class="{
      'border-n-brand dark:border-n-brand': isInputFocused,
      'border-n-weak dark:border-n-strong': !isInputFocused,
    }"
  >
    <div class="flex items-center">
      <fluent-icon
        icon="search"
        class="icon"
        aria-hidden="true"
        :class="{
          'text-n-blue-text': isInputFocused,
          'text-n-slate-10': !isInputFocused,
        }"
      />
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
      class="!m-0 whitespace-nowrap !bg-n-slate-3 dark:!bg-n-solid-3 !border-n-weak dark:!border-n-strong"
    />
  </div>
</template>

<style lang="scss" scoped>
.input-container {
  input[type='search'] {
    @apply w-full m-0 shadow-none border-transparent active:border-transparent active:shadow-none hover:border-transparent hover:shadow-none focus:border-transparent focus:shadow-none;
  }
}
</style>
