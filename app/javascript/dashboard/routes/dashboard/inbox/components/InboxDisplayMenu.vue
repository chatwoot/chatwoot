<script>
import wootConstants from 'dashboard/constants/globals';
import { useUISettings } from 'dashboard/composables/useUISettings';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
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
    class="flex flex-col bg-n-alpha-3 backdrop-blur-[100px] border-0 outline outline-1 outline-n-container shadow-lg z-50 max-w-64 min-w-[170px] w-fit rounded-xl divide-y divide-n-weak dark:divide-n-strong"
  >
    <div class="flex items-center gap-2 justify-between p-3 rounded-t-lg h-11">
      <div class="flex gap-1.5 min-w-0">
        <span class="i-lucide-arrow-down-up size-3.5 text-n-slate-12" />
        <span class="text-xs font-medium text-n-slate-12 truncate min-w-0">
          {{ $t('INBOX.DISPLAY_MENU.SORT') }}
        </span>
      </div>
      <div v-on-clickaway="() => (showSortMenu = false)" class="relative">
        <NextButton
          :label="activeSortOption"
          icon="i-lucide-chevron-down"
          slate
          trailing-icon
          xs
          outline
          class="w-fit min-w-20 max-w-32"
          @click="openSortMenu"
        />
        <div
          v-if="showSortMenu"
          class="absolute flex flex-col gap-0.5 bg-n-alpha-3 backdrop-blur-[100px] z-60 rounded-lg p-0.5 w-fit min-w-20 max-w-32 top-px outline outline-1 outline-n-container dark:outline-n-strong"
        >
          <div
            v-for="option in sortOptions"
            :key="option.key"
            role="button"
            class="flex rounded-md h-5 w-full items-center justify-between px-1.5 py-0.5 gap-2 whitespace-nowrap"
            :class="{
              'bg-n-brand/10 dark:bg-n-brand/10': activeSort === option.key,
            }"
            @click.stop="onSortOptionClick(option)"
          >
            <span
              class="text-xs font-medium hover:text-n-brand truncate min-w-0 dark:hover:text-n-brand"
              :class="{
                'text-n-blue-text dark:text-n-blue-text':
                  activeSort === option.key,
                'text-n-slate-11': activeSort !== option.key,
              }"
            >
              {{ option.name }}
            </span>
            <span
              v-if="activeSort === option.key"
              class="i-lucide-check size-2.5 flex-shrink-0 text-n-blue-text"
            />
          </div>
        </div>
      </div>
    </div>
    <div>
      <span class="px-3 py-4 text-xs font-medium text-n-slate-11">
        {{ $t('INBOX.DISPLAY_MENU.DISPLAY') }}
      </span>
      <div class="flex flex-col divide-y divide-n-weak dark:divide-n-strong">
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
            class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-n-brand dark:checked:bg-n-brand after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
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
