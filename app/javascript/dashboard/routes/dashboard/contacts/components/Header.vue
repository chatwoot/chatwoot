<template>
  <header class="header">
    <div class="table-actions-wrap">
      <div class="left-aligned-wrap">
        <h1 class="page-title">
          {{ headerTitle ? `#${headerTitle}` : $t('CONTACTS_PAGE.HEADER') }}
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
            @keyup.enter="onSearchSubmit"
            @input="onInputSearch"
          />
          <woot-button
            :is-loading="false"
            :class-names="searchButtonClass"
            @click="onSearchSubmit"
          >
            {{ $t('CONTACTS_PAGE.SEARCH_BUTTON') }}
          </woot-button>
        </div>

        <woot-button
          color-scheme="success"
          icon="ion-android-add-circle"
          @click="onToggleCreate"
          data-testid="create-new-contact"
        >
          {{ $t('CREATE_CONTACT.BUTTON_LABEL') }}
        </woot-button>
      </div>
    </div>
  </header>
</template>

<script>
export default {
  components: {},
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
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
    onToggleCreate: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      showCreateModal: false,
    };
  },
  computed: {
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
  },
};
</script>

<style lang="scss" scoped>
.page-title {
  margin: 0;
}
.table-actions-wrap {
  display: flex;
  justify-content: space-between;
  width: 100%;
  padding: var(--space-small) var(--space-normal) var(--space-small)
    var(--space-normal);
}

.left-aligned-wrap {
  display: flex;
  align-items: center;
  justify-content: center;
}

.right-aligned-wrap {
  display: flex;
}

.search-wrap {
  width: 400px;
  display: flex;
  align-items: center;
  position: relative;
  margin-right: var(--space-small);

  .search-icon {
    position: absolute;
    top: 1px;
    left: var(--space-one);
    height: 3.8rem;
    line-height: 3.6rem;
    font-size: var(--font-size-medium);
    color: var(--b-700);
  }
  .contact-search {
    margin: 0;
    height: 3.8rem;
    width: 100%;
    padding-left: var(--space-large);
    padding-right: 6rem;
    border-color: var(--s-100);
  }

  .button {
    margin-left: var(--space-small);
    height: 3.2rem;
    right: var(--space-smaller);
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
