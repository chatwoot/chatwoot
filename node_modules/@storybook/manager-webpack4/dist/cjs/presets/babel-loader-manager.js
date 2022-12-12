"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.babelLoader = void 0;

require("core-js/modules/es.array.concat.js");

var _coreCommon = require("@storybook/core-common");

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var babelLoader = function babelLoader() {
  var _getStorybookBabelCon = (0, _coreCommon.getStorybookBabelConfig)(),
      plugins = _getStorybookBabelCon.plugins,
      presets = _getStorybookBabelCon.presets;

  return {
    test: /\.(mjs|tsx?|jsx?)$/,
    use: [{
      loader: require.resolve('babel-loader'),
      options: {
        sourceType: 'unambiguous',
        presets: [].concat(_toConsumableArray(presets), [require.resolve('@babel/preset-react')]),
        plugins: [].concat(_toConsumableArray(plugins), [// Should only be done on manager. Template literals are not meant to be
        // transformed for frameworks like ember
        require.resolve('@babel/plugin-transform-template-literals')]),
        babelrc: false,
        configFile: false
      }
    }],
    include: [(0, _coreCommon.getProjectRoot)()],
    exclude: [/node_modules/, /dist/]
  };
};

exports.babelLoader = babelLoader;