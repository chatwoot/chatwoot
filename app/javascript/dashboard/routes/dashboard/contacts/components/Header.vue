<template>
  <header class="header">
    <div class="table-actions-wrap">
      <div class="left-aligned-wrap">
        <woot-sidemenu-icon />
        <h1 class="page-title">
          {{ headerTitle }}
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
            class="clear"
            :class-names="searchButtonClass"
            @click="onSearchSubmit"
          >
            {{ $t('CONTACTS_PAGE.SEARCH_BUTTON') }}
          </woot-button>
        </div>
        <woot-button
          v-if="hasActiveSegments"
          class="margin-right-small clear"
          color-scheme="alert"
          icon="delete"
          @click="onToggleDeleteSegmentsModal"
        >
          {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_DELETE') }}
        </woot-button>
        <div v-if="!hasActiveSegments" class="filters__button-wrap">
          <div v-if="hasAppliedFilters" class="filters__applied-indicator" />
          <woot-button
            class="margin-right-small clear"
            color-scheme="secondary"
            data-testid="create-new-contact"
            icon="filter"
            @click="onToggleFilter"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS') }}
          </woot-button>
        </div>

        <woot-button
          v-if="hasAppliedFilters && !hasActiveSegments"
          class="margin-right-small clear"
          color-scheme="alert"
          variant="clear"
          icon="save"
          @click="onToggleSegmentsModal"
        >
          {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_SAVE') }}
        </woot-button>
        <woot-button
          class="margin-right-small clear"
          color-scheme="success"
          icon="person-add"
          data-testid="create-new-contact"
          @click="onToggleCreate"
        >
          {{ $t('CREATE_CONTACT.BUTTON_LABEL') }}
        </woot-button>

        <woot-button
          color-scheme="info"
          icon="upload"
          class="clear"
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
    segmentsId: {
      type: [String, Number],
      default: 0,
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
    hasActiveSegments() {
      return this.segmentsId !== 0;
    },
  },
  methods: {
    onToggleSegmentsModal() {
      this.$emit('on-toggle-save-filter');
    },
    onToggleDeleteSegmentsModal() {
      this.$emit('on-toggle-delete-filter');
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
  max-width: 400px;
  min-width: 150px;
  display: flex;
  align-items: center;
  position: relative;
  margin-right: var(--space-small);
  margin-left: var(--space-small);

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
    background-color: var(--s-500);
    border-radius: var(--border-radius-rounded);
  }
}
</style>
