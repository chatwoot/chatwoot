<template>
  <woot-chat-list-filter
    :title="activeStatusLabel"
    :dropdown-title="$t('CHAT_LIST.CHAT_STATUS_FILTER.TITLE')"
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
  data() {
    return {
      activeStatus: wootConstants.STATUS_TYPE.OPEN,
      statusItems: [
        {
          key: wootConstants.STATUS_TYPE.OPEN,
          name: this.$t('CHAT_LIST.CHAT_STATUS_FILTER.ITEMS.OPEN'),
        },
        {
          key: wootConstants.STATUS_TYPE.RESOLVED,
          name: this.$t('CHAT_LIST.CHAT_STATUS_FILTER.ITEMS.RESOLVED'),
        },
        {
          key: wootConstants.STATUS_TYPE.PENDING,
          name: this.$t('CHAT_LIST.CHAT_STATUS_FILTER.ITEMS.PENDING'),
        },
        {
          key: wootConstants.STATUS_TYPE.SNOOZED,
          name: this.$t('CHAT_LIST.CHAT_STATUS_FILTER.ITEMS.SNOOZED'),
        },
        {
          key: wootConstants.STATUS_TYPE.ALL,
          name: this.$t('CHAT_LIST.CHAT_STATUS_FILTER.ITEMS.ALL'),
        },
      ],
    };
  },

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
