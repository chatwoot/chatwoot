<template>
  <select v-model="activeValue" class="status--filter" @change="onTabChange()">
    <option v-for="(value, status) in items" :key="status" :value="status">
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
  props: {
    selectedValue: {
      type: String,
      required: true,
    },
    items: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      activeValue: this.selectedValue,
    };
  },
  methods: {
    handleKeyEvents(e) {
      if (hasPressedAltAndBKey(e) && this.type === 'status') {
        if (this.activeValue === wootConstants.STATUS_TYPE.OPEN) {
          this.activeValue = wootConstants.STATUS_TYPE.RESOLVED;
        } else if (this.activeValue === wootConstants.STATUS_TYPE.RESOLVED) {
          this.activeValue = wootConstants.STATUS_TYPE.PENDING;
        } else if (this.activeValue === wootConstants.STATUS_TYPE.PENDING) {
          this.activeValue = wootConstants.STATUS_TYPE.SNOOZED;
        } else if (this.activeValue === wootConstants.STATUS_TYPE.SNOOZED) {
          this.activeValue = wootConstants.STATUS_TYPE.ALL;
        } else if (this.activeValue === wootConstants.STATUS_TYPE.ALL) {
          this.activeValue = wootConstants.STATUS_TYPE.OPEN;
        }
      }
      // TOOD: Enable this when we have a sort by filter
      // this.onTabChange();
    },
    onTabChange() {
      if (this.type === 'status') {
        this.$store.dispatch('setChatStatusFilter', this.activeValue);
      } else {
        this.$store.dispatch('setChatSortFilter', this.activeValue);
      }

      this.$emit('onChangeFilter', this.activeValue, this.type);
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
