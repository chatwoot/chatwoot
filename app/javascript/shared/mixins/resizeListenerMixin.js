export default {
  mounted() {
    window.addEventListener('resize', this.handleResize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.onResizeHandler);
  },
  methods: {
    // Resize event for layout changes
    onResizeHandler() {
      let throttled = false;
      const delay = 150;

      if (throttled) {
        return;
      }
      throttled = true;

      setTimeout(() => {
        throttled = false;
        this.handleResize();
      }, delay);
    },
  },
};
