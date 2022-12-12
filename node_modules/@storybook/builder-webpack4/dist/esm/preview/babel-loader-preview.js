import { getProjectRoot } from '@storybook/core-common';
import { useBaseTsSupport } from './useBaseTsSupport';
export var createBabelLoader = function (options, framework) {
  return {
    test: useBaseTsSupport(framework) ? /\.(mjs|tsx?|jsx?)$/ : /\.(mjs|jsx?)$/,
    use: [{
      loader: require.resolve('babel-loader'),
      options: options
    }],
    include: [getProjectRoot()],
    exclude: /node_modules/
  };
};