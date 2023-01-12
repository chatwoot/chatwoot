<template>
  <div>
    <woot-button
      variant="smooth"
      size="tiny"
      :icon="icon"
      color-scheme="secondary"
      class="selector-button"
      @click="toggleDropdown"
    >
      {{ title }}
      <span v-if="activeTypeCount" class="filter-count badge secondary">
        {{ activeTypeCount }}
      </span>
      <fluent-icon
        :icon="showActionsDropdown ? 'chevron-up' : 'chevron-down'"
        class="icon"
        size="12"
      />
    </woot-button>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
    >
      <woot-dropdown-menu>
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
      </woot-dropdown-menu>
    </div>
  </div>
</template>

<script>
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
  margin-left: var(--space-smaller);
}
</style>
