export default {
  methods: {
    async replaceRoute(name, params = {}) {
      if (this.$route.name !== name) {
        return this.$router.replace({ name, params });
      }
      return undefined;
    },
  },
};
