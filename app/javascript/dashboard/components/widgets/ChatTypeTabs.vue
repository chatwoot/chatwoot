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
  methods: {
    onTabChange(selectedTabIndex) {
      if (this.items[selectedTabIndex].key !== this.activeTab) {
        this.$emit('chatTabChange', this.items[selectedTabIndex].key);
      }
    },
  },
};
</script>
