"use strict";

exports.__esModule = true;
exports.default = void 0;

var _helperDefinePolyfillProvider = _interopRequireDefault(require("@babel/helper-define-polyfill-provider"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const runtimeCompat = "#__secret_key__@babel/runtime__compatibility";

var _default = (0, _helperDefinePolyfillProvider.default)(({
  debug
}, options) => {
  const {
    [runtimeCompat]: {
      useBabelRuntime
    } = {}
  } = options;
  const pureName = useBabelRuntime ? `${useBabelRuntime}/regenerator` : "regenerator-runtime";
  return {
    name: "regenerator",
    polyfills: ["regenerator-runtime"],

    usageGlobal(meta, utils) {
      if (isRegenerator(meta)) {
        debug("regenerator-runtime");
        utils.injectGlobalImport("regenerator-runtime/runtime.js");
      }
    },

    usagePure(meta, utils, path) {
      if (isRegenerator(meta)) {
        path.replaceWith(utils.injectDefaultImport(pureName, "regenerator-runtime"));
      }
    }

  };
});

exports.default = _default;

const isRegenerator = meta => meta.kind === "global" && meta.name === "regeneratorRuntime";