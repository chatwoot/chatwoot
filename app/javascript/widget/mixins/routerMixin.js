export default {
  methods: {
    async replaceRoute(name) {
      if (this.$route.name !== name) {
        return this.$router.replace({ name });
      }
      return undefined;
    },
  },
};
