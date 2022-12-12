2.2.1 / 2019-11-15
=================
  * Allow `string.prototype.matchall` v4

2.2.0 / 2019-04-25
=================
  * [New] add `es2020` target; add `globalthis` and `promise.allsettled` shims
  * [Deps] update `object.entries`, `object.fromentries`, `object.values`, `string.prototype.matchall`, `es5-shim`, `es6-shim`
  * [Dev Deps] update `eslint`, `eslint-config-airbnb-base`, `eslint-plugin-import`, `safe-publish-latest`, `tape`
  * [Docs] Update proposals that are in the language
  * [Tests] use `npm audit` instead of `nsp`

2.1.1 / 2018-08-31
=================
  * [meta] add license text (#8)
  * [docs] fix link to flatMap package (#7)

2.1.0 / 2018-07-25
=================
  * [New] add `Object.fromEntries`

2.0.0 / 2018-06-14
=================
  * [Breaking] remove `Array.prototype.flatten`

1.7.1 / 2018-08-31
=================
  * [meta] add license text (#8)
  * [docs] fix link to flatMap package (#7)

1.7.0 / 2018-07-25
=================
  * [New] add `Object.fromEntries`

1.6.0 / 2018-05-31
=================
  * [New] add `String.prototype.matchAll`, and `es2019` target

1.5.2 / 2018-05-27
=================
  * [Fix] restore `.flatten()`

1.5.1 / 2018-05-22
=================
  * [Fix] actually add `Array.prototype.flat` and `Symbol.prototype.description`

1.5.0 / 2018-05-22
=================
  * [New] add `array.prototype.flat`, deprecate `Array.prototype.flatten`
  * [New] add `symbol.prototype.description`
  * [Deps] update `array.prototype.flatten`, `array.prototype.flatmap`
  * [Dev Deps] update `eslint`, `eslint-plugin-import`, `nsp`, `tape`

1.4.1 / 2018-01-24
=================
  * [Docs] Promise.prototype.finally is at stage 4
  * [Deps] update `array.prototype.flatmap`, `array.prototype.flatten`, `es5-shim`, `function.prototype.name`
  * [Dev Deps] update `eslint`
  * [Tests] up to `node` `v9.4`; pin included builds to LTS

1.4.0 / 2017-11-29
=================
  * [New] add `Array.prototype.flat{ten,Map}`, now at stage 3
  * [Deps] update `promise.prototype.finally`
  * [Dev Deps] update `eslint`, `eslint-config-airbnb-base`, `eslint-plugin-import`, `tape`
  * [Tests] up to `node` `v9.2`, `v8.9`, `v6.12`; use `nvm install-latest-npm`; pin included builds to LTS

1.3.0 / 2017-07-28
=================
  * [New] add `promise.prototype.finally` shim, and ES2018 target
  * [Deps] update `function.prototype.name`
  * [Dev Deps] update `eslint`, `eslint-config-airbnb-base`

1.2.0 / 2017-07-14
=================
  * [New] add `Function#name` shim for IE 9-11
  * [Deps] update `array-includes`, `es6-shim`, `object.entries`, `object.values`
  * [Dev Deps] update `eslint`, `eslint-plugin-import`, `safe-publish-latest`, `tape`; switch to `eslint-config-airbnb-base`
  * [Tests] up to `node` `v8.1`, `v7.10`, `v6.11`, `v5.12`, `v4.8`; improve matrix; newer npms fail on older nodes
  * [Tests] ensure all target files parse

1.1.1 / 2017-02-16
=================
  * [Fix] Correctly require es2017 from es2016

1.1.0 / 2017-02-15
=================
  * [New] Add entry points for targeting specific ES versions

1.0.1 / 2016-08-17
=================
  * [Deps] update `es5-shim`, `es6-shim`, `object.getownpropertydescriptors`
  * [Dev Deps] update `tape`
  * [Docs] Update things that are now stage 4
  * [Tests] move tests into test dir
  * [Tests] add `npm run lint`

1.0.0 / 2016-03-24
=================
  * Initial release.
