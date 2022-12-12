import { logger } from '@storybook/client-logger';

/**
 * Executes a Loadable (function that returns exports or require context(s))
 * and returns a map of filename => module exports
 *
 * @param loadable Loadable
 * @returns Map<Path, ModuleExports>
 */
export function executeLoadable(loadable) {
  let reqs = null; // todo discuss / improve type check

  if (Array.isArray(loadable)) {
    reqs = loadable;
  } else if (loadable.keys) {
    reqs = [loadable];
  }

  let exportsMap = new Map();

  if (reqs) {
    reqs.forEach(req => {
      req.keys().forEach(filename => {
        try {
          const fileExports = req(filename);
          exportsMap.set(typeof req.resolve === 'function' ? req.resolve(filename) : filename, fileExports);
        } catch (error) {
          const errorString = error.message && error.stack ? `${error.message}\n ${error.stack}` : error.toString();
          logger.error(`Unexpected error while loading ${filename}: ${errorString}`);
        }
      });
    });
  } else {
    const exported = loadable();

    if (Array.isArray(exported) && exported.every(obj => obj.default != null)) {
      exportsMap = new Map(exported.map((fileExports, index) => [`exports-map-${index}`, fileExports]));
    } else if (exported) {
      logger.warn(`Loader function passed to 'configure' should return void or an array of module exports that all contain a 'default' export. Received: ${JSON.stringify(exported)}`);
    }
  }

  return exportsMap;
}
/**
 * Executes a Loadable (function that returns exports or require context(s))
 * and compares it's output to the last time it was run (as stored on a node module)
 *
 * @param loadable Loadable
 * @param m NodeModule
 * @returns { added: Map<Path, ModuleExports>, removed: Map<Path, ModuleExports> }
 */

export function executeLoadableForChanges(loadable, m) {
  var _m$hot, _m$hot$data, _m$hot2;

  let lastExportsMap = (m === null || m === void 0 ? void 0 : (_m$hot = m.hot) === null || _m$hot === void 0 ? void 0 : (_m$hot$data = _m$hot.data) === null || _m$hot$data === void 0 ? void 0 : _m$hot$data.lastExportsMap) || new Map();

  if (m !== null && m !== void 0 && (_m$hot2 = m.hot) !== null && _m$hot2 !== void 0 && _m$hot2.dispose) {
    m.hot.accept();
    m.hot.dispose(data => {
      // eslint-disable-next-line no-param-reassign
      data.lastExportsMap = lastExportsMap;
    });
  }

  const exportsMap = executeLoadable(loadable);
  const added = new Map();
  Array.from(exportsMap.entries()) // Ignore files that do not have a default export
  .filter(([, fileExports]) => !!fileExports.default) // Ignore exports that are equal (by reference) to last time, this means the file hasn't changed
  .filter(([fileName, fileExports]) => lastExportsMap.get(fileName) !== fileExports).forEach(([fileName, fileExports]) => added.set(fileName, fileExports));
  const removed = new Map();
  Array.from(lastExportsMap.keys()).filter(fileName => !exportsMap.has(fileName)).forEach(fileName => removed.set(fileName, lastExportsMap.get(fileName))); // Save the value for the dispose() call above

  lastExportsMap = exportsMap;
  return {
    added,
    removed
  };
}