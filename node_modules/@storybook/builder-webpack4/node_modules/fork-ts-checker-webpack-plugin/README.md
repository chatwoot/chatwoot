<div align="center">

<h1>Fork TS Checker Webpack Plugin</h1>
<p>Webpack plugin that runs TypeScript type checker on a separate process.</p>

[![npm version](https://img.shields.io/npm/v/fork-ts-checker-webpack-plugin.svg)](https://www.npmjs.com/package/fork-ts-checker-webpack-plugin)
[![npm beta version](https://img.shields.io/npm/v/fork-ts-checker-webpack-plugin/beta.svg)](https://www.npmjs.com/package/fork-ts-checker-webpack-plugin)
[![build status](https://github.com/TypeStrong/fork-ts-checker-webpack-plugin/workflows/CI/CD/badge.svg?branch=master&event=push)](https://github.com/TypeStrong/fork-ts-checker-webpack-plugin/actions?query=branch%3Amaster+event%3Apush)
[![downloads](http://img.shields.io/npm/dm/fork-ts-checker-webpack-plugin.svg)](https://npmjs.org/package/fork-ts-checker-webpack-plugin)
[![commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)
[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://github.com/prettier/prettier)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

</div>

## Installation

This plugin requires minimum **Node.js 6.11.5**, **webpack 4**, **TypeScript 2.1** and optionally **ESLint 6** (which itself requires minimum **Node.js 8.10.0**)

If you depend on **webpack 2**, **webpack 3**, or **tslint 4**, please use [older version](https://github.com/TypeStrong/fork-ts-checker-webpack-plugin/tree/v3.1.1) of the plugin. 

```sh
# with npm
npm install --save-dev fork-ts-checker-webpack-plugin

# with yarn
yarn add --dev fork-ts-checker-webpack-plugin
```

Basic webpack config (with [ts-loader](https://github.com/TypeStrong/ts-loader))

```js
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');

const webpackConfig = {
  context: __dirname, // to automatically find tsconfig.json
  entry: './src/index.ts',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: 'ts-loader',
        options: {
          // disable type checker - we will use it in fork plugin
          transpileOnly: true
        }
      }
    ]
  },
  plugins: [new ForkTsCheckerWebpackPlugin()]
};
```

## Motivation

There was already similar solution - [awesome-typescript-loader](https://github.com/s-panferov/awesome-typescript-loader). You can
add `CheckerPlugin` and delegate checker to the separate process. The problem with `awesome-typescript-loader` was that, in our case,
it was a lot slower than [ts-loader](https://github.com/TypeStrong/ts-loader) on an incremental build (~20s vs ~3s).
Secondly, we used [tslint](https://palantir.github.io/tslint) and we wanted to run this, along with type checker, in a separate process.
This is why this plugin was created. To provide better performance, the plugin reuses Abstract Syntax Trees between compilations and shares
these trees with TSLint.

## Modules resolution

It's very important to be aware that **this plugin uses [TypeScript](https://github.com/Microsoft/TypeScript)'s, not
[webpack](https://github.com/webpack/webpack)'s modules resolution**. It means that you have to setup `tsconfig.json` correctly. For example
if you set `files: ['./src/someFile.ts']` in `tsconfig.json`, this plugin will check only `someFile.ts` for semantic errors. It's because
of performance. The goal of this plugin is to be _as fast as possible_. With TypeScript's module resolution we don't have to wait for webpack
to compile files (which traverses dependency graph during compilation) - we have a full list of files from the begin.

To debug TypeScript's modules resolution, you can use `tsc --traceResolution` command.

## ESLint

[ESLint is the future of linting in the TypeScript world.](https://eslint.org/blog/2019/01/future-typescript-eslint) If you'd like to use eslint with the plugin, supply this option: `eslint: true` and ensure you have the relevant dependencies installed:

`yarn add eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin --dev`

You should have an ESLint configuration file in your root project directory. Here is a sample `.eslintrc.js` configuration for a TypeScript project:

```js
const path = require('path');
module.exports = {
  parser: '@typescript-eslint/parser', // Specifies the ESLint parser
  extends: [
    'plugin:@typescript-eslint/recommended' // Uses the recommended rules from the @typescript-eslint/eslint-plugin
  ],
  parserOptions: {
    project: path.resolve(__dirname, './tsconfig.json'),
    tsconfigRootDir: __dirname,
    ecmaVersion: 2018, // Allows for the parsing of modern ECMAScript features
    sourceType: 'module', // Allows for the use of imports
  },
  rules: {
    // Place to specify ESLint rules. Can be used to overwrite rules specified from the extended configs
    // e.g. "@typescript-eslint/explicit-function-return-type": "off",
  }
};
```

There's a good explanation on setting up TypeScript ESLint support by Robert Cooper [here](https://dev.to/robertcoopercode/using-eslint-and-prettier-in-a-typescript-project-53jb).

## Options

- **tsconfig** `string`:
  Path to _tsconfig.json_ file. Default: `path.resolve(compiler.options.context, './tsconfig.json')`.

- **compilerOptions** `object`:
  Allows overriding TypeScript options. Should be specified in the same format as you would do for the `compilerOptions` property in tsconfig.json. Default: `{}`.

- **eslint** `true | undefined`:

  - If `true`, this activates eslint support.

- **eslintOptions** `object`:

  - Options that can be used to initialise ESLint. See https://eslint.org/docs/developer-guide/nodejs-api#cliengine
  
- **async** `boolean`:
  True by default - `async: false` can block webpack's emit to wait for type checker/linter and to add errors to the webpack's compilation.
  We recommend to set this to `false` in projects where type checking is faster than webpack's build - it's better for integration with other plugins. Another scenario where you might want to set this to `false` is if you use the `overlay` functionality of `webpack-dev-server`.

- **ignoreDiagnostics** `number[]`:
  List of TypeScript diagnostic codes to ignore.

- **ignoreLints** `string[]`:
  List of eslint rule names to ignore.

- **ignoreLintWarnings** `boolean`:
  If true, will ignore all lint warnings.

- **reportFiles** `string[]`:
  Only report errors on files matching these glob patterns. This can be useful when certain types definitions have errors that are not fatal to your application. Default: `[]`. Please note that this may behave unexpectedly if using the incremental API as the incremental API doesn't look for global and semantic errors [if it has already found syntactic errors](https://github.com/Microsoft/TypeScript/blob/89386ddda7dafc63cb35560e05412487f47cc267/src/compiler/watch.ts#L141).

```js
// in webpack.config.js
new ForkTsCheckerWebpackPlugin({
  reportFiles: ['src/**/*.{ts,tsx}', '!src/skip.ts']
});
```

- **logger** `object`:
  Logger instance. It should be object that implements method: `error`, `warn`, `info`. Default: `console`.

- **formatter** `'default' | 'codeframe' | (issue: Issue) => string)`:
  Formatter for issues and lints. By default uses `default` formatter. You can also pass your own formatter as a function
  (see `src/issue/` and `src/formatter/` for API reference).

- **formatterOptions** `object`:
  Options passed to formatters (currently only `codeframe` - see [available options](https://babeljs.io/docs/en/next/babel-code-frame.html#options))

- **silent** `boolean`:
  If `true`, logger will not be used. Default: `false`.

- **checkSyntacticErrors** `boolean`:
  This option is useful if you're using ts-loader in `happyPackMode` with [HappyPack](https://github.com/amireh/happypack) or [thread-loader](https://github.com/webpack-contrib/thread-loader) to parallelise your builds. If `true` it will ensure that the plugin checks for _both_ syntactic errors (eg `const array = [{} {}];`) and semantic errors (eg `const x: number = '1';`). By default the plugin only checks for semantic errors. This is because when ts-loader is used in `transpileOnly` mode, ts-loader will still report syntactic errors. When used in `happyPackMode` it does not. Default: `false`.

- **memoryLimit** `number`:
  Memory limit for service process in MB. If service exits with allocation failed error, increase this number. Default: `2048`.

- **vue** `boolean | { enabled: boolean, compiler: string }`:
  If `true` or `enabled: true`, the linter and compiler will process VueJs single-file-component (.vue) files. See the
  [Vue section](https://github.com/TypeStrong/fork-ts-checker-webpack-plugin#vue) further down for information on how to correctly setup your project.

- **useTypescriptIncrementalApi** `boolean`:
  If true, the plugin will use incremental compilation API introduced in TypeScript 2.7. Defaults to `true` when working with TypeScript 3+ and `false` when below 3. The default can be overridden by directly specifying a value.
  Don't use it together with VueJs enabled - it's not supported yet.

- **measureCompilationTime** `boolean`:
  If true, the plugin will measure the time spent inside the compilation code. This may be useful to compare modes,
  especially if there are other loaders/plugins involved in the compilation. **requires Node.js >= 8.5.0**

- **typescript** `string`:
  If supplied this is a custom path where `typescript` can be found. Defaults to `require.resolve('typescript')`.

- **resolveModuleNameModule** and **resolveTypeReferenceDirectiveModule** `string`:
  Both of those options refer to files on the disk that respectively export a `resolveModuleName` or a `resolveTypeReferenceDirectiveModule` function. These functions will be used to resolve the import statements and the `<reference types="...">` directives instead of the default TypeScript implementation. Check the following code for an example of what those functions should look like:

  <details>
    <summary>Code sample</summary>

  ```js
  const { resolveModuleName } = require(`ts-pnp`);

  exports.resolveModuleName = (
    typescript,
    moduleName,
    containingFile,
    compilerOptions,
    resolutionHost
  ) => {
    return resolveModuleName(
      moduleName,
      containingFile,
      compilerOptions,
      resolutionHost,
      typescript.resolveModuleName
    );
  };

  exports.resolveTypeReferenceDirective = (
    typescript,
    moduleName,
    containingFile,
    compilerOptions,
    resolutionHost
  ) => {
    return resolveModuleName(
      moduleName,
      containingFile,
      compilerOptions,
      resolutionHost,
      typescript.resolveTypeReferenceDirective
    );
  };
  ```

</details>

## Different behaviour in watch mode

If you turn on [webpacks watch mode](https://webpack.js.org/configuration/watch/#watch) the `fork-ts-checker-notifier-webpack-plugin` will take care of logging type errors, _not_ webpack itself. That means if you set `silent: true` you won't see type errors in your console in watch mode.

You can either set `silent: false` to show the logging from `fork-ts-checker-notifier-webpack-plugin` _or_ set `async: false`. Now webpack itself will log type errors again, but note that this can slow down your builds depending on the size of your project.

## Notifier

You may already be using the excellent [webpack-notifier](https://github.com/Turbo87/webpack-notifier) plugin to make build failures more obvious in the form of system notifications. There's an equivalent notifier plugin designed to work with the `fork-ts-checker-webpack-plugin`. It is the `fork-ts-checker-notifier-webpack-plugin` and can be found [here](https://github.com/johnnyreilly/fork-ts-checker-notifier-webpack-plugin). This notifier deliberately has a similar API as the `webpack-notifier` plugin to make migration easier.

## Known Issue Watching Non-Emitting Files

At present there is an issue with the plugin regarding the triggering of type-checking when a change is made in a source file that will not emit js. If you have a file which contains only `interface`s and / or `type`s then changes to it will **not** trigger the type checker whilst in watch mode. Sorry about that.

We hope this will be resolved in future; the issue can be tracked [here](https://github.com/TypeStrong/fork-ts-checker-webpack-plugin/issues/36).

## Plugin Hooks

This plugin provides some custom webpack hooks (all are sync):

| Hook Access Key      | Description                                                                    | Params                            |
| -------------------- | ------------------------------------------------------------------------------ | --------------------------------- |
| `cancel`             | Cancellation has been requested                                                | `cancellationToken`               |
| `waiting`            | Waiting for results                                                            | -                                 |
| `serviceBeforeStart` | Async plugin that can be used for delaying `fork-ts-checker-service-start`     | -                                 |
| `serviceStart`       | Service will be started                                                        | `tsconfigPath`, `memoryLimit`     |
| `serviceStartError`  | Cannot start service                                                           | `error`                           |
| `serviceOutOfMemory` | Service is out of memory                                                       | -                                 |
| `receive`            | Plugin receives diagnostics and lints from service                             | `diagnostics`, `lints`            |
| `emit`               | Service will add errors and warnings to webpack compilation ('build' mode)     | `diagnostics`, `lints`, `elapsed` |
| `done`               | Service finished type checking and webpack finished compilation ('watch' mode) | `diagnostics`, `lints`, `elapsed` |

### Accessing plugin hooks

To access plugin hooks and tap into the event, we need to use
the `getCompilerHooks` static method. When we call this method with a [webpack compiler instance](https://webpack.js.org/api/node/),
it returns the series of [tapable](https://github.com/webpack/tapable)
hooks where you can pass in your callbacks.

```js
// require the plugin
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');
// setup compiler with the plugin
const compiler = webpack({
  // .. webpack config
});
// Optionally add the plugin to the compiler
// **Don't do this if already added through configuration**
new ForkTsCheckerWebpackPlugin({
  silent: true,
  async: true
}).apply(compiler);
// Now get the plugin hooks from compiler
const tsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(compiler);
// These hooks provide access to different events
// =================================================== //
// The properties of tsCheckerHooks corresponds to the //
// Hook Access Key of the table above.                 //
// =================================================== //
// Example, if we want to run some code when plugin has received diagnostics
// and lint
tsCheckerHooks.receive.tap('yourListenerName', (diagnostics, lint) => {
  // do something with diagnostics, perhaps show custom message
  console.log(diagnostics);
});
// Say we want to show some message when plugin is waiting for typecheck results
tsCheckerHooks.waiting.tap('yourListenerName', () => {
  console.log('waiting for typecheck results');
});
```

Calling `.tap()` on any hooks, requires two arguments.

##### `name` (`string`)

The first argument passed to `.tap` is the name of your listener callback (`yourListenerName`).
It doesn't need to correspond to anything special. It is intended to be used
[internally](https://github.com/webpack/tapable#interception) as the `name` of
the hook.

##### `callback` (`function`)

The second argument is the callback function. Depending on the hook you are
tapping into, several arguments are passed to the function. Do check the table
above to find out which arguments are passed to which hooks.

### Accessing hooks on Webpack Multi-Compiler instance

The above method will not work on webpack [multi compiler](https://webpack.js.org/api/node/#multicompiler)
instance. The reason is `getCompilerHooks` expects (at lease as of now) the same
compiler instance to be passed where the plugin was attached. So in case of
multi compiler, we need to access individual compiler instances.

```js
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');
// setup multi compiler with the plugin
const compiler = webpack([
  {
    // .. webpack config
  },
  {
    // .. webpack config
  }
]);

// safely determine if instance is multi-compiler
if ('compilers' in compiler) {
  compiler.compilers.forEach(singleCompiler => {
    // get plugin hooks from the single compiler instance
    const tsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(
      singleCompiler
    );
    // now access hooks just like before
    tsCheckerHooks.waiting.tap('yourListenerName', () => {
      console.log('waiting for typecheck results');
    });
  });
}
```

## Vue

1. Turn on the vue option in the plugin in your webpack config:

```js
new ForkTsCheckerWebpackPlugin({
  vue: true
});
```
Optionally change default [vue-template-compiler](https://github.com/vuejs/vue/tree/dev/packages/vue-template-compiler) to [nativescript-vue-template-compiler](https://github.com/nativescript-vue/nativescript-vue/tree/master/packages/nativescript-vue-template-compiler) if you use [nativescript-vue](https://github.com/nativescript-vue/nativescript-vue)
```
new ForkTsCheckerWebpackPlugin({
  vue: { enabled: true, compiler: 'nativescript-vue-template-compiler' }
});
```

2. To activate TypeScript in your `.vue` files, you need to ensure your script tag's language attribute is set
   to `ts` or `tsx` (also make sure you include the `.vue` extension in all your import statements as shown below):

```html
<script lang="ts">
  import Hello from '@/components/hello.vue';

  // ...
</script>
```

3. Ideally you are also using `ts-loader` (in transpileOnly mode). Your Webpack config rules may look something like this:

```js
{
  test: /\.ts$/,
  loader: 'ts-loader',
  include: [resolve('src'), resolve('test')],
  options: {
    appendTsSuffixTo: [/\.vue$/],
    transpileOnly: true
  }
},
{
  test: /\.vue$/,
  loader: 'vue-loader',
  options: vueLoaderConfig
},
```

4. Ensure your `tsconfig.json` includes .vue files:

```js
// tsconfig.json
{
  "include": [
    "src/**/*.ts",
    "src/**/*.vue"
  ],
  "exclude": [
    "node_modules"
  ]
}
```

5. It accepts any wildcard in your TypeScript configuration:

```js
// tsconfig.json
{
  "compilerOptions": {

    // ...

    "baseUrl": ".",
    "paths": {
      "@/*": [
        "src/*"
      ],
      "~/*": [
        "src/*"
      ]
    }
  }
}

// In a .ts or .vue file...
import Hello from '@/components/hello.vue'
```

6. If you are working in **VSCode**, you can get the [Vetur](https://marketplace.visualstudio.com/items?itemName=octref.vetur) extension to complete the developer workflow.

## Credits

This plugin was created in [Realytics](https://www.realytics.io/) in 2017. Thank you for supporting Open Source.

## License

MIT License
