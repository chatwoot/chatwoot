export default {
  name: 'WootTabs',
  props: {
    index: {
      type: Number,
      default: 0,
    },
    border: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return { hasScroll: false };
  },
  created() {
    window.addEventListener('resize', this.computeScrollWidth);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.computeScrollWidth);
  },
  mounted() {
    this.computeScrollWidth();
  },
  methods: {
    computeScrollWidth() {
      const tabElement = this.$el.getElementsByClassName('tabs')[0];
      this.hasScroll = tabElement.scrollWidth > tabElement.clientWidth;
    },
    onScrollClick(direction) {
      const tabElement = this.$el.getElementsByClassName('tabs')[0];
      let scrollPosition = tabElement.scrollLeft;
      if (direction === 'left') {
        scrollPosition -= 100;
      } else {
        scrollPosition += 100;
      }
      tabElement.scrollTo({
        top: 0,
        left: scrollPosition,
        behavior: 'smooth',
      });
    },
    createScrollButton(createElement, direction) {
      if (!this.hasScroll) {
        return false;
      }
      return createElement(
        'button',
        {
          class: 'tabs--scroll-button button clear secondary button--only-icon',
          on: { click: () => this.onScrollClick(direction) },
        },
        [
          createElement('fluent-icon', {
            props: { icon: `chevron-${direction}`, size: 16 },
          }),
        ]
      );
    },
  },
  render(createElement) {
    const Tabs = this.$slots.default
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
    const leftButton = this.createScrollButton(createElement, 'left');
    const rightButton = this.createScrollButton(createElement, 'right');
    return (
      <div
        class={{
          'tabs--container--with-border': this.border,
          'tabs--container': true,
        }}
      >
        {leftButton}
        <ul class={{ tabs: true, 'tabs--with-scroll': this.hasScroll }}>
          {Tabs}
        </ul>
        {rightButton}
      </div>
    );
  },
};
