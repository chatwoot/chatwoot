<template>
  <header
    class="flex justify-between w-full px-4 bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800"
  >
    <div
      class="flex items-center justify-center max-w-full min-w-[6.25rem] gap-4 mt-2 mb-2"
    >
      <fluent-icon icon="contact-card-group" />
      <h1
        class="text-xl text-slate-900 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis"
      >
        {{ headerTitle }}
      </h1>
      <stage-type-filter
        :stage-type-value="stageTypeValue"
        @on-stage-type-change="onStageFilterChange"
      />
      <div class="relative">
        <div
          role="button"
          class="flex h-10 gap-1 items-center py-1 px-2 border border-slate-100 dark:border-slate-500 rounded-md"
          @click="openDisplayOptionMenu"
        >
          <span class="text-center text-sm">
            {{ $t('INBOX.LIST.DISPLAY_DROPDOWN') }}
          </span>
          <fluent-icon
            icon="chevron-down"
            size="12"
            class="text-slate-600 dark:text-slate-200"
          />
        </div>
        <display-option-menu
          v-if="showDisplayOptionMenu"
          v-on-clickaway="openDisplayOptionMenu"
          :display-options="displayOptions"
          class="absolute top-9 ltr:left-0 rtl:right-0"
          @option-changed="onOptionChanged"
        />
      </div>
      <div class="flex">
        <quick-filter
          :applied-filters-prop="quickFilters"
          :segments-query="segmentsQuery"
          @filter-change="onFilterChange"
        />
        <div v-if="hasActiveSegments && canEditView">
          <woot-button
            class="clear"
            color-scheme="secondary"
            icon="edit"
            @click="onToggleEditSegmentsModal"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_EDIT') }}
          </woot-button>
          <woot-button
            class="clear"
            color-scheme="alert"
            icon="delete"
            @click="onToggleDeleteSegmentsModal"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_DELETE') }}
          </woot-button>
        </div>
        <div v-if="hasAppliedFilters && !hasActiveSegments" class="relative">
          <woot-button
            class="clear"
            color-scheme="secondary"
            icon="filter"
            @click="toggleFilter"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_EDIT') }}
          </woot-button>
          <woot-button
            class="clear"
            color-scheme="alert"
            variant="clear"
            icon="save"
            @click="onToggleSegmentsModal"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS_SAVE') }}
          </woot-button>
        </div>
      </div>
    </div>

    <div class="flex gap-2">
      <div
        class="max-w-[300px] min-w-[150px] flex items-center relative mx-2 search-wrap"
      >
        <div class="flex items-center absolute h-full left-2.5">
          <fluent-icon
            icon="search"
            class="h-5 leading-9 text-sm text-slate-700 dark:text-slate-200"
          />
        </div>
        <input
          type="text"
          :placeholder="$t('CONTACTS_PAGE.SEARCH_INPUT_PLACEHOLDER')"
          class="contact-search border-slate-100 dark:border-slate-600"
          :value="searchQuery"
          @keyup.enter="submitSearch"
          @input="inputSearch"
        />
        <woot-button
          :is-loading="false"
          class="clear"
          :class-names="searchButtonClass"
          @click="submitSearch"
        >
          {{ $t('CONTACTS_PAGE.SEARCH_BUTTON') }}
        </woot-button>
      </div>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import adminMixin from 'dashboard/mixins/isAdmin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import StageTypeFilter from '../settings/reports/components/Filters/StageType.vue';
import DisplayOptionMenu from './DisplayOptionMenu.vue';
import QuickFilter from './QuickFilter.vue';

export default {
  components: {
    StageTypeFilter,
    QuickFilter,
    DisplayOptionMenu,
  },
  mixins: [adminMixin, uiSettingsMixin],
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    searchQuery: {
      type: String,
      default: '',
    },
    segmentsQuery: {
      type: Object,
      default: () => {},
    },
    displayOptions: {
      type: Object,
      default: null,
    },
    stageTypeValue: {
      type: String,
      default: 'both',
    },
    customViews: {
      type: Array,
      default: () => [],
    },
    customViewValue: {
      type: Number,
      default: null,
    },
    quickFilters: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      showDisplayOptionMenu: false,
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
      return this.customViewValue !== null;
    },
    selectedView: {
      get() {
        return this.customViews.find(item => item.id === this.customViewValue);
      },
      set(selectedView) {
        this.$emit('on-custom-view-change', selectedView);
      },
    },
    canEditView() {
      return this.isAdmin || !this.selectedView.account_scoped;
    },
  },
  watch: {
    stageTypeValue() {
      this.saveSelectedValues();
    },
    displayOptions: {
      handler() {
        this.saveSelectedValues();
      },
      deep: true,
    },
    quickFilters: {
      handler() {
        this.saveSelectedValues();
      },
      deep: true,
    },
  },
  methods: {
    onFilterChange(appliedFilters) {
      this.$emit('on-quick-filters-change', appliedFilters);
    },
    removeAssigneeType() {
      this.$emit('on-assignee-type-change', null);
    },
    removeCustomView() {
      this.$emit('on-custom-view-change', null);
    },
    saveSelectedValues() {
      this.updateUISettings({
        pipeline_view: {
          stage_type: this.stageTypeValue,
          display_options: this.displayOptions,
          quick_filters: this.quickFilters,
        },
      });
    },
    onOptionChanged(option) {
      this.$emit('display-option-changed', option);
    },
    openDisplayOptionMenu() {
      this.showDisplayOptionMenu = !this.showDisplayOptionMenu;
    },
    onToggleSegmentsModal() {
      this.$emit('on-toggle-save-filter');
    },
    onToggleEditSegmentsModal() {
      this.$emit('on-toggle-edit-filter');
    },
    onToggleDeleteSegmentsModal() {
      this.$emit('on-toggle-delete-filter');
    },
    submitSearch() {
      this.$emit('on-search-submit');
    },
    inputSearch(event) {
      this.$emit('on-input-search', event);
    },
    onStageFilterChange(selectedStageType) {
      this.$emit('on-filter-change', selectedStageType);
    },
    toggleFilter() {
      this.$emit('on-toggle-filter');
    },
    customViewLabel(customView) {
      return `${this.$t('PIPELINE_PAGE.CUSTOM_VIEWS.CUSTOM_LABEL')} ${
        customView.name
      }`;
    },
  },
};
</script>

<style lang="scss" scoped>
.search-wrap {
  .contact-search {
    @apply pl-9 pr-[3.75rem] text-sm w-full m-0;
  }

  .button {
    transition: transform 100ms linear;
    @apply ml-2 h-8 right-1 absolute py-0 px-2 opacity-0 -translate-x-px invisible;
  }

  .button.show {
    @apply opacity-100 translate-x-0 visible;
  }
}
</style>
