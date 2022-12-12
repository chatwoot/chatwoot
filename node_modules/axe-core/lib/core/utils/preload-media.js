import querySelectorAllFilter from './query-selector-all-filter';

/**
 * Given a rootNode
 * -> get all HTMLMediaElement's and ensure their metadata is loaded
 *
 * @method preloadMedia
 * @memberof axe.utils
 * @property {Object} options.treeRoot (optional) the DOM tree to be inspected
 */
// TODO: es-modules_tree
function preloadMedia({ treeRoot = axe._tree[0] }) {
  const mediaVirtualNodes = querySelectorAllFilter(
    treeRoot,
    'video, audio',
    ({ actualNode }) => {
      /**
       * this is to safe-gaurd against empty `src` values which can get resolved `window.location`, thus never preloading as the URL is not a media asset
       */
      if (actualNode.hasAttribute('src')) {
        return !!actualNode.getAttribute('src');
      }

      /**
       * The `src` on <source> element is essential for `audio` and `video` elements
       */
      const sourceWithSrc = Array.from(
        actualNode.getElementsByTagName('source')
      ).filter(source => !!source.getAttribute('src'));
      if (sourceWithSrc.length <= 0) {
        return false;
      }

      return true;
    }
  );

  return Promise.all(
    mediaVirtualNodes.map(({ actualNode }) => isMediaElementReady(actualNode))
  );
}

export default preloadMedia;

/**
 * Ensures a media element's metadata is loaded
 * @param {HTMLMediaElement} elm elm
 * @returns {Promise}
 */
function isMediaElementReady(elm) {
  return new Promise(resolve => {
    /**
     * See - https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState
     */
    if (elm.readyState > 0) {
      resolve(elm);
    }

    function onMediaReady() {
      elm.removeEventListener('loadedmetadata', onMediaReady);
      resolve(elm);
    }

    /**
     * Given media is not ready, wire up listener for `loadedmetadata`
     * See - https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadedmetadata_event
     */
    elm.addEventListener('loadedmetadata', onMediaReady);
  });
}
