<template>
  <woot-tabs :index="tabsIndex" @change="onTabChange">
    <woot-tabs-item
      v-for="item in items"
      :key="item.name"
      :name="item.name"
      :count="item.count"
    />
  </woot-tabs>
</template>
<script>
/* eslint no-console: 0 */

export default {
  props: {
    items: {
      type: Array,
      default: () => [],
    },
    activeTabIndex: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      tabsIndex: 0,
    };
  },
  created() {
    this.tabsIndex = this.activeTabIndex;
  },
  methods: {
    onTabChange(selectedTabIndex) {
      if (selectedTabIndex !== this.tabsIndex) {
        this.$emit('chatTabChange', selectedTabIndex);
        this.tabsIndex = selectedTabIndex;
      }
    },
  },
};
</script>
