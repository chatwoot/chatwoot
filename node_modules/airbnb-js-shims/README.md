# airbnb-js-shims <sup>[![Version Badge][2]][1]</sup>

JS language shims used by Airbnb.

Just require/import `airbnb-js-shims`, and the environment will be shimmed.

```js
import 'airbnb-js-shims';
```

## Included shims

 - [es5-shim](https://www.npmjs.com/package/es5-shim)
 - [es5-sham](https://www.npmjs.com/package/es5-shim)
 - [es6-shim](https://www.npmjs.com/package/es6-shim)
 - [Function.prototype.name](https://www.npmjs.com/package/function.prototype.name)
 - [Array.prototype.includes](https://www.npmjs.com/package/array-includes) (ES7/ES2016)
 - [Object.entries](https://www.npmjs.com/package/object.entries) (ES8/ES2017)
 - [Object.values](https://www.npmjs.com/package/object.values) (ES8/ES2017)
 - [String.prototype.padStart](https://www.npmjs.com/package/string.prototype.padstart) (ES8/ES2017)
 - [String.prototype.padEnd](https://www.npmjs.com/package/string.prototype.padend) (ES8/ES2017)
 - [Promise.prototype.finally](https://npmjs.com/package/promise.prototype.finally) (ES2018)
 - [Array.prototype.flat](https://npmjs.com/package/array.prototype.flat) (ES2019)
 - [Array.prototype.flatMap](https://npmjs.com/package/array.prototype.flatmap) (ES2019)
 - [Symbol.prototype.description](https://npmjs.com/package/symbol.prototype.description) (ES2019)
 - [Object.fromEntries](https://npmjs.com/package/object.fromentries) (ES2019)
 - [String.prototype.matchAll](https://npmjs.com/package/string.prototype.matchall) (ES2019)
 - [globalThis](https://www.npmjs.com/package/globalthis) (Stage 3)
 - [Promise.allSettled](https://www.npmjs.com/package/promise.allsettled) (Stage 3)

## Targeting versions

If you do not need to support older browsers, you can pick a subset of ES versions to target. For example, if you don't support pre-ES5 browsers, you can start your shims with ES2015 by requiring/importing the specific target file. This will shim the environment for that version and upward.

```js
import 'airbnb-js-shims/target/es2015';
```

### Included targets

- `airbnb-js-shims/target/es5` (default)
- `airbnb-js-shims/target/es2015`
- `airbnb-js-shims/target/es2016`
- `airbnb-js-shims/target/es2017`
- `airbnb-js-shims/target/es2018`
- `airbnb-js-shims/target/es2019`
- `airbnb-js-shims/target/es2020`

[1]: https://npmjs.org/package/airbnb-js-shims
[2]: http://versionbadg.es/airbnb/js-shims.svg
