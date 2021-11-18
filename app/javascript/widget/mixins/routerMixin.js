export default {
  methods: {
    replaceRoute(name) {
      if (this.$router.name !== name) {
        this.$router.replace({ name });
      }
    },
  },
};
