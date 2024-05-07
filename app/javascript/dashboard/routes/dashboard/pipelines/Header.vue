<template>
  <header
    class="bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800"
  >
    <div class="flex justify-between w-full py-2 px-4">
      <div class="flex items-center justify-center max-w-full min-w-[6.25rem]">
        <woot-sidemenu-icon />
        <h1
          class="m-0 text-xl text-slate-900 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis my-0 mx-2"
        >
          {{ headerTitle }}
        </h1>
      </div>
      <stage-type-filter @on-stage-type-change="onFilterChange" />
      <div class="flex gap-2">
        <div
          class="max-w-[400px] min-w-[150px] flex items-center relative mx-2 search-wrap"
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
        <div class="relative">
          <div
            v-if="hasAppliedFilters"
            class="absolute h-2 w-2 top-1 right-3 bg-slate-500 dark:bg-slate-500 rounded-full"
          />
          <woot-button
            class="clear"
            color-scheme="secondary"
            icon="filter"
            @click="toggleFilter"
          >
            {{ $t('CONTACTS_PAGE.FILTER_CONTACTS') }}
          </woot-button>
        </div>
      </div>
    </div>
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import adminMixin from 'dashboard/mixins/isAdmin';
import StageTypeFilter from '../settings/reports/components/Filters/StageType.vue';

export default {
  components: {
    StageTypeFilter,
  },
  mixins: [adminMixin],
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    searchQuery: {
      type: String,
      default: '',
    },
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
  methods: {
    submitSearch() {
      this.$emit('on-search-submit');
    },
    inputSearch(event) {
      this.$emit('on-input-search', event);
    },
    onFilterChange(selectedStageType) {
      this.$emit('on-filter-change', selectedStageType);
    },
    toggleFilter() {
      this.$emit('on-toggle-filter');
    },
  },
};
</script>

<style lang="scss" scoped>
.search-wrap {
  .contact-search {
    @apply pl-9 pr-[3.75rem] text-sm w-full h-[2.375rem] m-0;
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
