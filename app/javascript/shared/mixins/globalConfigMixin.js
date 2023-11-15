export default {
  methods: {
    // eslint-disable-next-line default-param-last
    useInstallationName(str = '', installationName) {
      return str.replace(/Chatwoot/g, installationName);
    },
  },
};
