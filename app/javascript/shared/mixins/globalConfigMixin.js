export default {
  methods: {
    useInstallationName(str = '', installationName) {
      return str.replace(/ABrand/g, globalConfig.installationName);
    },
  },
};
