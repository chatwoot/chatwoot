<template>
  <div class="input-container" :class="{ 'is-focused': isInputFocused }">
    <div class="icon-container">
      <fluent-icon icon="search" class="icon" aria-hidden="true" />
    </div>
    <input
      ref="searchInput"
      type="search"
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
@import 'app/javascript/dashboard/assets/scss/_mixins.scss';
.input-container {
  position: relative;
  display: flex;
  align-items: center;
  padding: var(--space-small) var(--space-normal);
  border-bottom: 1px solid var(--s-100);
  transition: border-bottom 0.2s ease-in-out;

  input[type='search'] {
    @include ghost-input;
    width: 100%;
    margin: 0;
  }

  &.is-focused {
    border-bottom: 1px solid var(--w-100);

    .icon {
      color: var(--w-400);
    }
  }
}
.icon-container {
  display: flex;
  align-items: center;
  .icon {
    color: var(--s-400);
  }
}
</style>
