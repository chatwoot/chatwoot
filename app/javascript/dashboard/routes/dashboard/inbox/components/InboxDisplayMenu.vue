<template>
  <div
    class="flex flex-col bg-white z-50 dark:bg-slate-900 w-[170px] border shadow-md border-slate-100 dark:border-slate-700/50 rounded-xl divide-y divide-slate-100 dark:divide-slate-700/50"
  >
    <div class="flex items-center justify-between h-11 p-3 rounded-t-lg">
      <div class="flex gap-1.5">
        <fluent-icon
          icon="arrow-sort"
          type="outline"
          size="16"
          class="text-slate-700 dark:text-slate-100"
        />
        <span class="font-medium text-xs text-slate-800 dark:text-slate-100">
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
            :class="
              activeSort === option.key ? 'bg-woot-50 dark:bg-woot-700/50' : ''
            "
            @click.stop="onSortOptionClick(option.key)"
          >
            <span
              class="text-xs font-medium hover:text-woot-600 dark:hover:text-woot-600"
              :class="
                activeSort === option.key
                  ? 'text-woot-600 dark:text-woot-600'
                  : 'text-slate-600 dark:text-slate-300'
              "
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
        class="font-medium text-xs py-4 px-3 text-slate-400 dark:text-slate-400"
      >
        {{ $t('INBOX.DISPLAY_MENU.DISPLAY') }}
      </span>
      <div
        class="flex flex-col divide-y divide-slate-100 dark:divide-slate-700/50"
      >
        <div
          v-for="option in displayOptions"
          :key="option.id"
          class="flex items-center px-3 py-2 gap-1.5 h-9"
        >
          <input
            :id="option.value"
            type="checkbox"
            :name="option.value"
            :checked="option.selected"
            class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
            @change="updateDisplayOption(option)"
          />
          <label
            :for="option.value"
            class="text-xs font-medium text-slate-800 !ml-0 !mr-0 dark:text-slate-100"
          >
            {{ option.name }}
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      showSortMenu: false,
      displayOptions: [
        {
          id: 1,
          name: this.$t('INBOX.DISPLAY_MENU.DISPLAY_OPTIONS.SNOOZED'),
          value: 'snoozed',
          selected: false,
        },
        {
          id: 2,
          name: this.$t('INBOX.DISPLAY_MENU.DISPLAY_OPTIONS.READ'),
          value: 'read',
          selected: true,
        },
      ],
      sortOptions: [
        {
          name: this.$t('INBOX.DISPLAY_MENU.SORT_OPTIONS.NEWEST'),
          key: 'newest',
        },
        {
          name: this.$t('INBOX.DISPLAY_MENU.SORT_OPTIONS.OLDEST'),
          key: 'oldest',
        },
      ],
      activeSort: 'newest',
    };
  },
  computed: {
    activeSortOption() {
      return this.sortOptions.find(option => option.key === this.activeSort)
        .name;
    },
  },
  methods: {
    updateDisplayOption(option) {
      option.selected = !option.selected;
      // TODO: Update the display options
    },
    openSortMenu() {
      this.showSortMenu = !this.showSortMenu;
    },
    onSortOptionClick(key) {
      this.activeSort = key;
      this.showSortMenu = false;
      // TODO: Update the sort options
    },
  },
};
</script>
