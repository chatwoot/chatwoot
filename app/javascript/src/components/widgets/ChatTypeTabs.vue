<template>
  <woot-tabs :index="tabsIndex"
    @change="onTabChange">
    <woot-tabs-item :name="item.name" :count="item.count" v-for="item in items"></woot-tabs-item>
  </woot-tabs>
</template>
<script>
/* eslint no-console: 0 */

export default {
  props: ['items', 'activeTabIndex'],
  data() {
    return {
      tabsIndex: 0,
    };
  },
  methods: {
    onTabChange(...args) {
      this.$emit('chatTabChange', args[0]);
      this.tabsIndex = args[0];
    },
  },
  created() {
    this.tabsIndex = this.activeTabIndex;
  },
};
</script>
