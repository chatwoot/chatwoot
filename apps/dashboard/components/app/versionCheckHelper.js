const semver = require('semver');

export const hasAnUpdateAvailable = (latestVersion, currentVersion) => {
  if (!semver.valid(latestVersion)) {
    return false;
  }
  return semver.lt(currentVersion, latestVersion);
};
