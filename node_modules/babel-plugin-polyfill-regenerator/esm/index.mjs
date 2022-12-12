import defineProvider from '@babel/helper-define-polyfill-provider';

const runtimeCompat = "#__secret_key__@babel/runtime__compatibility";
var index = defineProvider(({
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

const isRegenerator = meta => meta.kind === "global" && meta.name === "regeneratorRuntime";

export default index;
//# sourceMappingURL=index.mjs.map
