<template>
  <div>
    <search-focus @keyup="focusSearch" />
    <div class="input-container">
      <div class="icon-container">
        <fluent-icon icon="search" class="icon" aria-hidden="true" />
      </div>
      <input
        ref="searchInput"
        type="search"
        placeholder="Search message content, contact name, email or phone or conversations"
        :value="searchQuery"
        @input="debounceSearch"
      />
      <div class="key-binding">
        <span>{{ $t('SEARCH.PLACEHOLDER_KEYBINDING') }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import SearchFocus from './SearchFocus.vue';

export default {
  components: {
    SearchFocus,
  },
  data() {
    return {
      searchQuery: '',
    };
  },
  mounted() {
    this.$refs.searchInput.focus();
  },
  methods: {
    debounceSearch(e) {
      this.searchQuery = e.target.value;
      clearTimeout(this.debounce);
      this.debounce = setTimeout(async () => {
        this.$emit('search', this.searchQuery);
      }, 500);
    },
    focusSearch(e) {
      if (e.key === '/') this.$refs.searchInput.focus();
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
    padding-right: var(--space-mega);

    &:focus {
      .icon {
        color: var(--w-500) !important;
      }
    }
  }
}

.icon-container {
  padding-left: var(--space-slab);
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
    font-size: 1.4rem;
    padding: 0 var(--space-small);
    border: 1px solid var(--s-400);
    border-radius: var(--border-radius-normal);
    display: inline-flex;
    align-items: center;
  }
}
</style>
