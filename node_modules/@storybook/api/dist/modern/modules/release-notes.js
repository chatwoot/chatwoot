import global from 'global';
import memoize from 'memoizerific';
const {
  RELEASE_NOTES_DATA
} = global;
const getReleaseNotesData = memoize(1)(() => {
  try {
    return Object.assign({}, JSON.parse(RELEASE_NOTES_DATA) || {});
  } catch (e) {
    return {};
  }
});
export const init = ({
  store
}) => {
  const releaseNotesData = getReleaseNotesData();

  const getReleaseNotesViewed = () => {
    const {
      releaseNotesViewed: persistedReleaseNotesViewed
    } = store.getState();
    return persistedReleaseNotesViewed || [];
  };

  const api = {
    releaseNotesVersion: () => releaseNotesData.currentVersion,
    setDidViewReleaseNotes: () => {
      const releaseNotesViewed = getReleaseNotesViewed();

      if (!releaseNotesViewed.includes(releaseNotesData.currentVersion)) {
        store.setState({
          releaseNotesViewed: [...releaseNotesViewed, releaseNotesData.currentVersion]
        }, {
          persistence: 'permanent'
        });
      }
    },
    showReleaseNotesOnLaunch: () => {
      // The currentVersion will only exist for dev builds
      if (!releaseNotesData.currentVersion) return false;
      const releaseNotesViewed = getReleaseNotesViewed();
      const didViewReleaseNotes = releaseNotesViewed.includes(releaseNotesData.currentVersion);
      const showReleaseNotesOnLaunch = releaseNotesData.showOnFirstLaunch && !didViewReleaseNotes;
      return showReleaseNotesOnLaunch;
    }
  };

  const initModule = () => {};

  return {
    init: initModule,
    api
  };
};