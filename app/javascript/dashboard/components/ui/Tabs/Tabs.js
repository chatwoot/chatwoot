import Vue from 'vue';

export default Vue.component('woot-tabs', {
  props: {
    index: {
      type: Number,
      default: 0,
    },
  },
  render(createElement) {
    const tabItems = this.$slots.default
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

    return createElement(
      'ul',
      {
        class: { tabs: true },
      },
      tabItems
    );
  },
});
