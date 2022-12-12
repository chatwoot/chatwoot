**Please note that Webpacker 3.1.0 and 3.1.1 have some serious bugs so please consider using either 3.0.2 or 3.2.0**

**Please note that Webpacker 4.1.0 has an installer bug. Please use 4.2.0 or above**

## [[5.3.0]](https://github.com/rails/webpacker/compare/v5.3.0...5.2.1) - 2021-TBD

- Adds experimental Yarn 2 support. Note you must manually set `nodeLinker: node-modules` in your `.yarnrc.yml`.

- Keep backups, even when they're old [#2912](https://github.com/rails/webpacker/pull/2912)

## [[5.2.2]](https://github.com/rails/webpacker/compare/v5.2.1...5.2.2) - 2021-04-27

- Bump deps and remove node-sass [#2997](https://github.com/rails/webpacker/pull/2997).

## [[5.2.1]](https://github.com/rails/webpacker/compare/v5.2.0...5.2.1) - 2020-08-17

- Revert [#1311](https://github.com/rails/webpacker/pull/1311).

## [[5.2.0]](https://github.com/rails/webpacker/compare/v5.1.1...5.2.0) - 2020-08-16

- Bump dependencies and fixes. See [diff](https://github.com/rails/webpacker/compare/v5.1.1...5-x-stable) for changes.

## [[5.1.1]](https://github.com/rails/webpacker/compare/v5.1.0...v5.1.1) - 2020-04-20

- Update [TypeScript documentation](https://github.com/rails/webpacker/blob/master/docs/typescript.md) and installer to use babel-loader for typescript.[(#2541](https://github.com/rails/webpacker/pull/2541)

## [[5.1.0]](https://github.com/rails/webpacker/compare/v5.0.1...v5.1.0) - 2020-04-19

- Remove yarn integrity check [#2518](https://github.com/rails/webpacker/pull/2518)
- Switch from ts-loader to babel-loader [#2449](https://github.com/rails/webpacker/pull/2449)
  Please see the [TypeScript documentation](https://github.com/rails/webpacker/blob/master/docs/typescript.md) to upgrade existing projects to use typescript with 5.1
- Resolve multi-word snakecase WEBPACKER_DEV_SERVER env values [#2528](https://github.com/rails/webpacker/pull/2528)

## [[5.0.1]](https://github.com/rails/webpacker/compare/v5.0.0...v5.0.1) - 2020-03-22

- Upgrade deps and fix sass loader config options bug [#2508](https://github.com/rails/webpacker/pull/2508)

## [[5.0.0]](https://github.com/rails/webpacker/compare/v4.2.2...v5.0.0) - 2020-03-22

- Bump minimum node version [#2428](https://github.com/rails/webpacker/pull/2428)
- Bump minimum ruby/rails version [#2415](https://github.com/rails/webpacker/pull/2415)
- Add support for multiple files per entry [#2476](https://github.com/rails/webpacker/pull/2476)

```js
  entry: {
    home: ['./home.js', './home.scss'],
    account: ['./account.js', './account.scss']
  }
```

You can now have two entry files with same names inside packs folder, `home.scss` and `home.js`

And, other minor fixes, please see a list of changes [here](https://github.com/rails/webpacker/compare/v4.2.2...v5.0.0)

## [[4.2.2]](https://github.com/rails/webpacker/compare/v4.2.1...v4.2.2) - 2019-12-09

- Fixed issue with webpack clean task for nested assets [#2391](https://github.com/rails/webpacker/pull/2391)

## [[4.2.1]](https://github.com/rails/webpacker/compare/v4.2.0...v4.2.1) - 2019-12-09

- Fixed issue with webpack clean task [#2389](https://github.com/rails/webpacker/pull/2389)

## [[4.2.0]](https://github.com/rails/webpacker/compare/v4.1.0...v4.2.0) - 2019-11-12

- Fixed installer bug [#2366](https://github.com/rails/webpacker/pull/2366)

## [[4.1.0]](https://github.com/rails/webpacker/compare/v4.0.7...v4.1.0) - 2019-11-12

- Added favicon_pack_tag to generate favicon links [#2281](https://github.com/rails/webpacker/pull/2281)
- Add support for Brotli compression [#2273](https://github.com/rails/webpacker/pull/2273)
- Support .(sass|scss).erb [#2259](https://github.com/rails/webpacker/pull/2259)
- Elm: Enable production optimizations when compiling in production [#2234](https://github.com/rails/webpacker/pull/2234)
- fixes webpacker:clean erroring because of nested hashes [#2318](https://github.com/rails/webpacker/pull/2318)
- Revert of production env enforcement [#2341](https://github.com/rails/webpacker/pull/2341)
- Add a preload_pack_asset helper [#2124](https://github.com/rails/webpacker/pull/2124)
- Record the compilation digest even on webpack error [#2117](https://github.com/rails/webpacker/pull/2117)
- See more changes [here](https://github.com/rails/webpacker/compare/v4.0.7...v4.1.0)

## [[4.0.7]](https://github.com/rails/webpacker/compare/v4.0.6...v4.0.7) - 2019-06-03

- Prevent `@babel/plugin-transform-runtime` from rewriting babel helpers in core-js. Remove unneeded runtime `@babel/runtime-corejs3` [#2116](https://github.com/rails/webpacker/pull/2116)
  - Fix for: [#2109 Uncaught TypeError: **webpack_require**(...) is not a function](https://github.com/rails/webpacker/issues/2109): **If you are upgrading**, please check your `babel.config.js` against the [default `babel.config.js`](https://github.com/rails/webpacker/blob/master/lib/install/config/babel.config.js):
    - `@babel/preset-env` should contain `corejs: 3`
    - `@babel/plugin-transform-runtime` should contain `corejs: false`
- Removed unneeded runtime `@babel/runtime-corejs3`

## [[4.0.6]](https://github.com/rails/webpacker/compare/v4.0.5...v4.0.6) - 2019-05-30

- Webpack should not be transpiled [#2111](https://github.com/rails/webpacker/pull/2111)

## [[4.0.5]](https://github.com/rails/webpacker/compare/v4.0.4...v4.0.5) - 2019-05-30

- Don't let babel & core-js transpile each other [#2110](https://github.com/rails/webpacker/pull/2110)

## [[4.0.4]](https://github.com/rails/webpacker/compare/v4.0.3...v4.0.4) - 2019-05-28

- Remove bundler version constraint

## [[4.0.3]](https://github.com/rails/webpacker/compare/v4.0.2...v4.0.3) - 2019-05-28

Please see the diff

##### Breaking changes (for pre-existing apps)

- [`@babel/polyfill`](https://babeljs.io/docs/en/next/babel-polyfill.html) [doesn't make it possible to provide a smooth migration path from `core-js@2` to `core-js@3`](https://github.com/zloirock/core-js/blob/master/docs/2019-03-19-core-js-3-babel-and-a-look-into-the-future.md#babelpolyfill): for this reason, it was decided to deprecate `@babel/polyfill` in favor of separate inclusion of required parts of `core-js` and `regenerator-runtime`. [#2031](https://github.com/rails/webpacker/pull/2031)

In each of your `/packs/*.js` files, change this:

```js
import '@babel/polyfill'
```

to this:

```js
import 'core-js/stable'
import 'regenerator-runtime/runtime'
```

Don't forget to install those dependencies directly!

```sh
yarn add core-js regenerator-runtime
```

## [4.0.2] - 2019-03-06

- Bump the version on npm

## [4.0.1] - 2019-03-04

### Fixed

- Pre-release version installer

## [4.0.0] - 2019-03-04

No changes in this release. See RC releases for changes.

## [4.0.0.rc.8] - 2019-03-03

### Fixed

- Re-enable source maps in production to make debugging in production
  easier. Enabling source maps doesn't have drawbacks for most of the
  applications since maps are compressed by default and aren't loaded
  by browsers unless Dev Tools are opened.

Source maps can be disabled in any environment configuration, e.g:

```js
// config/webpack/production.js

const environment = require('./environment')
environment.config.merge({ devtool: 'none' })

module.exports = environment.toWebpackConfig()
```

- Reintroduced `context` to the file loader. Reverting the simpler paths change

- Updated file loader to have filename based on the path. This change
  keeps the old behaviour intact i.e. let people use namespaces for media
  inside `app/javascript` and also include media outside of `app/javascript`
  with simpler paths, for example from `node_modules` or `app/assets`

```bash
# Files inside app/javascript (i.e. packs source path)
# media/[full_path_relative_to_app_javascript]/name_of_the_asset_with_digest
media/images/google-97e897b3851e415bec4fd30c265eb3ce.jpg
media/images/rails-45b116b1f66cc5e6f9724e8f9a2db73d.png
media/images/some_namespace/google-97e897b3851e415bec4fd30c265eb3ce.jpg

# Files outside app/javascript (i.e. packs source path)
# media/[containing_folder_name]/name_of_the_asset_with_digest
media/some_assets/rails_assets-f0f7bbb5.png
media/webfonts/fa-brands-400-4b115e11.woff2
```

This change is done so we don't end up paths like `media/_/assets/images/rails_assets-f0f7bbb5ef00110a0dcef7c2cb7d34a6.png` or `media/_/_/node_modules/foo-f0f7bbb5ef00110a0dcef7c2cb7d34a6.png` for media outside of
`app/javascript`

## [4.0.0.rc.7] - 2019-01-25

### Fixed

- Webpacker builds test app assets [#1908](https://github.com/rails/webpacker/issues/1908)

## [4.0.0.rc.6] - 2019-01-25

### Fixed

- Remove `context` from file loader in favour of simpler paths

```rb
# before
"_/assets/images/avatar.png": "/packs/_/assets/images/avatar-057862c747f0fdbeae506bdd0516cad1.png"

# after
"media/avatar.png": "/packs/media/avatar-057862c747f0fdbeae506bdd0516cad1.png"
```

To get old behaviour:

```js
// config/webpack/environment.js

const { environment, config } = require('@rails/webpacker')
const { join } = require('path')

const fileLoader = environment.loaders.get('file')
fileLoader.use[0].options.name = '[path][name]-[hash].[ext]'
fileLoader.use[0].options.context = join(config.source_path) // optional if you don't want to expose full paths
```

### Added

- Namespaces for compiled packs in the public directory

```rb
# before
"runtime~hello_react" => "/packs/runtime~hello_react-da2baf7fd07b0e8b6d17.js"

# after
"runtime~hello_react" => "/packs/js/runtime~hello_react-da2baf7fd07b0e8b6d17.js"
```

## [4.0.0.rc.5] - 2019-01-21

### Updated

- Gems and node dependencies

## [4.0.0.rc.4] - 2019-01-21

### Added

- `stylesheet_packs_with_chunks_tag` helper, similar to javascript helper but for
  loading stylesheets chunks.

```erb
<%= stylesheet_packs_with_chunks_tag 'calendar', 'map', 'data-turbolinks-track': 'reload' %>

<link rel="stylesheet" media="screen" href="/packs/3-8c7ce31a.chunk.css" />
<link rel="stylesheet" media="screen" href="/packs/calendar-8c7ce31a.chunk.css" />
<link rel="stylesheet" media="screen" href="/packs/map-8c7ce31a.chunk.css" />
```

**Important:** Pass all your pack names when using `stylesheet_packs_with_chunks_tag`
helper otherwise you will get duplicated chunks on the page.

```erb
<%# DO %>
# <%= stylesheet_packs_with_chunks_tag 'calendar', 'map' %>
<%# DON'T %>
# <%= stylesheet_packs_with_chunks_tag 'calendar' %>
# <%= stylesheet_packs_with_chunks_tag 'map' %>
```

## [4.0.0.rc.3] - 2019-01-17

### Fixed

- Issue with javascript_pack_tag asset duplication [#1898](https://github.com/rails/webpacker/pull/1898)

### Added

- `javascript_packs_with_chunks_tag` helper, which creates html tags
  for a pack and all the dependent chunks, when using splitchunks.

```erb
<%= javascript_packs_with_chunks_tag 'calendar', 'map', 'data-turbolinks-track': 'reload' %>

<script src="/packs/vendor-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/calendar~runtime-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/calendar-1016838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/map~runtime-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/map-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
```

**Important:** Pass all your pack names when using `javascript_packs_with_chunks_tag`
helper otherwise you will get duplicated chunks on the page.

```erb
<%# DO %>
<%= javascript_packs_with_chunks_tag 'calendar', 'map' %>

<%# DON'T %>
<%= javascript_packs_with_chunks_tag 'calendar' %>
<%= javascript_packs_with_chunks_tag 'map' %>
```

## [4.0.0.rc.2] - 2018-12-15

### Fixed

- Disable integrity hash generation [#1835](https://github.com/rails/webpacker/issues/1835)

## [4.0.0.rc.1] - 2018-12-14

### Breaking changes

- Order of rules changed so you might have to change append to prepend,
  depending on how you want to process packs [#1823](https://github.com/rails/webpacker/pull/1823)

```js
environment.loaders.prepend()
```

- Separate CSS extraction from build environment [#1625](https://github.com/rails/webpacker/pull/1625)

```yml
# Extract and emit a css file
extract_css: true
```

- Separate rule to compile node modules
  (fixes cases where ES6 libraries were included in the app code) [#1823](https://github.com/rails/webpacker/pull/1823).

  In previous versions only application code was transpiled. Now everything in `node_modules` is transpiled with Babel. In some cases it could break your build (known issue with `mapbox-gl` package being broken by Babel, https://github.com/mapbox/mapbox-gl-js/issues/3422).

  [`nodeModules` loader](https://github.com/rails/webpacker/pull/1823/files#diff-456094c8451b5774db50028dfecf4aa8) ignores `config.babel.js` and uses hard-coded `'@babel/preset-env', { modules: false }` config.

  To keep previous behavior, remove `nodeModules` loader specifying `environment.loaders.delete('nodeModules');` in your `config/webpack/environment.js` file.

- File loader extensions API [#1823](https://github.com/rails/webpacker/pull/1823)

```yml
# webpacker.yml
static_assets_extensions:
  - .pdf
  # etc..
```

### Added

- Move `.babelrc` and `.postcssrc` to `.js` variant [#1822](https://github.com/rails/webpacker/pull/1822)
- Use postcss safe parser when optimising css assets [#1822](https://github.com/rails/webpacker/pull/1822)
- Add split chunks api (undocumented)

```js
const { environment } = require('@rails/webpacker')
// Enable with default config
environment.splitChunks()
// Configure via a callback
environment.splitChunks((config) =>
  Object.assign({}, config, { optimization: { splitChunks: false } })
)
```

- Allow changing static file extensions using webpacker.yml (undocumented)

## [4.0.0-pre.3] - 2018-10-01

### Added

- Move supported browsers configuration to [.browserslistrc](https://github.com/browserslist/browserslist#queries)

### Breaking changes

- postcss-next is replaced with postcss-preset-env
- babel@7

### Fixed

- Bring back test env [#1563](https://github.com/rails/webpacker/pull/1563)

Please see a list of [commits](https://github.com/rails/webpacker/compare/2dd68f0273074aadb3f869c4c30369d5e4e3fea7...master)

## [4.0.0-pre.2] - 2018-04-2

### Fixed

- Webpack dev server version in installer

## [4.0.0-pre.1] - 2018-04-2

Pre-release to try out webpack 4.0 support

### Added

- Webpack 4.0 support [#1376](https://github.com/rails/webpacker/pull/1316)

### Fixed

- Remove compilation digest file if webpack command fails[#1398](https://github.com/rails/webpacker/issues/1398)

## [3.6.0] - 2019-03-06

See changes: https://github.com/rails/webpacker/compare/88a253ed42966eb2d5c997435e9396881513bce1...3-x-stable

## [3.5.5] - 2018-07-09

See changes: https://github.com/rails/webpacker/compare/e8b197e36c77181ca2e4765c620faea59dcd0351...3-x-stable

### Added

- On CI, sort files & check modified w/ digest intead of mtime[#1522](https://github.com/rails/webpacker/pull/1522)

## [3.5.3] - 2018-05-03

### Fixed

- Relax Javascript package dependencies [#1466](https://github.com/rails/webpacker/pull/1466#issuecomment-386336605)

## [3.5.2] - 2018-04-29

- Pin Javascript package to 3.5.x

## [3.5.1] - 2018-04-29

- Upgraded gems and Javascript packages

## [3.5.0] - 2018-04-29

### Fixed

- Remove compilation digest file if webpack command fails [#1399](https://github.com/rails/webpacker/pull/1399)
- Handle http dev_server setting properly in the proxy [#1420](https://github.com/rails/webpacker/pull/1420)
- Use correct protocol [#1425](https://github.com/rails/webpacker/pull/1425)

### Added

- `image_pack_tag` helper [#1400](https://github.com/rails/webpacker/pull/1400)
- devserver proxy for custom environments [#1415](https://github.com/rails/webpacker/pull/1415)
- Rails webpacker:info task [#1416](https://github.com/rails/webpacker/pull/1416)
- Include `RAILS_RELATIVE_URL_ROOT` environment variable in publicPath [#1428](https://github.com/rails/webpacker/pull/1428)

Complete list of changes: [#1464](https://github.com/rails/webpacker/pull/1464)

## [3.4.3] - 2018-04-3

### Fixed

- Lock webpacker version in installer [#1401](https://github.com/rails/webpacker/issues/1401)

## [3.4.1] - 2018-03-24

### Fixed

- Yarn integrity check in development [#1374](https://github.com/rails/webpacker/issues/1374)

## [3.4.0] - 2018-03-23

**Please use 3.4.1 instead**

### Added

- Support for custom Rails environments [#1359](https://github.com/rails/webpacker/pull/1359)

_This could break the compilation if you set NODE_ENV to custom environment. Now, NODE_ENV only understands production or development mode_

## [3.3.1] - 2018-03-12

### Fixed

- Use webpack dev server 2.x until webpacker supports webpack 4.x [#1338](https://github.com/rails/webpacker/issues/1338)

## [3.3.0] - 2018-03-03

### Added

- Separate task for installing/updating binstubs
- CSS modules support [#1248](https://github.com/rails/webpacker/pull/1248)
- Pass `relative_url_root` to webpacker config [#1236](https://github.com/rails/webpacker/pull/1236)

### Breaking changes

- Fixes [#1281](https://github.com/rails/webpacker/issues/1281) by installing binstubs only as local executables. To upgrade:

```
bundle exec rails webpacker:binstubs
```

- set function is now removed from plugins and loaders, please use `append` or `prepend`

```js
// config/webpack/environment.js
const { environment } = require('@rails/webpacker')

environment.loaders.append('json', {
  test: /\.json$/,
  use: 'json-loader'
})
```

### Fixed

- Limit ts-loader to 3.5.0 until webpack 4 support [#1308](https://github.com/rails/webpacker/pull/1308)
- Custom env support [#1304](https://github.com/rails/webpacker/pull/1304)

## [3.2.2] - 2018-02-11

### Added

- Stimulus example [https://stimulusjs.org/](https://stimulusjs.org/)

```bash
bundle exec rails webpacker:install:stimulus
```

- Upgrade gems and npm packages [#1254](https://github.com/rails/webpacker/pull/1254)

And, bunch of bug fixes [See changes](https://github.com/rails/webpacker/compare/v3.2.1...v3.2.2)

## [3.2.1] - 2018-01-21

- Disable dev server running? check if no dev server config is present in that environment [#1179](https://github.com/rails/webpacker/pull/1179)

- Fix checking 'webpack' binstub on Windows [#1123](https://github.com/rails/webpacker/pull/1123)

- silence yarn output if checking is successful [#1131](https://github.com/rails/webpacker/pull/1131)

- Update uglifyJs plugin to support ES6 [#1194](https://github.com/rails/webpacker/pull/1194)

- Add typescript installer [#1145](https://github.com/rails/webpacker/pull/1145)

- Update default extensions and move to installer [#1181](https://github.com/rails/webpacker/pull/1181)

- Revert file loader [#1196](https://github.com/rails/webpacker/pull/1196)

## [3.2.0] - 2017-12-16

### To upgrade:

```bash
bundle update webpacker
yarn upgrade @rails/webpacker
```

### Breaking changes

If you are using react, vue, angular, elm, erb or coffeescript inside your
`packs/` please re-run the integration installers as described in the README.

```bash
bundle exec rails webpacker:install:react
bundle exec rails webpacker:install:vue
bundle exec rails webpacker:install:angular
bundle exec rails webpacker:install:elm
bundle exec rails webpacker:install:erb
bundle exec rails webpacker:install:coffee
```

Or simply copy required loaders used in your app from
https://github.com/rails/webpacker/tree/master/lib/install/loaders
into your `config/webpack/loaders/`
directory and add it to webpack build from `config/webpack/environment.js`

```js
const erb = require('./loaders/erb')
const elm = require('./loaders/elm')
const typescript = require('./loaders/typescript')
const vue = require('./loaders/vue')
const coffee = require('./loaders/coffee')

environment.loaders.append('coffee', coffee)
environment.loaders.append('vue', vue)
environment.loaders.append('typescript', typescript)
environment.loaders.append('elm', elm)
environment.loaders.append('erb', erb)
```

In `.postcssrc.yml` you need to change the plugin name from `postcss-smart-import` to `postcss-import`:

```yml
plugins:
  postcss-import: {}
  postcss-cssnext: {}
```

### Added (npm module)

- Upgrade gems and webpack dependencies

- `postcss-import` in place of `postcss-smart-import`

### Removed (npm module)

- `postcss-smart-import`, `coffee-loader`, `url-loader`, `rails-erb-loader` as dependencies

- `publicPath` from file loader [#1107](https://github.com/rails/webpacker/pull/1107)

### Fixed (npm module)

- Return native array type for `ConfigList` [#1098](https://github.com/rails/webpacker/pull/1098)

### Added (Gem)

- New `asset_pack_url` helper [#1102](https://github.com/rails/webpacker/pull/1102)

- New installers for coffee and erb

```bash
bundle exec rails webpacker:install:erb
bundle exec rails webpacker:install:coffee
```

- Resolved paths from webpacker.yml to compiler watched list

## [3.1.1] - 2017-12-11

### Fixed

- Include default webpacker.yml config inside npm package

## [3.1.0] - 2017-12-11

### Added (npm module)

- Expose base config from environment

```js
environment.config.set('resolve.extensions', ['.foo', '.bar'])
environment.config.set('output.filename', '[name].js')
environment.config.delete('output.chunkFilename')
environment.config.get('resolve')
environment.config.merge({
  output: {
    filename: '[name].js'
  }
})
```

- Expose new API's for loaders and plugins to insert at position

```js
const jsonLoader = {
  test: /\.json$/,
  exclude: /node_modules/,
  loader: 'json-loader'
}

environment.loaders.append('json', jsonLoader)
environment.loaders.prepend('json', jsonLoader)
environment.loaders.insert('json', jsonLoader, { after: 'style' })
environment.loaders.insert('json', jsonLoader, { before: 'babel' })

// Update a plugin
const manifestPlugin = environment.plugins.get('Manifest')
manifestPlugin.opts.writeToFileEmit = false

// Update coffee loader to use coffeescript 2
const babelLoader = environment.loaders.get('babel')
environment.loaders.insert(
  'coffee',
  {
    test: /\.coffee(\.erb)?$/,
    use: babelLoader.use.concat(['coffee-loader'])
  },
  { before: 'json' }
)
```

- Expose `resolve.modules` paths like loaders and plugins

```js
environment.resolvedModules.append('vendor', 'vendor')
```

- Enable sourcemaps in `style` and `css` loader

- Separate `css` and `sass` loader for easier configuration. `style` loader is now
  `css` loader, which resolves `.css` files and `sass` loader resolves `.scss` and `.sass`
  files.

```js
// Enable css modules with sass loader
const sassLoader = environment.loaders.get('sass')
const cssLoader = sassLoader.use.find(
  (loader) => loader.loader === 'css-loader'
)

cssLoader.options = Object.assign({}, cssLoader.options, {
  modules: true,
  localIdentName: '[path][name]__[local]--[hash:base64:5]'
})
```

- Expose rest of configurable dev server options from webpacker.yml

```yml
quiet: false
headers:
  'Access-Control-Allow-Origin': '*'
watch_options:
  ignored: /node_modules/
```

- `pretty` option to disable/enable color and progress output when running dev server

```yml
dev_server:
  pretty: false
```

- Enforce deterministic loader order in desc order, starts processing from top to bottom

- Enforce the entire path of all required modules match the exact case of the actual path on disk using [case sensitive paths plugin](https://github.com/Urthen/case-sensitive-paths-webpack-plugin).

- Add url loader to process and embed smaller static files

### Removed

- resolve url loader [#1042](https://github.com/rails/webpacker/issues/1042)

### Added (Gem)

- Allow skipping webpacker compile using an env variable

```bash
WEBPACKER_PRECOMPILE=no|false|n|f
WEBPACKER_PRECOMPILE=false bundle exec rails assets:precompile
```

- Use `WEBPACKER_ASSET_HOST` instead of `ASSET_HOST` for CDN

- Alias `webpacker:compile` task to `assets:precompile` if is not defined so it works
  without sprockets

## [3.0.2] - 2017-10-04

### Added

- Allow dev server connect timeout (in seconds) to be configurable, default: 0.01

```rb
# Change to 1s
Webpacker.dev_server.connect_timeout = 1
```

- Restrict the source maps generated in production [#770](https://github.com/rails/webpacker/pull/770)

- Binstubs [#833](https://github.com/rails/webpacker/pull/833)

- Allow dev server settings to be overridden by env variables [#843](https://github.com/rails/webpacker/pull/843)

- A new `lookup` method to manifest to perform lookup without raise and return `nil`

```rb
Webpacker.manifest.lookup('foo.js')
# => nil
Webpacker.manifest.lookup!('foo.js')
# => raises Webpacker::Manifest::MissingEntryError
```

- Catch all exceptions in `DevServer.running?` and return false [#878](https://github.com/rails/webpacker/pull/878)

### Removed

- Inline CLI args for dev server binstub, use env variables instead

- Coffeescript as core dependency. You have to manually add coffeescript now, if you are using
  it in your app.

```bash
yarn add coffeescript@1.12.7

# OR coffeescript 2.0
yarn add coffeescript
```

## [3.0.1] - 2017-09-01

### Fixed

- Missing `node_modules/.bin/*` files by bumping minimum Yarn version to 0.25.2 [#727](https://github.com/rails/webpacker/pull/727)

- `webpacker:compile` task so that fails properly when webpack compilation fails [#728](https://github.com/rails/webpacker/pull/728)

- Rack dev server proxy middleware when served under another proxy (example: pow), which uses `HTTP_X_FORWARDED_HOST` header resulting in `404` for webpacker assets

- Make sure tagged logger works with rails < 5 [#716](https://github.com/rails/webpacker/pull/716)

### Added

- Allow webpack dev server listen host/ip to be configurable using additional `--listen-host` option

  ```bash
  ./bin/webpack-dev-server --listen-host 0.0.0.0 --host localhost
  ```

### Removed

- `watchContentBase` from devServer config so it doesn't unncessarily trigger
  live reload when manifest changes. If you have applied this workaround from [#724](https://github.com/rails/webpacker/issues/724), please revert the change from `config/webpack/development.js` since this is now fixed.

## [3.0.0] - 2017-08-30

### Added

- `resolved_paths` option to allow adding additional paths webpack should lookup when resolving modules

```yml
# config/webpacker.yml
# Additional paths webpack should lookup modules
resolved_paths: [] # empty by default
```

- `Webpacker::Compiler.fresh?` and `Webpacker::Compiler.stale?` answer the question of whether compilation is needed.
  The old `Webpacker::Compiler.compile?` predicate is deprecated.

- Dev server config class that exposes config options through singleton.

  ```rb
  Webpacker.dev_server.running?
  ```

- Rack middleware proxies webpacker requests to dev server so we can always serve from same-origin and the lookup works out of the box - no more paths prefixing

- `env` attribute on `Webpacker::Compiler` allows setting custom environment variables that the compilation is being run with

  ```rb
  Webpacker::Compiler.env['FRONTEND_API_KEY'] = 'your_secret_key'
  ```

### Breaking changes

**Note:** requires running `bundle exec rails webpacker:install`

`config/webpack/**/*.js`:

- The majority of this config moved to the [@rails/webpacker npm package](https://www.npmjs.com/package/@rails/webpacker). `webpacker:install` only creates `config/webpack/{environment,development,test,production}.js` now so if you're upgrading from a previous version you can remove all other files.

`webpacker.yml`:

- Move dev-server config options under defaults so it's transparently available in all environments

- Add new `HMR` option for hot-module-replacement

- Add HTTPS

### Removed

- Host info from manifest.json, now looks like this:

  ```json
  {
    "hello_react.js": "/packs/hello_react.js"
  }
  ```

### Fixed

- Update `webpack-dev-server.tt` to respect RAILS_ENV and NODE_ENV values [#502](https://github.com/rails/webpacker/issues/502)
- Use `0.0.0.0` as default listen address for `webpack-dev-server`
- Serve assets using `localhost` from dev server - [#424](https://github.com/rails/webpacker/issues/424)

```yml
dev_server:
  host: localhost
```

- On Windows, `ruby bin/webpacker` and `ruby bin/webpacker-dev-server` will now bypass yarn, and execute via `node_modules/.bin` directly - [#584](https://github.com/rails/webpacker/pull/584)

### Breaking changes

- Add `compile` and `cache_path` options to `config/webpacker.yml` for configuring lazy compilation of packs when a file under tracked paths is changed [#503](https://github.com/rails/webpacker/pull/503). To enable expected behavior, update `config/webpacker.yml`:

  ```yaml
  default: &default
    cache_path: tmp/cache/webpacker
  test:
    compile: true

  development:
    compile: true

  production:
    compile: false
  ```

- Make test compilation cacheable and configurable so that the lazy compilation
  only triggers if files are changed under tracked paths.
  Following paths are watched by default -

  ```rb
    ["app/javascript/**/*", "yarn.lock", "package.json", "config/webpack/**/*"]
  ```

  To add more paths:

  ```rb
  # config/initializers/webpacker.rb or config/application.rb
  Webpacker::Compiler.watched_paths << 'bower_components'
  ```

## [2.0] - 2017-05-24

### Fixed

- Update `.babelrc` to fix compilation issues - [#306](https://github.com/rails/webpacker/issues/306)

- Duplicated asset hosts - [#320](https://github.com/rails/webpacker/issues/320), [#397](https://github.com/rails/webpacker/pull/397)

- Missing asset host when defined as a `Proc` or on `ActionController::Base.asset_host` directly - [#397](https://github.com/rails/webpacker/pull/397)

- Incorrect asset host when running `webpacker:compile` or `bin/webpack` in development mode - [#397](https://github.com/rails/webpacker/pull/397)

- Update `webpacker:compile` task to use `stdout` and `stderr` for better logging - [#395](https://github.com/rails/webpacker/issues/395)

- ARGV support for `webpack-dev-server` - [#286](https://github.com/rails/webpacker/issues/286)

### Added

- [Elm](http://elm-lang.org) support. You can now add Elm support via the following methods:

  - New app: `rails new <app> --webpack=elm`
  - Within an existing app: `rails webpacker:install:elm`

- Support for custom `public_output_path` paths independent of `source_entry_path` in `config/webpacker.yml`. `output` is also now relative to `public/`. - [#397](https://github.com/rails/webpacker/pull/397)

  Before (compile to `public/packs`):

  ```yaml
  source_entry_path: packs
  public_output_path: packs
  ```

  After (compile to `public/sweet/js`):

  ```yaml
  source_entry_path: packs
  public_output_path: sweet/js
  ```

- `https` option to use `https` mode, particularly on platforms like - https://community.c9.io/t/running-a-rails-app/1615 or locally - [#176](https://github.com/rails/webpacker/issues/176)

- [Babel] Dynamic import() and Class Fields and Static Properties babel plugin to `.babelrc`

```json
{
  "presets": [
    [
      "env",
      {
        "modules": false,
        "targets": {
          "browsers": "> 1%",
          "uglify": true
        },
        "useBuiltIns": true
      }
    ]
  ],

  "plugins": [
    "syntax-dynamic-import",
    "transform-class-properties",
    { "spec": true }
  ]
}
```

- Source-map support for production bundle

#### Breaking Change

- Consolidate and flatten `paths.yml` and `development.server.yml` config into one file - `config/webpacker.yml` - [#403](https://github.com/rails/webpacker/pull/403). This is a breaking change and requires you to re-install webpacker and cleanup old configuration files.

  ```bash
  bundle update webpacker
  bundle exec rails webpacker:install

  # Remove old/unused configuration files
  rm config/webpack/paths.yml
  rm config/webpack/development.server.yml
  rm config/webpack/development.server.js
  ```

  **Warning**: For now you also have to add a pattern in `.gitignore` by hand.

  ```diff
   /public/packs
  +/public/packs-test
   /node_modules
  ```

## [1.2] - 2017-04-27

Some of the changes made requires you to run below commands to install new changes.

```
bundle update webpacker
bundle exec rails webpacker:install
```

### Fixed

- Support Spring - [#205](https://github.com/rails/webpacker/issues/205)

  ```ruby
  Spring.after_fork { Webpacker.bootstrap } if defined?(Spring)
  ```

- Check node version and yarn before installing webpacker - [#217](https://github.com/rails/webpacker/issues/217)

- Include webpacker helper to views - [#172](https://github.com/rails/webpacker/issues/172)

- Webpacker installer on windows - [#245](https://github.com/rails/webpacker/issues/245)

- Yarn duplication - [#278](https://github.com/rails/webpacker/issues/278)

- Add back Spring for `rails-erb-loader` - [#216](https://github.com/rails/webpacker/issues/216)

- Move babel presets and plugins to .babelrc - [#202](https://github.com/rails/webpacker/issues/202)

### Added

- A changelog - [#211](https://github.com/rails/webpacker/issues/211)
- Minimize CSS assets - [#218](https://github.com/rails/webpacker/issues/218)
- Pack namespacing support - [#201](https://github.com/rails/webpacker/pull/201)

  For example:

  ```
  app/javascript/packs/admin/hello_vue.js
  app/javascript/packs/admin/hello.vue
  app/javascript/packs/hello_vue.js
  app/javascript/packs/hello.vue
  ```

- Add tree-shaking support - [#250](https://github.com/rails/webpacker/pull/250)
- Add initial test case by @kimquy [#259](https://github.com/rails/webpacker/pull/259)
- Compile assets before test:controllers and test:system

### Removed

- Webpack watcher - [#295](https://github.com/rails/webpacker/pull/295)

## [1.1] - 2017-03-24

This release requires you to run below commands to install new features.

```
bundle update webpacker
bundle exec rails webpacker:install

# if installed react, vue or angular
bundle exec rails webpacker:install:[react, angular, vue]
```

### Added (breaking changes)

- Static assets support - [#153](https://github.com/rails/webpacker/pull/153)
- Advanced webpack configuration - [#153](https://github.com/rails/webpacker/pull/153)

### Removed

```rb
config.x.webpacker[:digesting] = true
```
