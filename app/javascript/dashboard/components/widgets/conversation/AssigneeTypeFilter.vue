<template>
  <div>
    <woot-button
      variant="smooth"
      size="small"
      color-scheme="secondary"
      class="selector-button"
      @click="toggleDropdown"
    >
      {{ $t('CHAT_LIST.CHAT_ASSIGNEE_TYPE_FILTER_ITEMS')[activeType]['TEXT'] }}
      <fluent-icon
        :icon="showActionsDropdown ? 'chevron-up' : 'chevron-down'"
        class="icon"
        size="16"
      />
    </woot-button>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open"
    >
      <woot-dropdown-menu>
        <woot-dropdown-sub-menu
          :title="this.$t('CHAT_LIST.CHAT_ASSIGNEE_TYPE_FILTER')"
        >
          <woot-dropdown-item
            v-for="assigneeType in items"
            :key="assigneeType.key"
          >
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              class="filter-items"
              :class="{ active: assigneeType.key === activeType }"
              @click="() => onTabChange(assigneeType.key)"
            >
              <div>
                <span>{{ assigneeType.name }}</span>
                <span class="count">{{ assigneeType.count }}</span>
              </div>
              <fluent-icon
                v-if="assigneeType.key === activeType"
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
import wootConstants from '../../../constants';
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
    activeType: wootConstants.ASSIGNEE_TYPE.ME,
    showActionsDropdown: false,
  }),
  props: {
    items: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    onTabChange(value) {
      if (value) {
        this.activeType = value;
      }
      this.$store.dispatch('setChatFilter', this.activeType);
      this.$emit('filterChange', this.activeType);
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
.filter-items {
  &.active {
    background: var(--s-25);
    border-color: var(--s-50);
    font-weight: var(--font-weight-medium);
  }
}

.count {
  background: var(--s-75);
  border-radius: var(--border-radius-normal);
  color: var(--s-700);
  font-size: var(--font-size-micro);
  padding: var(--space-micro) var(--space-smaller);
}

::v-deep {
  .dropdown-pane {
    width: 14rem;
  }
  .button.small {
    height: 2.8rem;
  }
  .button__content {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
}

.icon {
  margin-left: var(--space-small);
}
</style>
