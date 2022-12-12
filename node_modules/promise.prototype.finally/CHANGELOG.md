3.1.2 / 2019-12-11
=================
  * [Refactor] use split-up `es-abstract`
  * [Deps] update `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `safe-publish-latest`
  * [Tests] up to `node` `v12.12`
  * [Tests] use shared travis-ci configs
  * [meta] add `funding` field
  * [actions] add automatic rebasing / merge commit blocking

3.1.1 / 2019-08-25
=================
  * [Fix] `finally` receiver must only be an Object, not a Promise
  * [Deps] update `define-properties`, `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `@es-shims/api`, `covert`, `es6-shim`, `safe-publish-latest`, `tape`
  * [Tests] up to `node` `v12.9`, `v11.15`, `v10.16`, `v9.11`, `v8.16`, `v6.17`, `v4.9`
  * [Tests] add test for non-Promise receiver
  * [Tests] use `npx aud` instead of `nsp` or `npm audit` with hoops

3.1.0 / 2017-10-26
=================
  * [New] Add auto shim file, allowing clean 'import' (#12)
  * [Refactor] only call `Promise#then` for a brand check once, instead of twice.
  * [Deps] update `es-abstract`
  * [Dev Deps] update `eslint`, `nsp`

3.0.1 / 2017-09-09
=================
  * [Fix] ensure that the “then” brand check doesn’t cause an unhandled rejection warning (#10)
  * [Deps] update `es-abstract`, `function-bind`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `nsp`, `tape`, `@es-shims/api`
  * [Tests] up to `node` `v8.4`; use `nvm install-latest-npm` so new `npm` doesn’t break old `node`; add 0.8
  * [Tests] restore ES5 tests
  * [Tests] refactor to allow for unshimmed tests

3.0.0 / 2017-07-25
=================
  * [Breaking] update implementation to follow the new spec (#9)
  * [Deps] update `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `es6-shim`, `nsp`, `safe-publish-latest`, `tape`
  * [Tests] up to `node` `v8.1`, `v7.10`, `v6.11`, `v4.8`; improve matrix
  * [Tests] fix 0.10; remove 0.8

2.0.1 / 2016-09-27
=================
  * [Fix] functions in IE 9-11 don’t have a `name` property (#3)

2.0.0 / 2016-08-21
=================
  * Re-release.

[1.0.1](https://github.com/matthew-andrews/Promise.prototype.finally/releases/tag/v1.0.1) / 2015-02-09
=================
  * Always replace function for predictability (https://github.com/matthew-andrews/Promise.prototype.finally/issues/3)
  * Wrap polyfill so that if it's used direct it doesn't leak

[1.0.0](https://github.com/matthew-andrews/Promise.prototype.finally/releases/tag/v1.0.0) / 2014-10-11
=================
  * Initial release.
