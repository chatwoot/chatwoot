function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.map.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";
import { logger } from '@storybook/client-logger';

/**
 * Executes a Loadable (function that returns exports or require context(s))
 * and returns a map of filename => module exports
 *
 * @param loadable Loadable
 * @returns Map<Path, ModuleExports>
 */
export function executeLoadable(loadable) {
  var reqs = null; // todo discuss / improve type check

  if (Array.isArray(loadable)) {
    reqs = loadable;
  } else if (loadable.keys) {
    reqs = [loadable];
  }

  var exportsMap = new Map();

  if (reqs) {
    reqs.forEach(function (req) {
      req.keys().forEach(function (filename) {
        try {
          var fileExports = req(filename);
          exportsMap.set(typeof req.resolve === 'function' ? req.resolve(filename) : filename, fileExports);
        } catch (error) {
          var errorString = error.message && error.stack ? "".concat(error.message, "\n ").concat(error.stack) : error.toString();
          logger.error("Unexpected error while loading ".concat(filename, ": ").concat(errorString));
        }
      });
    });
  } else {
    var exported = loadable();

    if (Array.isArray(exported) && exported.every(function (obj) {
      return obj.default != null;
    })) {
      exportsMap = new Map(exported.map(function (fileExports, index) {
        return ["exports-map-".concat(index), fileExports];
      }));
    } else if (exported) {
      logger.warn("Loader function passed to 'configure' should return void or an array of module exports that all contain a 'default' export. Received: ".concat(JSON.stringify(exported)));
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

  var lastExportsMap = (m === null || m === void 0 ? void 0 : (_m$hot = m.hot) === null || _m$hot === void 0 ? void 0 : (_m$hot$data = _m$hot.data) === null || _m$hot$data === void 0 ? void 0 : _m$hot$data.lastExportsMap) || new Map();

  if (m !== null && m !== void 0 && (_m$hot2 = m.hot) !== null && _m$hot2 !== void 0 && _m$hot2.dispose) {
    m.hot.accept();
    m.hot.dispose(function (data) {
      // eslint-disable-next-line no-param-reassign
      data.lastExportsMap = lastExportsMap;
    });
  }

  var exportsMap = executeLoadable(loadable);
  var added = new Map();
  Array.from(exportsMap.entries()) // Ignore files that do not have a default export
  .filter(function (_ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        fileExports = _ref2[1];

    return !!fileExports.default;
  }) // Ignore exports that are equal (by reference) to last time, this means the file hasn't changed
  .filter(function (_ref3) {
    var _ref4 = _slicedToArray(_ref3, 2),
        fileName = _ref4[0],
        fileExports = _ref4[1];

    return lastExportsMap.get(fileName) !== fileExports;
  }).forEach(function (_ref5) {
    var _ref6 = _slicedToArray(_ref5, 2),
        fileName = _ref6[0],
        fileExports = _ref6[1];

    return added.set(fileName, fileExports);
  });
  var removed = new Map();
  Array.from(lastExportsMap.keys()).filter(function (fileName) {
    return !exportsMap.has(fileName);
  }).forEach(function (fileName) {
    return removed.set(fileName, lastExportsMap.get(fileName));
  }); // Save the value for the dispose() call above

  lastExportsMap = exportsMap;
  return {
    added: added,
    removed: removed
  };
}