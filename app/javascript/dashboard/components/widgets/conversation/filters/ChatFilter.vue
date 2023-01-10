<template>
  <woot-chat-list-filter
    :title="activeStatusLabel"
    :dropdown-title="$t('CHAT_LIST.CHAT_STATUS_FILTER')"
    :items="statusItems"
    :selected-value="activeStatus"
    @changeFilter="onTabChange"
  />
</template>

<script>
import wootConstants from 'dashboard/constants';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { hasPressedAltAndBKey } from 'shared/helpers/KeyboardHelpers';
import WootChatListFilter from './FilterItems';

export default {
  components: {
    WootChatListFilter,
  },
  mixins: [eventListenerMixins],
  data: () => ({
    activeStatus: wootConstants.STATUS_TYPE.OPEN,
    statusItems: [
      {
        key: wootConstants.STATUS_TYPE.OPEN,
        name: 'Open',
      },
      {
        key: wootConstants.STATUS_TYPE.RESOLVED,
        name: 'Resolved',
      },
      {
        key: wootConstants.STATUS_TYPE.PENDING,
        name: 'Pending',
      },
      {
        key: wootConstants.STATUS_TYPE.SNOOZED,
        name: 'Snoozed',
      },
      {
        key: wootConstants.STATUS_TYPE.ALL,
        name: 'All',
      },
    ],
  }),

  computed: {
    activeStatusLabel() {
      return this.statusItems.find(item => item.key === this.activeStatus).name;
    },
  },
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
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep {
  .dropdown-pane {
    width: var(--space-mega);
  }
}
</style>
