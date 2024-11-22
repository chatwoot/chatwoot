export const useInstallationName = (str, installationName) => {
  if (str && installationName) {
    return str.replace(/xping/g, installationName);
  }
  return str;
};

export default {
  methods: {
    useInstallationName,
  },
};
