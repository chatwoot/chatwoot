import { getProjectRoot, getStorybookBabelConfig } from '@storybook/core-common';
export const babelLoader = () => {
  const {
    plugins,
    presets
  } = getStorybookBabelConfig();
  return {
    test: /\.(mjs|tsx?|jsx?)$/,
    use: [{
      loader: require.resolve('babel-loader'),
      options: {
        sourceType: 'unambiguous',
        presets: [...presets, require.resolve('@babel/preset-react')],
        plugins: [...plugins, // Should only be done on manager. Template literals are not meant to be
        // transformed for frameworks like ember
        require.resolve('@babel/plugin-transform-template-literals')],
        babelrc: false,
        configFile: false
      }
    }],
    include: [getProjectRoot()],
    exclude: [/node_modules/, /dist/]
  };
};