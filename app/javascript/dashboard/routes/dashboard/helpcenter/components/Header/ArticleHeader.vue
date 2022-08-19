<template>
  <div class="header--wrap">
    <div class="header-left--wrap">
      <woot-sidemenu-icon />
      <h3 class="page-title">{{ headerTitle }}</h3>
      <span class="text-block-title count-view">{{ `(${count})` }}</span>
    </div>
    <div class="header-right--wrap">
      <woot-button
        v-if="shouldShowSettings"
        class-names="article--buttons"
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
        class-names="article--buttons"
        icon="arrow-sort"
        color-scheme="secondary"
        size="small"
        variant="hollow"
        @click="openDropdown"
      >
        {{ $t('HELP_CENTER.HEADER.SORT') }}
        <span class="selected-value">
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
        class-names="article--buttons"
        variant="hollow"
        size="small"
        color-scheme="secondary"
      />
      <woot-button
        class-names="article--buttons"
        size="small"
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
.header--wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  height: var(--space-larger);
}
.header-left--wrap {
  display: flex;
  align-items: center;

  .page-title {
    margin-bottom: 0;
  }
}
.header-right--wrap {
  display: flex;
  align-items: center;
}
.count-view {
  margin-left: var(--space-smaller);
}
.dropdown-pane--open {
  top: var(--space-larger);
  right: 14.8rem;
}
.selected-value {
  display: inline-flex;
  margin-left: var(--space-smaller);
  color: var(--b-900);
  align-items: center;
}
.dropdown-arrow {
  margin-left: var(--space-smaller);
}
.article--buttons {
  margin-left: var(--space-smaller);
}
</style>
