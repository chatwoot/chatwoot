export default {
  mounted() {
    document.addEventListener('keydown', this.handleKeyEvents);
  },
  destroyed() {
    document.removeEventListener('keydown', this.handleKeyEvents);
  },
};
