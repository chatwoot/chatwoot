<template>
  <div>
    <woot-button
      variant="smooth"
      size="small"
      color-scheme="secondary"
      class="selector-button"
      @click="toggleDropdown"
    >
      {{ $t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS')[activeStatus]['TEXT'] }}
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
          :title="$t('CHAT_LIST.CHAT_STATUS_FILTER')"
        >
          <woot-dropdown-item
            v-for="(value, status) in $t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS')"
            :key="status"
          >
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              class="filter-items"
              :class="{ active: status === activeStatus }"
              @click="() => onTabChange(status)"
            >
              {{ value['TEXT'] }}
              <fluent-icon
                v-if="status === activeStatus"
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
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { hasPressedAltAndBKey } from 'shared/helpers/KeyboardHelpers';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import WootDropdownSubMenu from 'shared/components/ui/dropdown/DropdownSubMenu';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    WootDropdownSubMenu,
  },
  mixins: [eventListenerMixins, clickaway],
  data: () => ({
    activeStatus: wootConstants.STATUS_TYPE.OPEN,
    showActionsDropdown: false,
  }),
  methods: {
    handleKeyEvents(e) {
      if (hasPressedAltAndBKey(e)) {
        if (this.activeStatus === wootConstants.STATUS_TYPE.OPEN) {
          this.activeStatus = wootConstants.STATUS_TYPE.RESOLVED;
        } else if (this.activeStatus === wootConstants.STATUS_TYPE.RESOLVED) {
          this.activeStatus = wootConstants.STATUS_TYPE.PENDING;
        } else if (this.activeStatus === wootConstants.STATUS_TYPE.PENDING) {
          this.activeStatus = wootConstants.STATUS_TYPE.SNOOZED;
        } else if (this.activeStatus === wootConstants.STATUS_TYPE.SNOOZED) {
          this.activeStatus = wootConstants.STATUS_TYPE.ALL;
        } else if (this.activeStatus === wootConstants.STATUS_TYPE.ALL) {
          this.activeStatus = wootConstants.STATUS_TYPE.OPEN;
        }
      }
      this.onTabChange();
    },
    onTabChange(value) {
      if (value) {
        this.activeStatus = value;
      }
      this.$store.dispatch('setChatFilter', this.activeStatus);
      this.$emit('statusFilterChange', this.activeStatus);
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

::v-deep {
  .dropdown-pane {
    width: var(--space-mega);
  }
  .button.small {
    height: 2.8rem;
    padding: var(--space-smaller) var(--space-small);
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
