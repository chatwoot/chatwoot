<template>
  <select v-model="activeStatus" class="status--filter" @change="onTabChange()">
    <option
      v-for="(value, status) in $t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS')"
      :key="status"
      :value="status"
    >
      {{ value['TEXT'] }}
    </option>
  </select>
</template>

<script>
import wootConstants from '../../../constants';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { hasPressedAltAndBKey } from 'shared/helpers/KeyboardHelpers';

export default {
  mixins: [eventListenerMixins],
  data: () => ({
    activeStatus: wootConstants.STATUS_TYPE.OPEN,
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
    onTabChange() {
      this.$store.dispatch('setChatFilter', this.activeStatus);
      this.$emit('statusFilterChange', this.activeStatus);
    },
  },
};
</script>
<style lang="scss" scoped>
.status--filter {
  background-color: var(--color-background-light);
  border: 1px solid var(--color-border);
  font-size: var(--font-size-mini);
  height: var(--space-medium);
  margin: 0 var(--space-smaller);
  padding: 0 var(--space-medium) 0 var(--space-small);
  width: auto;
}
</style>
