export default {
  methods: {
    replaceRoute(routeName) {
      return this.$router.replace({ name: routeName });
    },
  },
};
