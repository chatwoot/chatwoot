export default {
  methods: {
    useInstallationName(str = '', installationName) {
      return str.replace(/Chatwoot/g, installationName);
    },
  },
};
