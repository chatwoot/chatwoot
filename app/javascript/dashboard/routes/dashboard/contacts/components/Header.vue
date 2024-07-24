<template>
  <header
    class="bg-white border-b dark:bg-slate-900 border-slate-50 dark:border-slate-800"
  >
    <div class="flex justify-between w-full px-4 py-2">
      <div class="flex flex-col items-center w-full gap-2 md:flex-row">
        <div class="flex justify-between w-full gap-2">
          <div
            class="flex items-center justify-center max-w-full min-w-[6.25rem]"
          >
            <woot-sidemenu-icon />
            <h1
              class="m-0 mx-2 my-0 overflow-hidden text-xl text-slate-900 dark:text-slate-100 whitespace-nowrap text-ellipsis"
            >
              {{ headerTitle }}
            </h1>
          </div>
          <div
            class="max-w-[400px] min-w-[100px] flex items-center relative mx-2"
          >
            <div class="flex items-center absolute h-full left-2.5">
              <fluent-icon
                icon="search"
                class="h-5 text-sm leading-9 text-slate-700 dark:text-slate-200"
              />
            </div>
            <input
              type="text"
              :placeholder="$t('CONTACTS_PAGE.SEARCH_INPUT_PLACEHOLDER')"
              class="!pl-9 !pr-[3.75rem] !text-sm !w-full !h-[2.375rem] !m-0 border-slate-100 dark:border-slate-600"
              :value="searchQuery"
              @keyup.enter="submitSearch"
              @input="inputSearch"
            />
            <woot-button
              :is-loading="false"
              class="absolute h-8 px-2 py-0 ml-2 transition-transform duration-100 ease-linear clear right-1"
              :class-names="searchButtonClass"
              @click="submitSearch"
            >
              {{ $t('CONTACTS_PAGE.SEARCH_BUTTON') }}
            </woot-button>
          </div>
        </div>
        <div class="flex gap-1">
          <div v-if="hasActiveSegments" class="flex gap-2">
            <woot-button
              class="clear [&>span]:hidden xs:[&>span]:block"
              color-scheme="secondary"
              icon="edit"
              @click="onToggleEditSegmentsModal"
            >
              {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_EDIT') }}
            </woot-button>
            <woot-button
              class="clear [&>span]:hidden xs:[&>span]:block"
              color-scheme="alert"
              icon="delete"
              @click="onToggleDeleteSegmentsModal"
            >
              {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_DELETE') }}
            </woot-button>
          </div>
          <div v-if="!hasActiveSegments" class="relative">
            <div
              v-if="hasAppliedFilters"
              class="absolute w-2 h-2 rounded-full top-1 right-3 bg-slate-500 dark:bg-slate-500"
            />
            <woot-button
              class="clear [&>span]:hidden xs:[&>span]:block"
              color-scheme="secondary"
              data-testid="create-new-contact"
              icon="filter"
              @click="toggleFilter"
            >
              {{ $t('CONTACTS_PAGE.FILTER_CONTACTS') }}
            </woot-button>
          </div>

          <woot-button
            v-if="hasAppliedFilters && !hasActiveSegments"
            class="clear [&>span]:hidden xs:[&>span]:block"
            color-scheme="alert"
            variant="clear"
            icon="save"
            @click="onToggleSegmentsModal"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_SAVE') }}
          </woot-button>
          <woot-button
            class="clear [&>span]:hidden xs:[&>span]:block"
            color-scheme="success"
            icon="person-add"
            data-testid="create-new-contact"
            @click="toggleCreate"
          >
            {{ $t('CREATE_CONTACT.BUTTON_LABEL') }}
          </woot-button>

          <woot-button
            v-if="isAdmin"
            color-scheme="info"
            icon="upload"
            class="clear [&>span]:hidden xs:[&>span]:block"
            @click="toggleImport"
          >
            {{ $t('IMPORT_CONTACTS.BUTTON_LABEL') }}
          </woot-button>

          <woot-button
            v-if="isAdmin"
            color-scheme="info"
            icon="download"
            class="clear [&>span]:hidden xs:[&>span]:block"
            @click="submitExport"
          >
            {{ $t('EXPORT_CONTACTS.BUTTON_LABEL') }}
          </woot-button>
        </div>
      </div>
    </div>
    <woot-confirm-modal
      ref="confirmExportContactsDialog"
      :title="$t('EXPORT_CONTACTS.CONFIRM.TITLE')"
      :description="exportDescription"
      :confirm-label="$t('EXPORT_CONTACTS.CONFIRM.YES')"
      :cancel-label="$t('EXPORT_CONTACTS.CONFIRM.NO')"
    />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';

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
  },
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      showCreateModal: false,
      showImportModal: false,
    };
  },
  computed: {
    searchButtonClass() {
      return this.searchQuery !== ''
        ? 'opacity-100 translate-x-0 visible'
        : '-translate-x-px opacity-0 invisible';
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
    exportDescription() {
      return this.hasAppliedFilters
        ? this.$t('EXPORT_CONTACTS.CONFIRM.FILTERED_MESSAGE')
        : this.$t('EXPORT_CONTACTS.CONFIRM.MESSAGE');
    },
  },
  methods: {
    onToggleSegmentsModal() {
      this.$emit('on-toggle-save-filter');
    },
    onToggleEditSegmentsModal() {
      this.$emit('on-toggle-edit-filter');
    },
    onToggleDeleteSegmentsModal() {
      this.$emit('on-toggle-delete-filter');
    },
    toggleCreate() {
      this.$emit('on-toggle-create');
    },
    toggleFilter() {
      this.$emit('on-toggle-filter');
    },
    toggleImport() {
      this.$emit('on-toggle-import');
    },
    async submitExport() {
      const ok =
        await this.$refs.confirmExportContactsDialog.showConfirmation();

      if (ok) {
        this.$emit('on-export-submit');
      }
    },
    submitSearch() {
      this.$emit('on-search-submit');
    },
    inputSearch(event) {
      this.$emit('on-input-search', event);
    },
  },
};
</script>
