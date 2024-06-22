<template>
  <header
    class="bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800"
  >
    <div class="flex justify-between w-full px-4">
      <div class="flex items-center justify-center max-w-full min-w-[6.25rem]">
        <fluent-icon icon="contact-card-group" />
        <h1
          class="m-0 text-xl text-slate-900 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis my-0 mx-2"
        >
          {{ headerTitle }}
        </h1>
        <stage-type-filter @on-stage-type-change="onFilterChange" />
        <div class="multiselect-wrap--small mt-4 pl-4">
          <multiselect
            v-model="selectedAssigneeType"
            track-by="id"
            label="name"
            placeholder="Chọn người phụ trách"
            selected-label="Đang chọn"
            select-label="Chọn"
            deselect-label="Bỏ chọn"
            :options="assigneeTypes"
          />
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
        <div class="flex mt-4">
          <div v-if="customViews.length > 0" class="multiselect-wrap--small">
            <multiselect
              v-model="selectedView"
              track-by="id"
              label="name"
              placeholder="Chọn bộ lọc có sẵn"
              selected-label="Đang chọn"
              select-label="Chọn"
              deselect-label="Bỏ chọn"
              :custom-label="customViewLabel"
              :options="customViews"
            >
              <template slot="option" slot-scope="{ option }">
                <span>{{ option.name }}</span>
              </template>
            </multiselect>
          </div>
          <div v-if="hasActiveSegments">
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
          <div v-if="!hasActiveSegments" class="relative">
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
              {{
                hasAppliedFilters
                  ? $t('CONTACTS_PAGE.FILTER_CONTACTS_EDIT')
                  : $t('PIPELINE_PAGE.FILTER_CONTACTS')
              }}
            </woot-button>
          </div>

          <woot-button
            v-if="hasAppliedFilters && !hasActiveSegments"
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
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import adminMixin from 'dashboard/mixins/isAdmin';
import StageTypeFilter from '../settings/reports/components/Filters/StageType.vue';
import { frontendURL } from '../../../helper/URLHelper';

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
    customViews: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      selectedView: null,
      selectedAssigneeType: null,
    };
  },
  computed: {
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      getAppliedContactFilters: 'contacts/getAppliedContactFilters',
    }),
    hasAppliedFilters() {
      return this.getAppliedContactFilters.length;
    },
    hasActiveSegments() {
      return this.selectedView !== null;
    },
    assigneeTypes() {
      return [
        { id: 'me', name: 'Tôi đang phụ trách' },
        { id: 'unassigned', name: 'Chưa có phụ trách' },
      ];
    },
  },
  watch: {
    selectedView() {
      if (this.selectedView) {
        const route = frontendURL(
          `accounts/${this.accountId}/pipelines/custom_view/${this.selectedView.id}`
        );
        this.$router.push(route);
      } else {
        this.$router.push({ name: 'pipelines_dashboard' });
      }
    },
    selectedAssigneeType() {
      this.$emit('on-assignee-type-change', this.selectedAssigneeType);
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
    customViewLabel(customView) {
      return `Lọc theo: ${customView.name}`;
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
