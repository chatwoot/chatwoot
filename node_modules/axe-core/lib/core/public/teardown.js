import cache from '../base/cache';

/**
 * Clean up axe-core tree and caches. `axe.run` will call this function at the end of the run so there's no need to call it yourself afterwards.
 */
function teardown() {
  if (cache.get('globalDocumentSet')) {
    document = null;
  }
  if (cache.get('globalWindowSet')) {
    window = null;
  }

  axe._memoizedFns.forEach(fn => fn.clear());
  cache.clear();
  axe._tree = undefined;
  axe._selectorData = undefined;
  axe._selectCache = undefined;
}

export default teardown;
