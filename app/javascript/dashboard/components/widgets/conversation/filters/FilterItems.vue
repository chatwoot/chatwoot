<template>
  <div style="position: relative;">
    <woot-button
      variant="smooth"
      size="tiny"
      color-scheme="secondary"
      class="selector-button"
      @click="toggleDropdown"
    >
      <fluent-icon icon="menu-icon" class="icon" size="12" />
      {{ title }}
      <span v-if="activeTypeCount" class="filter-count badge secondary">
        {{ activeTypeCount }}
      </span>
      <fluent-icon
        :icon="showActionsDropdown ? 'chevron-up' : 'chevron-down'"
        class="icon dropdown-icon"
        size="12"
      />
    </woot-button>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
      style=" width: 250px; padding:0;right: 0;
      "
    >
      <div
        style="justify-content: space-between;
    display: flex;
    align-items: center;padding: 8px 16px;"
      >
        <span style="font-size: 1.2rem;">Status</span>
        <chat-filter />
      </div>
      <div
        style="justify-content: space-between;
    display: flex;
    align-items: center;padding: 8px 16px;"
      >
        <span style="font-size: 1.2rem;">Order by</span>
        <sort-filters value="Oldest" />
      </div>

      <!-- <div
        style="justify-content: space-between;
    display: flex;
    align-items: center;padding: 8px 16px;"
      >
        <span style="font-size: 1.2rem;">Last activity at</span>
        <sort-filters value="Newest" />
      </div>

      <div
        style="justify-content: space-between;
    display: flex;
    align-items: center;padding: 8px 16px;"
      >
        <span style="font-size: 1.2rem;">Last message at</span>
        <sort-filters value="Oldest" />
      </div> -->

      <!-- <woot-dropdown-menu>
        <woot-dropdown-sub-menu :title="dropdownTitle">
          <woot-dropdown-item v-for="item in items" :key="item.key">
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="tiny"
              class="filter-items"
              :class="{ active: item.key === selectedValue }"
              @click="() => onTabChange(item.key)"
            >
              <div class="item--wrap">
                <span>{{ item.name }}</span>
                <span v-if="item.count" class="badge">
                  {{ item.count.toLocaleString() }}
                </span>
              </div>
              <fluent-icon
                v-if="item.key === selectedValue"
                icon="checkmark"
                size="14"
                class="icon"
              />
            </woot-button>
          </woot-dropdown-item>
        </woot-dropdown-sub-menu>
      </woot-dropdown-menu> -->
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import WootDropdownSubMenu from 'shared/components/ui/dropdown/DropdownSubMenu';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';
import ChatFilter from 'dashboard/components/widgets/conversation/ChatFilter.vue';
import SortFilters from 'dashboard/components/widgets/conversation/SortFilters.vue';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    WootDropdownSubMenu,
    ChatFilter,
    SortFilters,
  },
  mixins: [clickaway],
  props: {
    title: {
      type: String,
      default: '',
    },
    dropdownTitle: {
      type: String,
      default: '',
    },
    items: {
      type: Array,
      default: () => [],
    },
    selectedValue: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    activeTypeCount: {
      type: String,
      default: '',
    },
  },
  data: () => ({
    showActionsDropdown: false,
  }),
  mounted() {
    console.log('mounted', this.icon);
  },
  methods: {
    onTabChange(value) {
      this.$emit('changeFilter', value);
      this.closeDropdown();
    },
    toggleDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.badge {
  margin-left: var(--space-smaller);
  background: var(--s-100);
  color: var(--s-800);
  font-weight: var(--font-weight-bold);
}

.filter-items {
  .item--wrap {
    display: flex;
    align-items: center;
  }

  &.active {
    background: var(--s-25);
    border-color: var(--s-50);
    font-weight: var(--font-weight-medium);
  }
}

::v-deep {
  .selector-button {
    padding: var(--space-smaller) var(--space-smaller) var(--space-smaller)
      var(--space-small);
  }

  .button__content {
    display: flex;
    align-items: center;
    justify-content: space-between;
    white-space: nowrap;
  }
}

.icon {
  margin-right: var(--space-smaller);
}
.dropdown-icon {
  margin-left: var(--space-smaller);
}
</style>
