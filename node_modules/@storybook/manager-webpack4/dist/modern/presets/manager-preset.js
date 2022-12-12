import path from 'path';
import fse from 'fs-extra';
import { DefinePlugin } from 'webpack';
import HtmlWebpackPlugin from 'html-webpack-plugin';
import CaseSensitivePathsPlugin from 'case-sensitive-paths-webpack-plugin';
import PnpWebpackPlugin from 'pnp-webpack-plugin';
import VirtualModulePlugin from 'webpack-virtual-modules';
import TerserWebpackPlugin from 'terser-webpack-plugin';
import uiPaths from '@storybook/ui/paths';
import readPackage from 'read-pkg-up';
import { loadManagerOrAddonsFile, resolvePathInStorybookCache, stringifyProcessEnvs, es6Transpiler, getManagerHeadTemplate, getManagerMainTemplate } from '@storybook/core-common';
import { babelLoader } from './babel-loader-manager';
export async function managerWebpack(_, {
  configDir,
  configType,
  docsMode,
  entries,
  refs,
  outputDir,
  previewUrl,
  versionCheck,
  releaseNotesData,
  presets,
  modern,
  features,
  serverChannelUrl
}) {
  const envs = await presets.apply('env');
  const logLevel = await presets.apply('logLevel', undefined);
  const template = await presets.apply('managerMainTemplate', getManagerMainTemplate());
  const headHtmlSnippet = await presets.apply('managerHead', getManagerHeadTemplate(configDir, process.env));
  const isProd = configType === 'PRODUCTION';
  const refsTemplate = fse.readFileSync(path.join(__dirname, '..', 'virtualModuleRef.template.js'), {
    encoding: 'utf8'
  });
  const {
    packageJson: {
      version
    }
  } = await readPackage({
    cwd: __dirname
  }); // @ts-ignore
  // const { BundleAnalyzerPlugin } = await import('webpack-bundle-analyzer').catch(() => ({}));

  return {
    name: 'manager',
    mode: isProd ? 'production' : 'development',
    bail: isProd,
    devtool: false,
    entry: entries,
    output: {
      path: outputDir,
      filename: isProd ? '[name].[contenthash].manager.bundle.js' : '[name].manager.bundle.js',
      publicPath: ''
    },
    watchOptions: {
      ignored: /node_modules/
    },
    plugins: [refs ? new VirtualModulePlugin({
      [path.resolve(path.join(configDir, `generated-refs.js`))]: refsTemplate.replace(`'{{refs}}'`, JSON.stringify(refs))
    }) : null, new HtmlWebpackPlugin({
      filename: `index.html`,
      // FIXME: `none` isn't a known option
      chunksSortMode: 'none',
      alwaysWriteToDisk: true,
      inject: false,
      template,
      templateParameters: {
        version,
        globals: {
          CONFIG_TYPE: configType,
          LOGLEVEL: logLevel,
          FEATURES: features,
          VERSIONCHECK: JSON.stringify(versionCheck),
          RELEASE_NOTES_DATA: JSON.stringify(releaseNotesData),
          DOCS_MODE: docsMode,
          // global docs mode
          PREVIEW_URL: previewUrl,
          // global preview URL
          SERVER_CHANNEL_URL: serverChannelUrl
        },
        headHtmlSnippet
      }
    }), new CaseSensitivePathsPlugin(), // graphql sources check process variable
    new DefinePlugin(Object.assign({}, stringifyProcessEnvs(envs), {
      NODE_ENV: JSON.stringify(envs.NODE_ENV)
    })) // isProd &&
    //   BundleAnalyzerPlugin &&
    //   new BundleAnalyzerPlugin({ analyzerMode: 'static', openAnalyzer: false }),
    ].filter(Boolean),
    module: {
      rules: [babelLoader(), es6Transpiler(), {
        test: /\.css$/,
        use: [require.resolve('style-loader'), {
          loader: require.resolve('css-loader'),
          options: {
            importLoaders: 1
          }
        }]
      }, {
        test: /\.(svg|ico|jpg|jpeg|png|apng|gif|eot|otf|webp|ttf|woff|woff2|cur|ani|pdf)(\?.*)?$/,
        loader: require.resolve('file-loader'),
        options: {
          name: isProd ? 'static/media/[name].[contenthash:8].[ext]' : 'static/media/[path][name].[ext]'
        }
      }, {
        test: /\.(mp4|webm|wav|mp3|m4a|aac|oga)(\?.*)?$/,
        loader: require.resolve('url-loader'),
        options: {
          limit: 10000,
          name: isProd ? 'static/media/[name].[contenthash:8].[ext]' : 'static/media/[path][name].[ext]'
        }
      }]
    },
    resolve: {
      extensions: ['.mjs', '.js', '.jsx', '.json', '.cjs', '.ts', '.tsx'],
      modules: ['node_modules'].concat(envs.NODE_PATH || []),
      mainFields: [modern ? 'sbmodern' : null, 'browser', 'module', 'main'].filter(Boolean),
      alias: Object.assign({}, uiPaths),
      plugins: [// Transparently resolve packages via PnP when needed; noop otherwise
      PnpWebpackPlugin]
    },
    resolveLoader: {
      plugins: [PnpWebpackPlugin.moduleLoader(module)]
    },
    recordsPath: resolvePathInStorybookCache('public/records.json'),
    performance: {
      hints: false
    },
    optimization: {
      splitChunks: {
        chunks: 'all'
      },
      runtimeChunk: true,
      sideEffects: true,
      usedExports: true,
      concatenateModules: true,
      minimizer: isProd ? [new TerserWebpackPlugin({
        parallel: true,
        terserOptions: {
          mangle: false,
          sourceMap: true,
          keep_fnames: true
        }
      })] : []
    }
  };
}
export async function managerEntries(installedAddons, options) {
  const {
    managerEntry = '@storybook/core-client/dist/esm/manager'
  } = options;
  const entries = options.modern ? [] : [require.resolve('@storybook/core-client/dist/esm/globals/polyfills')];

  if (installedAddons && installedAddons.length) {
    entries.push(...installedAddons);
  }

  const managerConfig = loadManagerOrAddonsFile(options);

  if (managerConfig) {
    entries.push(managerConfig);
  }

  entries.push(require.resolve(managerEntry));
  return entries;
}