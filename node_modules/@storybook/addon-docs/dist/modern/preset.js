import path from 'path';
import remarkSlug from 'remark-slug';
import remarkExternalLinks from 'remark-external-links';
import global from 'global';
import { logger } from '@storybook/node-logger'; // for frameworks that are not working with react, we need to configure
// the jsx to transpile mdx, for now there will be a flag for that
// for more complex solutions we can find alone that we need to add '@babel/plugin-transform-react-jsx'

function createBabelOptions({
  babelOptions,
  mdxBabelOptions,
  configureJSX
}) {
  const babelPlugins = (mdxBabelOptions === null || mdxBabelOptions === void 0 ? void 0 : mdxBabelOptions.plugins) || (babelOptions === null || babelOptions === void 0 ? void 0 : babelOptions.plugins) || [];
  const jsxPlugin = [require.resolve('@babel/plugin-transform-react-jsx'), {
    pragma: 'React.createElement',
    pragmaFrag: 'React.Fragment'
  }];
  const plugins = configureJSX ? [...babelPlugins, jsxPlugin] : babelPlugins;
  return Object.assign({
    // don't use the root babelrc by default (users can override this in mdxBabelOptions)
    babelrc: false,
    configFile: false
  }, babelOptions, mdxBabelOptions, {
    plugins
  });
}

export async function webpack(webpackConfig = {}, options) {
  var _global$FEATURES, _global$FEATURES2;

  const resolvedBabelLoader = require.resolve('babel-loader');

  const {
    module = {}
  } = webpackConfig; // it will reuse babel options that are already in use in storybook
  // also, these babel options are chained with other presets.

  const {
    babelOptions,
    mdxBabelOptions,
    configureJSX = true,
    sourceLoaderOptions = {
      injectStoryParameters: true
    },
    transcludeMarkdown = false
  } = options;
  const mdxLoaderOptions = {
    skipCsf: true,
    remarkPlugins: [remarkSlug, remarkExternalLinks]
  };
  const mdxVersion = (_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.previewMdx2 ? 'MDX2' : 'MDX1';
  logger.info(`Addon-docs: using ${mdxVersion}`);
  const mdxLoader = (_global$FEATURES2 = global.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.previewMdx2 ? require.resolve('@storybook/mdx2-csf/loader') : require.resolve('@storybook/mdx1-csf/loader'); // set `sourceLoaderOptions` to `null` to disable for manual configuration

  const sourceLoader = sourceLoaderOptions ? [{
    test: /\.(stories|story)\.[tj]sx?$/,
    loader: require.resolve('@storybook/source-loader'),
    options: Object.assign({}, sourceLoaderOptions, {
      inspectLocalDependencies: true
    }),
    enforce: 'pre'
  }] : [];
  let rules = module.rules || [];

  if (transcludeMarkdown) {
    rules = [...rules.filter(rule => {
      var _rule$test;

      return ((_rule$test = rule.test) === null || _rule$test === void 0 ? void 0 : _rule$test.toString()) !== '/\\.md$/';
    }), {
      test: /\.md$/,
      use: [{
        loader: resolvedBabelLoader,
        options: createBabelOptions({
          babelOptions,
          mdxBabelOptions,
          configureJSX
        })
      }, {
        loader: mdxLoader,
        options: mdxLoaderOptions
      }]
    }];
  }

  const result = Object.assign({}, webpackConfig, {
    module: Object.assign({}, module, {
      rules: [...rules, {
        test: /\.js$/,
        include: new RegExp(`node_modules\\${path.sep}acorn-jsx`),
        use: [{
          loader: resolvedBabelLoader,
          options: {
            presets: [[require.resolve('@babel/preset-env'), {
              modules: 'commonjs'
            }]]
          }
        }]
      }, {
        test: /(stories|story)\.mdx$/,
        use: [{
          loader: resolvedBabelLoader,
          options: createBabelOptions({
            babelOptions,
            mdxBabelOptions,
            configureJSX
          })
        }, {
          loader: mdxLoader
        }]
      }, {
        test: /\.mdx$/,
        exclude: /(stories|story)\.mdx$/,
        use: [{
          loader: resolvedBabelLoader,
          options: createBabelOptions({
            babelOptions,
            mdxBabelOptions,
            configureJSX
          })
        }, {
          loader: mdxLoader,
          options: mdxLoaderOptions
        }]
      }, ...sourceLoader]
    })
  });
  return result;
}