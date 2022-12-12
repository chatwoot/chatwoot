# Lazy Universal DotEnv

[npm]: https://www.npmjs.com/package/universal-dotenv
[travis]: https://travis-ci.org/storybooks/lazy-universal-dotenv

Lazy Universal DotEnv - A Robust Environment Configuration for Universal Applications.

## Features

- Supports loading `.env` files with overriding between different `NODE_ENV` settings and `BUILD_TARGET` configurations.
- Supports variable expansion between different settings.
- Allows local overrides using files which use a ".local" postfix.

## All Strings

It is important to remember that all environment variables are always stored as strings. Even numbers and booleans. The casting to other types must therefore take place in the application code. See also: https://github.com/motdotla/dotenv/issues/51

## Variables

- `NODE_ENV`: Typically either `production`, `development` or `test`
- `BUILD_TARGET`: Either `client` or `server`

## File Priority

Files are being loaded in this order. Values which are already set are never overwritten. Command line environment settings e.g. via [cross-env](https://www.npmjs.com/package/cross-env) always win.

- `.env.${BUILD_TARGET}.${NODE_ENV}.local`
- `.env.${BUILD_TARGET}.${NODE_ENV}`
- `.env.${BUILD_TARGET}.local`
- `.env.${BUILD_TARGET}`
- `.env.${NODE_ENV}.local`
- `.env.${NODE_ENV}`
- `.env.local`
- `.env`

Note: `local` files without `NODE_ENV` are not respected when running in `NODE_ENV=test`.

## Basic Usage

```js
import { getEnvironment } from "lazy-dotenv-universal";

const environment = getEnvironment({ nodeEnv, buildTarget });

const { raw, stringified, webpack } = environment;
```

After this you can access all environment settings you have defined in one of your `.env` files.

A .env file:
```
MY_END=awesome
```

Webpack config:
```js
import { getEnvironment } from "lazy-dotenv-universal";

export default {
  // ... 
  plugins: [
    new webpack.DefinePlugin(getEnvironment().webpack),
  ],
  // ...
}
```

Code being bundled by webpack:
```js
console.log(process.env.MY_ENV); // -> "awesome"
```

### Serialization

- raw: Just a plain JS object containing all app settings
- stringified: Plain object but with JSON stringified values
- webpack: For usage with [Webpacks Define Plugin](https://webpack.js.org/plugins/define-plugin/)


## License

[Apache License Version 2.0, January 2004](license)

## Copyright

Copyright 2018<br/>[Sebastian Software GmbH](http://www.sebastian-software.de)
