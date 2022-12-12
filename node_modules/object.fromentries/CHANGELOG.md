2.0.4 / 2021-02-21
=================
  * [readme] fix repo URLs; remove travis badge
  * [meta] do not publish github action workflow files
  * [Deps] update `call-bind`, `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `has-strict-mode`, `tape`
  * [actions] update workflows

2.0.3 / 2020-11-26
=================
  * [Deps] update `es-abstract`; remove `function-bind`; use `call-bind` where applicable
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `tape`; add `aud`, `safe-publish-latest`
  * [actions] add "Allow Edits" workflow
  * [actions] switch Automatic Rebase workflow to `pull_request_target` event
  * [Tests] migrate tests to Github Actions
  * [Tests] run `nyc` on all tests
  * [Tests] add `implementation` test; run `es-shim-api` in postlint; use `tape` runner
  * [Tests] only audit prod deps

2.0.2 / 2019-12-12
=================
  * [Refactor] use split-up `es-abstract` (63% bundle size decrease)
  * [readme] remove testling
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`
  * [meta] add `funding` field
  * [Tests] use shared travis-ci configs
  * [actions] add automatic rebasing / merge commit blocking

2.0.1 / 2019-10-03
=================
  * [Fix] do not mutate `Object.fromEntries` when already present
  * [Deps] update `define-properties`, `es-abstract`, `has`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `covert`, `tape`
  * [Tests] up to `node` `v12.9`, `v11.15`, `v10.16`, `v9.11`, `v8.16`, `v6.17`, `v4.9`
  * [Tests] use `npx aud` instead of `nsp` or `npm audit` with hoops

2.0.0 / 2018-08-09
=================
  * [Breaking] throw when `iterable` is nullish
  * [Docs] Fix link to proposed spec

1.0.0 / 2018-03-21
=================
  * v1.0.0
