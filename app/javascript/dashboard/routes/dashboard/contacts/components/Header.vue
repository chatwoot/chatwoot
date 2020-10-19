<template>
  <header class="header">
    <div class="table-actions-wrap">
      <div class="left-aligned-wrap">
        <h1 class="page-title">
          {{ $t('CONTACTS_PAGE.HEADER') }}
        </h1>
      </div>
      <div class="right-aligned-wrap">
        <div class="search-wrap">
          <i class="ion-ios-search-strong search-icon" />
          <input
            type="text"
            :placeholder="$t('CONTACTS_PAGE.SEARCH_INPUT_PLACEHOLDER')"
            class="contact-search"
            :value="searchQuery"
            @input="onInputSearch"
          />
          <woot-submit-button
            :button-text="$t('CONTACTS_PAGE.SEARCH_BUTTON')"
            :loading="false"
            :button-class="searchButtonClass"
            @click="onSearchSubmit"
          />
        </div>
      </div>
    </div>
  </header>
</template>

<script>
export default {
  components: {},
  props: {
    searchQuery: {
      type: String,
      default: '',
    },
    onInputSearch: {
      type: Function,
      default: () => {},
    },
    onSearchSubmit: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
  },
};
</script>

<style lang="scss" scoped>
/* TODO-REM; Change variables sizing to rem after html font size change from 1.0 t0 1.6 */

.header {
  padding: 0 var(--space-medium);
}
.page-title {
  margin: 0;
}
.table-actions-wrap {
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-bottom: var(--space-slab);
}
.search-wrap {
  width: 400px;
  height: 3.6rem;
  display: flex;
  align-items: center;
  position: relative;

  .search-icon {
    position: absolute;
    top: 1px;
    left: var(--space-one);
    height: 3.6rem;
    line-height: 3.6rem;
    font-size: var(--font-size-medium);
    color: var(--b-700);
  }
  .contact-search {
    margin: 0;
    height: 3.6rem;
    width: 100%;
    padding-left: var(--space-large);
    padding-right: 6rem;
  }

  .button {
    margin-left: var(--space-small);
    height: 3.2rem;
    top: var(--space-micro);
    right: var(--space-micro);
    position: absolute;
    padding: 0 var(--space-small);
    transition: transform 100ms linear;
    opacity: 0;
    transform: translateX(-1px);
    visibility: hidden;
  }

  .button.show {
    opacity: 1;
    transform: translateX(0);
    visibility: visible;
  }
}
</style>
