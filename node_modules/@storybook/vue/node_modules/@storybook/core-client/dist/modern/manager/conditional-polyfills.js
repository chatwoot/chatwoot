import global from 'global';
const {
  window: globalWindow
} = global;
export const importPolyfills = () => {
  const polyfills = [];

  if (!globalWindow.fetch) {
    // manually patch window.fetch;
    //    see issue: <https://github.com/developit/unfetch/issues/101#issuecomment-454451035>
    const patch = ({
      default: fetch
    }) => {
      globalWindow.fetch = fetch;
    };

    polyfills.push(import('unfetch/dist/unfetch').then(patch));
  }

  return Promise.all(polyfills);
};