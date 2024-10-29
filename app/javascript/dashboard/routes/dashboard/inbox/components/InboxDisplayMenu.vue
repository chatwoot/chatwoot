<script>
import wootConstants from 'dashboard/constants/globals';
import { useUISettings } from 'dashboard/composables/useUISettings';

export default {
  emits: ['filter'],

  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
  data() {
    return {
      showSortMenu: false,
      displayOptions: [
        {
          name: this.$t('INBOX.DISPLAY_MENU.DISPLAY_OPTIONS.SNOOZED'),
          key: wootConstants.INBOX_DISPLAY_BY.SNOOZED,
          selected: false,
          type: wootConstants.INBOX_FILTER_TYPE.STATUS,
        },
        {
          name: this.$t('INBOX.DISPLAY_MENU.DISPLAY_OPTIONS.READ'),
          key: wootConstants.INBOX_DISPLAY_BY.READ,
          selected: false,
          type: wootConstants.INBOX_FILTER_TYPE.TYPE,
        },
      ],
      sortOptions: [
        {
          name: this.$t('INBOX.DISPLAY_MENU.SORT_OPTIONS.NEWEST'),
          key: wootConstants.INBOX_SORT_BY.NEWEST,
          type: wootConstants.INBOX_FILTER_TYPE.SORT_ORDER,
        },
        {
          name: this.$t('INBOX.DISPLAY_MENU.SORT_OPTIONS.OLDEST'),
          key: wootConstants.INBOX_SORT_BY.OLDEST,
          type: wootConstants.INBOX_FILTER_TYPE.SORT_ORDER,
        },
      ],
      activeSort: wootConstants.INBOX_SORT_BY.NEWEST,
      activeDisplayFilter: {
        status: '',
        type: '',
      },
    };
  },
  computed: {
    activeSortOption() {
      return (
        this.sortOptions.find(option => option.key === this.activeSort)?.name ||
        ''
      );
    },
  },
  mounted() {
    this.setSavedFilter();
  },
  methods: {
    updateDisplayOption(option) {
      this.displayOptions.forEach(displayOption => {
        if (displayOption.key === option.key) {
          displayOption.selected = !option.selected;
          this.activeDisplayFilter[displayOption.type] = displayOption.selected
            ? displayOption.key
            : '';
          this.saveSelectedDisplayFilter();
          this.$emit('filter', option);
        }
      });
    },
    openSortMenu() {
      this.showSortMenu = !this.showSortMenu;
    },
    onSortOptionClick(option) {
      this.activeSort = option.key;
      this.showSortMenu = false;
      this.saveSelectedDisplayFilter();
      this.$emit('filter', option);
    },
    saveSelectedDisplayFilter() {
      this.updateUISettings({
        inbox_filter_by: {
          ...this.activeDisplayFilter,
          sort_by: this.activeSort || wootConstants.INBOX_SORT_BY.NEWEST,
        },
      });
    },
    setSavedFilter() {
      const { inbox_filter_by: filterBy = {} } = this.uiSettings;
      const { status, type, sort_by: sortBy } = filterBy;
      this.activeSort = sortBy || wootConstants.INBOX_SORT_BY.NEWEST;
      this.displayOptions.forEach(option => {
        option.selected =
          option.type === wootConstants.INBOX_FILTER_TYPE.STATUS
            ? option.key === status
            : option.key === type;
        this.activeDisplayFilter[option.type] = option.selected
          ? option.key
          : '';
      });
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col bg-white z-50 dark:bg-slate-900 w-[170px] border shadow-md border-slate-100 dark:border-slate-700/50 rounded-xl divide-y divide-slate-100 dark:divide-slate-700/50"
  >
    <div class="flex items-center justify-between p-3 rounded-t-lg h-11">
      <div class="flex gap-1.5">
        <fluent-icon
          icon="arrow-sort"
          type="outline"
          size="16"
          class="text-slate-700 dark:text-slate-100"
        />
        <span class="text-xs font-medium text-slate-800 dark:text-slate-100">
          {{ $t('INBOX.DISPLAY_MENU.SORT') }}
        </span>
      </div>
      <div class="relative">
        <div
          role="button"
          class="border h-5 flex gap-1 rounded-md items-center pr-1.5 pl-1 py-0.5 w-[70px] justify-between border-slate-100 dark:border-slate-700/50"
          @click="openSortMenu"
        >
          <span class="text-xs font-medium text-slate-600 dark:text-slate-300">
            {{ activeSortOption }}
          </span>
          <fluent-icon
            icon="chevron-down"
            size="12"
            class="text-slate-600 dark:text-slate-200"
          />
        </div>
        <div
          v-if="showSortMenu"
          class="absolute flex flex-col gap-0.5 bg-white z-60 dark:bg-slate-800 rounded-md p-0.5 top-0 w-[70px] border border-slate-100 dark:border-slate-700/50"
        >
          <div
            v-for="option in sortOptions"
            :key="option.key"
            role="button"
            class="flex rounded-[4px] h-5 w-full items-center justify-between p-0.5 gap-1"
            :class="{
              'bg-woot-50 dark:bg-woot-700/50': activeSort === option.key,
            }"
            @click.stop="onSortOptionClick(option)"
          >
            <span
              class="text-xs font-medium hover:text-woot-600 dark:hover:text-woot-600"
              :class="{
                'text-woot-600 dark:text-woot-600': activeSort === option.key,
                'text-slate-600 dark:text-slate-300': activeSort !== option.key,
              }"
            >
              {{ option.name }}
            </span>
            <fluent-icon
              v-if="activeSort === option.key"
              icon="checkmark"
              size="14"
              class="text-woot-600 dark:text-woot-600"
            />
          </div>
        </div>
      </div>
    </div>
    <div>
      <span
        class="px-3 py-4 text-xs font-medium text-slate-400 dark:text-slate-400"
      >
        {{ $t('INBOX.DISPLAY_MENU.DISPLAY') }}
      </span>
      <div
        class="flex flex-col divide-y divide-slate-100 dark:divide-slate-700/50"
      >
        <div
          v-for="option in displayOptions"
          :key="option.key"
          class="flex items-center px-3 py-2 gap-1.5 h-9"
        >
          <input
            :id="option.key"
            type="checkbox"
            :name="option.key"
            :checked="option.selected"
            class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
            @change="updateDisplayOption(option)"
          />
          <label
            :for="option.key"
            class="text-xs font-medium text-slate-800 !ml-0 !mr-0 dark:text-slate-100"
          >
            {{ option.name }}
          </label>
        </div>
      </div>
    </div>
  </div>
</template>
