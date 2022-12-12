"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  compile: true,
  compileSync: true
};
exports.compileSync = exports.compile = void 0;

var _mdx = _interopRequireDefault(require("@mdx-js/mdx"));

var _sbMdxPlugin = require("./sb-mdx-plugin");

Object.keys(_sbMdxPlugin).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _sbMdxPlugin[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _sbMdxPlugin[key];
    }
  });
});

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const compile = async (code, options) => (0, _mdx.default)(code, {
  compilers: [(0, _sbMdxPlugin.createCompiler)(options)]
});

exports.compile = compile;

const compileSync = (code, options) => _mdx.default.sync(code, {
  compilers: [(0, _sbMdxPlugin.createCompiler)(options)]
});

exports.compileSync = compileSync;