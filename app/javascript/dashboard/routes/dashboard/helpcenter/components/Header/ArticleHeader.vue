<template>
  <div class="flex items-center justify-between w-full h-16 pt-2">
    <div class="flex items-center">
      <woot-sidemenu-icon />
      <div class="flex items-center my-0 mx-2">
        <h3 class="text-2xl text-slate-800 dark:text-slate-100 mb-0">
          {{ headerTitle }}
        </h3>
        <span class="text-sm text-slate-600 dark:text-slate-300 my-0 mx-2">{{
          `(${count})`
        }}</span>
      </div>
    </div>
    <div class="flex items-center gap-1">
      <woot-button
        v-if="shouldShowSettings"
        icon="filter"
        color-scheme="secondary"
        variant="hollow"
        size="small"
        @click="openFilterModal"
      >
        {{ $t('HELP_CENTER.HEADER.FILTER') }}
      </woot-button>
      <woot-button
        v-if="shouldShowSettings"
        icon="arrow-sort"
        color-scheme="secondary"
        size="small"
        variant="hollow"
        @click="openDropdown"
      >
        {{ $t('HELP_CENTER.HEADER.SORT') }}
        <span
          class="inline-flex ml-1 rtl:ml-0 rtl:mr-1 items-center text-slate-800 dark:text-slate-100"
        >
          {{ selectedValue }}
          <Fluent-icon class="dropdown-arrow" icon="chevron-down" size="14" />
        </span>
      </woot-button>
      <div
        v-if="showSortByDropdown"
        v-on-clickaway="closeDropdown"
        class="dropdown-pane dropdown-pane--open"
      >
        <woot-dropdown-menu>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="send-clock"
            >
              {{ $t('HELP_CENTER.HEADER.DROPDOWN_OPTIONS.PUBLISHED') }}
            </woot-button>
          </woot-dropdown-item>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="dual-screen-clock"
            >
              {{ $t('HELP_CENTER.HEADER.DROPDOWN_OPTIONS.DRAFT') }}
            </woot-button>
          </woot-dropdown-item>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="calendar-clock"
            >
              {{ $t('HELP_CENTER.HEADER.DROPDOWN_OPTIONS.ARCHIVED') }}
            </woot-button>
          </woot-dropdown-item>
        </woot-dropdown-menu>
      </div>
      <woot-button
        v-if="shouldShowSettings"
        v-tooltip.top-end="$t('HELP_CENTER.HEADER.SETTINGS_BUTTON')"
        icon="settings"
        variant="hollow"
        size="small"
        color-scheme="secondary"
      />
      <woot-button
        size="small"
        icon="add"
        color-scheme="primary"
        @click="onClickNewArticlePage"
      >
        {{ $t('HELP_CENTER.HEADER.NEW_BUTTON') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon';
export default {
  components: {
    FluentIcon,
    WootDropdownItem,
    WootDropdownMenu,
  },
  mixins: [clickaway],
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    count: {
      type: Number,
      default: 0,
    },
    selectedValue: {
      type: String,
      default: '',
    },
    shouldShowSettings: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showSortByDropdown: false,
    };
  },
  methods: {
    openFilterModal() {
      this.$emit('openModal');
    },
    openDropdown() {
      this.$emit('open');
      this.showSortByDropdown = true;
    },
    closeDropdown() {
      this.$emit('close');
      this.showSortByDropdown = false;
    },
    onClickNewArticlePage() {
      this.$emit('newArticlePage');
    },
  },
};
</script>

<style scoped lang="scss">
.dropdown-pane--open {
  @apply top-12 right-[9.25rem];
}
.dropdown-arrow {
  @apply ml-1 rtl:ml-0 rtl:mr-1;
}
</style>
