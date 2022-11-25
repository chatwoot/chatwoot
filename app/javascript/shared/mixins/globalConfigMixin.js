export default {
  methods: {
    useInstallationName(str = '', installationName) {
      return str.replace(/Chatquick/g, installationName);
    },
  },
};
