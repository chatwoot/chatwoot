import "core-js/modules/es.promise.js";
import "core-js/modules/es.array.sort.js";
import semver from '@storybook/semver';

// We only expect to have release notes available for major and minor releases.
// For this reason, we convert the actual version of the build here so that
// every place that relies on this data can reference the version of the
// release notes that we expect to use.
var getReleaseNotesVersion = function (version) {
  var _semver$parse = semver.parse(version),
      major = _semver$parse.major,
      minor = _semver$parse.minor;

  var _semver$coerce = semver.coerce(`${major}.${minor}`),
      releaseNotesVersion = _semver$coerce.version;

  return releaseNotesVersion;
};

export var getReleaseNotesFailedState = function (version) {
  return {
    success: false,
    currentVersion: getReleaseNotesVersion(version),
    showOnFirstLaunch: false
  };
};
export var RELEASE_NOTES_CACHE_KEY = 'releaseNotesData';
export var getReleaseNotesData = async function (currentVersionToParse, fileSystemCache) {
  var result;

  try {
    var fromCache = (await fileSystemCache.get('releaseNotesData', []).catch(function () {})) || [];
    var releaseNotesVersion = getReleaseNotesVersion(currentVersionToParse);
    var versionHasNotBeenSeen = !fromCache.includes(releaseNotesVersion);

    if (versionHasNotBeenSeen) {
      await fileSystemCache.set('releaseNotesData', [...fromCache, releaseNotesVersion]);
    }

    var sortedHistory = semver.sort(fromCache);
    var highestVersionSeenInThePast = sortedHistory.slice(-1)[0];
    var isUpgrading = false;
    var isMajorOrMinorDiff = false;

    if (highestVersionSeenInThePast) {
      isUpgrading = semver.gt(releaseNotesVersion, highestVersionSeenInThePast);
      var versionDiff = semver.diff(releaseNotesVersion, highestVersionSeenInThePast);
      isMajorOrMinorDiff = versionDiff === 'major' || versionDiff === 'minor';
    }

    result = {
      success: true,
      showOnFirstLaunch: versionHasNotBeenSeen && // Only show the release notes if this is not the first time Storybook
      // has been built.
      !!highestVersionSeenInThePast && isUpgrading && isMajorOrMinorDiff,
      currentVersion: releaseNotesVersion
    };
  } catch (e) {
    result = getReleaseNotesFailedState(currentVersionToParse);
  }

  return result;
};