export default {
  methods: {
    replaceRoute(name) {
      if (this.$route.name !== name) {
        this.$router.replace({ name });
      }
    },
  },
};
