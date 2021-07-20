<template>
  <woot-tabs :index="activeTabIndex" @change="onTabChange">
    <woot-tabs-item
      v-for="item in items"
      :key="item.key"
      :name="item.name"
      :count="item.count"
    />
  </woot-tabs>
</template>
<script>
import wootConstants from '../../constants';
import { hasPressedShiftAndNKey } from 'shared/helpers/KeyboardHelpers';

export default {
  props: {
    items: {
      type: Array,
      default: () => [],
    },
    activeTab: {
      type: String,
      default: wootConstants.ASSIGNEE_TYPE.ME,
    },
  },
  computed: {
    activeTabIndex() {
      return this.items.findIndex(item => item.key === this.activeTab);
    },
  },
  mounted() {
    document.addEventListener('keydown', this.handleKeyEvents);
  },
  methods: {
    handleKeyEvents(e) {
      if (hasPressedShiftAndNKey(e)) {
        if (this.activeTabIndex === 2) {
          this.onTabChange(0);
        } else {
          this.onTabChange(this.activeTabIndex + 1);
        }
      }
    },
    onTabChange(selectedTabIndex) {
      if (this.items[selectedTabIndex].key !== this.activeTab) {
        this.$emit('chatTabChange', this.items[selectedTabIndex].key);
      }
    },
  },
};
</script>
