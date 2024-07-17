export default {
  methods: {
    getRegexp(regexPatternValue) {
      let lastSlash = regexPatternValue.lastIndexOf('/');
      return new RegExp(
        regexPatternValue.slice(1, lastSlash),
        regexPatternValue.slice(lastSlash + 1)
      );
    },
  },
};
