<template>
  <div>
    <woot-button
      variant="smooth"
      size="small"
      color-scheme="secondary"
      class="selector-button"
      @click="toggleDropdown"
    >
      <span class="text-truncate button-text">
        {{ $t('CHAT_LIST.CHAT_SORT_BY_FILTER_ITEMS')[activeSortBy]['LABEL'] }}
      </span>
      <fluent-icon
        :icon="showActionsDropdown ? 'chevron-up' : 'chevron-down'"
        class="icon"
        size="14"
      />
    </woot-button>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
    >
      <woot-dropdown-menu>
        <woot-dropdown-sub-menu
          :title="this.$t('CHAT_LIST.CHAT_SORT_BY_FILTER')"
        >
          <woot-dropdown-item
            v-for="(value, sortBy) in $t('CHAT_LIST.CHAT_SORT_BY_FILTER_ITEMS')"
            :key="sortBy"
          >
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              class="filter-items"
              :class="{ active: sortBy === activeSortBy }"
              @click="() => onTabChange(sortBy)"
            >
              <span class="text-truncate button-text">{{ value['TEXT'] }}</span>
              <fluent-icon
                v-if="sortBy === activeSortBy"
                icon="checkmark"
                size="16"
                class="icon"
              />
            </woot-button>
          </woot-dropdown-item>
        </woot-dropdown-sub-menu>
      </woot-dropdown-menu>
    </div>
  </div>
</template>

<script>
import wootConstants from 'dashboard/constants';
import { mixin as clickaway } from 'vue-clickaway';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import WootDropdownSubMenu from 'shared/components/ui/dropdown/DropdownSubMenu';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    WootDropdownSubMenu,
  },
  mixins: [clickaway],

  data: () => ({
    activeSortBy: wootConstants.SORT_BY_TYPE.LATEST,
    showActionsDropdown: false,
  }),

  methods: {
    toggleDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
    onTabChange(value) {
      this.activeSortBy = value;
      this.$store.dispatch('setChatSortByFilter', this.activeSortBy);
      this.$emit('changeSortByFilter', this.activeSortBy);
      this.closeDropdown();
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';

.filter-items {
  &.active {
    background: var(--s-25);
    border-color: var(--s-50);
    font-weight: var(--font-weight-medium);
  }
}

::v-deep {
  .button.small {
    height: 2.8rem;
    padding: var(--space-smaller) var(--space-small);
    max-width: 100%;

    @include breakpoint(large up) {
      max-width: 16rem;
    }
    @include breakpoint(xxlarge up) {
      max-width: 100%;
    }
  }
  .button__content {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
}

.button-text {
  line-height: 1.2;
}

.icon {
  margin-left: var(--space-smaller);
}
</style>
