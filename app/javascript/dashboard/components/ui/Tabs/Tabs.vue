<template>
  <ul class="tabs">
    {{
      tabItems
    }}
  </ul>
</template>
<script>
export default {
  name: 'WootTabs',
  props: {
    index: {
      type: Number,
      default: 0,
    },
  },
  tabItems() {
    return this.$slots.default
      .filter(
        node =>
          node.componentOptions &&
          node.componentOptions.tag === 'woot-tabs-item'
      )
      .map((node, index) => {
        const data = node.componentOptions.propsData;
        data.index = index;
        return node;
      });
  },
};
</script>
