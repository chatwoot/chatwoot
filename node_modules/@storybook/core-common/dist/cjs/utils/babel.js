"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getStorybookBabelDependencies = exports.getStorybookBabelConfig = void 0;

var r = function (s, local) {
  return local ? s : require.resolve(s);
};

var getStorybookBabelConfig = function ({
  local = false
} = {}) {
  return {
    sourceType: 'unambiguous',
    presets: [[r('@babel/preset-env', local), {
      shippedProposals: true,
      loose: true
    }], r('@babel/preset-typescript', local)],
    plugins: [r('@babel/plugin-transform-shorthand-properties', local), r('@babel/plugin-transform-block-scoping', local),
    /*
     * Added for TypeScript experimental decorator support
     * https://babeljs.io/docs/en/babel-plugin-transform-typescript#typescript-compiler-options
     */
    [r('@babel/plugin-proposal-decorators', local), {
      legacy: true
    }], [r('@babel/plugin-proposal-class-properties', local), {
      loose: true
    }], [r('@babel/plugin-proposal-private-property-in-object', local), {
      loose: true
    }], [r('@babel/plugin-proposal-private-methods', local), {
      loose: true
    }], r('@babel/plugin-proposal-export-default-from', local), r('@babel/plugin-syntax-dynamic-import', local), [r('@babel/plugin-proposal-object-rest-spread', local), {
      loose: true,
      useBuiltIns: true
    }], r('@babel/plugin-transform-classes', local), r('@babel/plugin-transform-arrow-functions', local), r('@babel/plugin-transform-parameters', local), r('@babel/plugin-transform-destructuring', local), r('@babel/plugin-transform-spread', local), r('@babel/plugin-transform-for-of', local), r('babel-plugin-macros', local),
    /*
     * Optional chaining and nullish coalescing are supported in
     * @babel/preset-env, but not yet supported in Webpack due to support
     * missing from acorn. These can be removed once Webpack has support.
     * See https://github.com/facebook/create-react-app/issues/8445#issuecomment-588512250
     */
    r('@babel/plugin-proposal-optional-chaining', local), r('@babel/plugin-proposal-nullish-coalescing-operator', local), [r('babel-plugin-polyfill-corejs3', local), {
      method: 'usage-global',
      absoluteImports: r('core-js', local),
      // eslint-disable-next-line global-require
      version: require('core-js/package.json').version
    }]]
  };
};

exports.getStorybookBabelConfig = getStorybookBabelConfig;

var getStorybookBabelDependencies = function () {
  return ['@babel/preset-env', '@babel/preset-typescript', '@babel/plugin-transform-shorthand-properties', '@babel/plugin-proposal-private-property-in-object', '@babel/plugin-transform-block-scoping', '@babel/plugin-proposal-decorators', '@babel/plugin-proposal-class-properties', '@babel/plugin-proposal-private-methods', '@babel/plugin-proposal-export-default-from', '@babel/plugin-syntax-dynamic-import', '@babel/plugin-proposal-object-rest-spread', '@babel/plugin-transform-classes', '@babel/plugin-transform-arrow-functions', '@babel/plugin-transform-parameters', '@babel/plugin-transform-destructuring', '@babel/plugin-transform-spread', '@babel/plugin-transform-for-of', 'babel-plugin-macros', '@babel/plugin-proposal-optional-chaining', '@babel/plugin-proposal-nullish-coalescing-operator', 'babel-plugin-polyfill-corejs3', 'babel-loader', 'core-js'];
};

exports.getStorybookBabelDependencies = getStorybookBabelDependencies;