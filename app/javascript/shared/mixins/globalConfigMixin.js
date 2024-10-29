export const useInstallationName = (str, installationName) => {
  if (str && installationName) {
    return str.replace(/Chatwoot/g, installationName);
  }
  return str;
};

export default {
  methods: {
    useInstallationName,
  },
};
