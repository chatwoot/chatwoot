'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var helperPluginUtils = require('@babel/helper-plugin-utils');
var transformTypeScript = require('@babel/plugin-transform-typescript');
var helperValidatorOption = require('@babel/helper-validator-option');

function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

var transformTypeScript__default = /*#__PURE__*/_interopDefaultLegacy(transformTypeScript);

const v = new helperValidatorOption.OptionValidator("@babel/preset-typescript");
function normalizeOptions(options = {}) {
  let {
    allowNamespaces = true,
    jsxPragma,
    onlyRemoveTypeImports
  } = options;
  const jsxPragmaFrag = v.validateStringOption("jsxPragmaFrag", options.jsxPragmaFrag, "React.Fragment");
  const allExtensions = v.validateBooleanOption("allExtensions", options.allExtensions, false);
  const isTSX = v.validateBooleanOption("isTSX", options.isTSX, false);

  if (isTSX) {
    v.invariant(allExtensions, "isTSX:true requires allExtensions:true");
  }

  return {
    allExtensions,
    allowNamespaces,
    isTSX,
    jsxPragma,
    jsxPragmaFrag,
    onlyRemoveTypeImports
  };
}

var index = helperPluginUtils.declare((api, opts) => {
  api.assertVersion(7);
  const {
    allExtensions,
    allowNamespaces,
    isTSX,
    jsxPragma,
    jsxPragmaFrag,
    onlyRemoveTypeImports
  } = normalizeOptions(opts);

  const pluginOptions = isTSX => ({
    allowDeclareFields: opts.allowDeclareFields,
    allowNamespaces,
    isTSX,
    jsxPragma,
    jsxPragmaFrag,
    onlyRemoveTypeImports
  });

  return {
    overrides: allExtensions ? [{
      plugins: [[transformTypeScript__default['default'], pluginOptions(isTSX)]]
    }] : [{
      test: /\.ts$/,
      plugins: [[transformTypeScript__default['default'], pluginOptions(false)]]
    }, {
      test: /\.tsx$/,
      plugins: [[transformTypeScript__default['default'], pluginOptions(true)]]
    }]
  };
});

exports.default = index;
//# sourceMappingURL=index.js.map
