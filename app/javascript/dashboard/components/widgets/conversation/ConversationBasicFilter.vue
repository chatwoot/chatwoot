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
      {{ this.$t('CHAT_LIST.VIEW_FILTER') }}
      <fluent-icon
        :icon="showActionsDropdown ? 'chevron-up' : 'chevron-down'"
        class="icon dropdown-icon"
        size="12"
      />
    </woot-button>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open basic-filter"
    >
      <div class="filter__item">
        <span>{{ this.$t('CHAT_LIST.CHAT_SORT.STATUS') }}</span>
        <filter-item
          type="status"
          :selected-value="chatStatus"
          :items="chatStatusItems"
          @onChangeFilter="onChangeFilter"
        />
      </div>
      <div class="filter__item">
        <span>{{ this.$t('CHAT_LIST.CHAT_SORT.ORDER_BY') }}</span>
        <filter-item
          type="sort"
          :selected-value="chatSortFilter"
          :items="chatSortItems"
          @onChangeFilter="onChangeFilter"
        />
      </div>
    </div>
  </div>
</template>

<script>
import wootConstants from 'dashboard/constants';
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import FilterItem from './FilterItem';

export default {
  components: {
    FilterItem,
  },
  mixins: [clickaway],
  data() {
    return {
      showActionsDropdown: false,
      chatStatusItems: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS'),
      chatSortItems: this.$t('CHAT_LIST.CHAT_SORT_FILTER_ITEMS'),
    };
  },
  computed: {
    ...mapGetters({
      chatStatusFilter: 'getChatStatusFilter',
      chatSortFilter: 'getChatSortFilter',
    }),
    chatStatus() {
      return this.chatStatusFilter || wootConstants.STATUS_TYPE.OPEN;
    },
    sortFilter() {
      return this.chatSortFilter || wootConstants.SORT_BY_TYPE.LATEST;
    },
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
    onChangeFilter(type, value) {
      this.$emit('changeFilter', type, value);
    },
  },
};
</script>
<style lang="scss" scoped>
.basic-filter {
  width: 210px;
  padding: 0;
  margin-top: var(--space-smaller);
  right: 0;
  padding: var(--space-normal);
  span {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
  }
  .filter__item {
    justify-content: space-between;
    display: flex;
    align-items: center;

    &:last-child {
      margin-top: var(--space-normal);
    }

    span {
      font-size: var(--font-size-mini);
    }
  }
}
.icon {
  margin-right: var(--space-smaller);
}
.dropdown-icon {
  margin-left: var(--space-smaller);
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
</style>
