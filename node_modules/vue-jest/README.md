# vue-jest

Jest transformer for Vue single file components

> **NOTE:** This is documentation for `vue-jest@4.x`. [View the vue-jest@3.x documentation](https://github.com/vuejs/vue-jest/tree/v3)

## Usage

```bash
npm install --save-dev vue-jest
yarn add vue-jest --dev
```

### Usage with Babel 7

If you use [jest](https://github.com/facebook/jest) > 24.0.0 and [babel-jest](https://github.com/facebook/jest/tree/master/packages/babel-jest) make sure to install babel-core@bridge

```bash
npm install --save-dev babel-core@bridge
yarn add babel-core@bridge --dev
```

## Setup

To use `vue-jest` as a transformer for your `.vue` files, map them to the `vue-jest` module:

```json
{
  "jest": {
    "transform": {
      "^.+\\.vue$": "vue-jest"
    }
  }
}
```

A full config will look like this.

```json
{
  "jest": {
    "moduleFileExtensions": ["js", "json", "vue"],
    "transform": {
      "^.+\\.js$": "babel-jest",
      "^.+\\.vue$": "vue-jest"
    }
  }
}
```

## Examples

Example repositories testing Vue components with jest and vue-jest:

- [Vue Test Utils with Jest](https://github.com/eddyerburgh/vue-test-utils-jest-example)

## Supported langs

vue-jest compiles `<script />`, `<template />`, and `<style />` blocks with supported `lang` attributes into JavaScript that Jest can run.

### Supported script languages

- **typescript** (`lang="ts"`, `lang="typescript"`)
- **coffeescript** (`lang="coffee"`, `lang="coffeescript"`)

### Global Jest options

You can change the behavior of `vue-jest` by using `jest.globals`.

#### Supporting custom blocks

A great feature of the Vue SFC compiler is that it can support custom blocks. You might want to use those blocks in your tests. To render out custom blocks for testing purposes, you'll need to write a transformer. Once you have your transformer, you'll add an entry to vue-jest's transform map. This is how [vue-i18n's](https://github.com/kazupon/vue-i18n) `<i18n>` custom blocks are supported in unit tests.

A `package.json` Example

```json
{
  "jest": {
    "moduleFileExtensions": ["js", "json", "vue"],
    "transform": {
      "^.+\\.js$": "babel-jest",
      "^.+\\.vue$": "vue-jest"
    },
    "globals": {
      "vue-jest": {
        "transform": {
          "your-custom-block": "./custom-block-processor.js"
        }
      }
    }
  }
}
```

> _Tip:_ Need programmatic configuration? Use the [--config](https://jestjs.io/docs/en/cli.html#config-path) option in Jest CLI, and export a `.js` file

A `jest.config.js` Example - If you're using a dedicated configuration file like you can reference and require your processor in the config file instead of using a file reference.

```js
module.exports = {
  globals: {
    'vue-jest': {
      transform: {
        'your-custom-block': require('./custom-block-processor')
      }
    }
  }
}
```

#### Writing a processor

Processors must return an object with a "process" method, like so...

```js
module.exports = {
  /**
   * Process the content inside of a custom block and prepare it for execution in a testing environment
   * @param {SFCCustomBlock[]} blocks All of the blocks matching your type, returned from `@vue/component-compiler-utils`
   * @param {string} vueOptionsNamespace The internal namespace for a component's Vue Options in vue-jest
   * @param {string} filename The SFC file being processed
   * @param {Object} config The full Jest config
   * @returns {string} The code to be output after processing all of the blocks matched by this type
   */
  process({ blocks, vueOptionsNamespace, filename, config }) {}
}
```

#### babelConfig

Provide `babelConfig` in one of the following formats:

- `<Boolean>`
- `<Object>`
- `<String>`

##### Boolean

- `true` - Enable Babel processing. `vue-jest` will try to find Babel configuration using [find-babel-config](https://www.npmjs.com/package/find-babel-config).

> This is the default behavior if [babelConfig](#babelconfig) is not defined.

- `false` - Skip Babel processing entirely:

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "babelConfig": false
      }
    }
  }
}
```

##### Object

Provide inline [Babel options](https://babeljs.io/docs/en/options):

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "babelConfig": {
          "presets": [
            [
              "env",
              {
                "useBuiltIns": "entry",
                "shippedProposals": true
              }
            ]
          ],
          "plugins": ["syntax-dynamic-import"],
          "env": {
            "test": {
              "plugins": ["dynamic-import-node"]
            }
          }
        }
      }
    }
  }
}
```

##### String

If a string is provided, it will be an assumed path to a babel configuration file (e.g. `.babelrc`, `.babelrc.js`).

- Config file should export a Babel configuration object.
- Should _not_ point to a [project-wide configuration file (babel.config.js)](https://babeljs.io/docs/en/config-files#project-wide-configuration), which exports a function.

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "babelConfig": "path/to/.babelrc.js"
      }
    }
  }
}
```

To use the [Config Function API](https://babeljs.io/docs/en/config-files#config-function-api), use inline options instead. i.e.:

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "babelConfig": {
          "configFile": "path/to/babel.config.js"
        }
      }
    }
  }
}
```

#### tsConfig

Provide `tsConfig` in one of the following formats:

- `<Boolean>`
- `<Object>`
- `<String>`

##### Boolean

- `true` - Process TypeScript files using custom configuration. `vue-jest` will try to find TypeScript configuration using [tsconfig.loadSync](https://www.npmjs.com/package/tsconfig#api).

> This is the default behavior if [tsConfig](#tsConfig) is not defined.

- `false` - Process TypeScript files using the [default configuration provided by vue-jest](https://github.com/vuejs/vue-jest/blob/master/lib/load-typescript-config.js#L5-L27).

##### Object

Provide inline [TypeScript compiler options](https://www.typescriptlang.org/docs/handbook/compiler-options.html):

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "tsConfig": {
          "importHelpers": true
        }
      }
    }
  }
}
```

##### String

If a string is provided, it will be an assumed path to a TypeScript configuration file:

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "tsConfig": "path/to/tsconfig.json"
      }
    }
  }
}
```

#### templateCompiler

You can provide [TemplateCompileOptions](https://github.com/vuejs/component-compiler-utils#compiletemplatetemplatecompileoptions-templatecompileresults) in `templateCompiler` section like this:

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "templateCompiler": {
          "transpileOptions": {
            "transforms": {
              "dangerousTaggedTemplateString": true
            }
          }
        }
      }
    }
  }
}
```

### Supported template languages

- **pug** (`lang="pug"`)

  - To give options for the Pug compiler, enter them into the Jest configuration.
    The options will be passed to pug.compile().

  ```json
  {
    "jest": {
      "globals": {
        "vue-jest": {
          "pug": {
            "basedir": "mybasedir"
          }
        }
      }
    }
  }
  ```

- **jade** (`lang="jade"`)
- **haml** (`lang="haml"`)

### Supported style languages

- **stylus** (`lang="stylus"`, `lang="styl"`)
- **sass** (`lang="sass"`), and
- **scss** (`lang="scss"`)

  - The Sass compiler supports Jest's [moduleNameMapper](https://facebook.github.io/jest/docs/en/configuration.html#modulenamemapper-object-string-string) which is the suggested way of dealing with Webpack aliases. Webpack's `sass-loader` uses a [special syntax](https://github.com/webpack-contrib/sass-loader/blob/v9.0.2/README.md#resolving-import-at-rules) for indicating non-relative imports, so you'll likely need to copy this syntax into your `moduleNameMapper` entries if you make use of it. For aliases of bare imports (imports that require node module resolution), the aliased value must also be prepended with this `~` or `vue-jest`'s custom resolver won't recognize it.
    ```json
    {
      "jest": {
        "moduleNameMapper": {
          "^~foo/(.*)": "<rootDir>/foo/$1",
          // @import '~foo'; -> @import 'path/to/project/foo';
          "^~bar/(.*)": "~baz/lib/$1"
          // @import '~bar/qux'; -> @import 'path/to/project/node_modules/baz/lib/qux';
          // Notice how the tilde (~) was needed on the bare import to baz.
        }
      }
    }
    ```
  - To import globally included files (ie. variables, mixins, etc.), include them in the Jest configuration at `jest.globals['vue-jest'].resources.scss`:

    ```json
    {
      "jest": {
        "globals": {
          "vue-jest": {
            "resources": {
              "scss": [
                "./node_modules/package/_mixins.scss",
                "./src/assets/css/globals.scss"
              ]
            }
          }
        }
      }
    }
    ```

## CSS options

`experimentalCSSCompile`: `Boolean` Default true. Turn off CSS compilation
`hideStyleWarn`: `Boolean` Default false. Hide warnings about CSS compilation
`resources`:

```json
{
  "jest": {
    "globals": {
      "vue-jest": {
        "hideStyleWarn": true,
        "experimentalCSSCompile": true
      }
    }
  }
}
```
