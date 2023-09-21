export default {
  props: {
    trianglePosition: {
      type: String,
      default: '0',
    },
  },
  computed: {
    cssVars() {
      return {
        '--triangle-position': this.trianglePosition + 'rem',
      };
    },
  },
};
