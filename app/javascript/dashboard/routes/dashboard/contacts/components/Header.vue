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
          <fluent-icon icon="search" class="search-icon" />
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
        <div class="filters__button-wrap">
          <div
            v-if="hasAppliedFilters"
            class="filters__applied-indicator"
          ></div>
          <woot-button
            color-scheme="secondary"
            icon="ion-ios-settings-strong"
            class="margin-right-small"
            data-testid="create-new-contact"
            @click="onToggleFilter"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS') }}
          </woot-button>
        </div>
        <woot-button
          color-scheme="success"
          icon="add-circle"
          class="margin-right-small"
          data-testid="create-new-contact"
          @click="onToggleCreate"
        >
          {{ $t('CREATE_CONTACT.BUTTON_LABEL') }}
        </woot-button>

        <woot-button
          color-scheme="info"
          icon="cloud-backup"
          @click="onToggleImport"
        >
          {{ $t('IMPORT_CONTACTS.BUTTON_LABEL') }}
        </woot-button>
      </div>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
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
    onToggleImport: {
      type: Function,
      default: () => {},
    },
    onToggleFilter: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      showCreateModal: false,
      showImportModal: false,
    };
  },
  computed: {
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
    ...mapGetters({
      getAppliedContactFilters: 'contacts/getAppliedContactFilters',
    }),
    hasAppliedFilters() {
      return this.getAppliedContactFilters.length;
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
.filters__button-wrap {
  position: relative;

  .filters__applied-indicator {
    position: absolute;
    height: var(--space-small);
    width: var(--space-small);
    top: var(--space-smaller);
    right: var(--space-slab);
    background-color: var(--white);
    border-radius: var(--border-radius-rounded);
  }
}
</style>
