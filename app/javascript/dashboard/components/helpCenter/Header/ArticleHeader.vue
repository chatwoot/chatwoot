<template>
  <div class="header--wrap">
    <div class="header-left--wrap">
      <h3 class="page-title">{{ headerTitle }}</h3>
      <span class="text-block-title count-view">{{ `(${count})` }}</span>
    </div>
    <div class="header-right--wrap">
      <woot-button
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
              {{ 'Status' }}
            </woot-button>
          </woot-dropdown-item>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="dual-screen-clock"
            >
              {{ 'Created' }}
            </woot-button>
          </woot-dropdown-item>
          <woot-dropdown-item>
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              icon="calendar-clock"
            >
              {{ 'Last edited' }}
            </woot-button>
          </woot-dropdown-item>
        </woot-dropdown-menu>
      </div>
      <woot-button
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
  },
};
</script>

<style scoped lang="scss">
.header--wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-small) var(--space-normal);
  width: 100%;
  height: var(--space-larger);
}
.header-left--wrap {
  display: flex;
  align-items: center;
}
.header-right--wrap {
  display: flex;
  align-items: center;
}
.count-view {
  margin-left: var(--space-smaller);
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
