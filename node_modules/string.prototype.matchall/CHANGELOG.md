4.0.4 / 2021-02-21
==================
  * [readme] fix repo URLs; remove travis badge
  * [meta] gitignore coverage output
  * [Deps] update `call-bind`, `es-abstract`, `internal-slot`, `regexp.prototype.flags`, `side-channel`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `es5-shim`, `functions-have-names`, `object-inspect`, `object.entries`, `tape`
  * [Tests] increase coverage
  * [actions] update workflows

4.0.3 / 2020-11-19
==================
  * [meta] do not publish github action workflow files
  * [Deps] update `es-abstract`, `side-channel`; use `call-bind` where applicable; remove `function-bind`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `es5-shim`, `es6-shim`, `functions-have-names`, `object-inspect`, `object.assign`, `object.entries`, `tape`
  * [actions] add "Allow Edits" workflow
  * [actions] switch Automatic Rebase workflow to `pull_request_target` event
  * [Tests] migrate tests to Github Actions
  * [Tests] run `nyc` on all tests
  * [Tests] run `es-shim-api` in postlint; use `tape` runner
  * [Tests] only audit prod deps

4.0.2 / 2019-12-22
==================
  * [Refactor] use `internal-slot`
  * [Refactor] use `side-channel` instead of "hidden" helper
  * [Deps] update `es-abstract`, `internal-slot`, `regexp.prototype.flags`, `side-channel`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `tape`

4.0.1 / 2019-12-13
==================
  * [Refactor] use split-up `es-abstract` (61% bundle size decrease)
  * [Fix] fix error message: matchAll requires *global*
  * [Deps] update `es-abstract`, `has-symbols`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `functions-have-names`, `object-inspect`, `evalmd`, `object.entries`; add `safe-publish-latest`
  * [meta] add `funding` field
  * [Tests] use shared travis-ci configs
  * [actions] add automatic rebasing / merge commit blocking

4.0.0 / 2019-10-03
==================
  * [Breaking] throw on non-global/nullish flags
  * [Deps] update `es-abstract`

3.0.2 / 2019-10-02
==================
  * [Fix] ensure that `flagsGetter` is only used when there is no `flags` property on the regex
  * [Fix] `RegExp.prototype[Symbol.matchAll]`: ToString the `flags` property
  * [Refactor] provide a consistent way to determine the polyfill for `RegExp.prototype[Symbol.matchAll]`
  * [meta] create FUNDING.yml
  * [Deps] update `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `evalmd`, `functions-have-names`, `es5-shim`, `es6-shim`, `object.entries`, `tape`
  * [Tests] up to `node` `v12.11`, `v11.15`, `v10.16`, `v8.16`, `v6.17`
  * [Tests] use `functions-have-names`
  * [Tests] bump audit level, due to https://github.com/reggi/evalmd/issues/13
  * [Tests] use `npx aud` instead of `npm audit` with hoops

3.0.1 / 2018-12-11
==================
  * [Fix] update spec to follow committee feedback
  * [Deps] update `define-properties`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `es5-shim`, `es6-shim`, `tape`
  * [Tests] use `npm audit` instead of `nsp`
  * [Tests] up to `node` `v11.4`, `v10.14`, `v8.14`, `v6.15`

3.0.0 / 2018-05-31
==================
  * [Breaking] update to match latest spec
  * [Deps] update `es-abstract`
  * [Dev Deps] update `eslint`, `nsp`, `object-inspect`, `tape`
  * [Tests] up to `node` `v10.3`, `v9.11`, `v8.11`, `v6.14`, `v4.9`
  * [Tests] regexes now have a "groups" property in ES2018
  * [Tests] run evalmd in prelint

2.0.0 / 2018-01-24
==================
  * [Breaking] change to handle nonmatching regexes
  * [Breaking] non-regex arguments that are thus coerced to RegExp now get the global flag
  * [Deps] update `es-abstract`, `regexp.prototype.flags`
  * [Dev Deps] update `es5-shim`, `eslint`, `object.assign`
  * [Tests] up to `node` `v9.4`, `v8.9`, `v6.12`; pin included builds to LTS
  * [Tests] improve and correct tests and failure messages

1.0.0 / 2017-09-28
==================
  * Initial release
