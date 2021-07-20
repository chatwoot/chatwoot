<template>
  <select v-model="activeStatus" class="status--filter" @change="onTabChange()">
    <option
      v-for="item in $t('CHAT_LIST.CHAT_STATUS_ITEMS')"
      :key="item['VALUE']"
      :value="item['VALUE']"
    >
      {{ item['TEXT'] }}
    </option>
  </select>
</template>

<script>
import wootConstants from '../../../constants';
import { hasPressedShiftAndBKey } from 'shared/helpers/KeyboardHelpers';

export default {
  data: () => ({
    activeStatus: wootConstants.STATUS_TYPE.OPEN,
  }),
  mounted() {
    document.addEventListener('keydown', this.handleKeyEvents);
  },
  methods: {
    handleKeyEvents(e) {
      if (hasPressedShiftAndBKey(e)) {
        if (this.activeStatus === wootConstants.STATUS_TYPE.OPEN) {
          this.activeStatus = wootConstants.STATUS_TYPE.RESOLVED;
        } else if (this.activeStatus === wootConstants.STATUS_TYPE.RESOLVED) {
          this.activeStatus = wootConstants.STATUS_TYPE.BOT;
        } else if (this.activeStatus === wootConstants.STATUS_TYPE.BOT) {
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
