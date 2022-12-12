2.1.2 / 2021-02-20
=================
  * [Deps] update `call-bind`, `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `functions-have-names`, `has-strict-mode`, `tape`
  * [meta] do not publish github action workflow files
  * [meta] gitignore coverage output
  * [actions] update workflows

2.1.1 / 2020-11-26
=================
  * [Fix] do not mutate the native function when present
  * [Deps] update `es-abstract`; use `call-bind` where applicable
  * [meta] remove unused Makefile and associated utilities
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `tape`, `functions-have-names`; add `aud`
  * [actions] add Require Allow Edits workflow
  * [actions] switch Automatic Rebase workflow to `pull_request_target` event
  * [Tests] migrate tests to Github Actions
  * [Tests] run `nyc` on all tests
  * [Tests] add `implementation` test; run `es-shim-api` in postlint; use `tape` runner
  * [Tests] only audit prod deps

2.1.0 / 2019-12-12
=================
  * [New] add auto entry point
  * [Refactor] use split-up `es-abstract` (78% bundle size decrease)
  * [readme] fix repo URLs, remove testling
  * [Docs] Fix formatting in the README (#30)
  * [Deps] update `define-properties`, `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `functions-have-names`, `covert`, `replace`, `semver`, `tape`, `@es-shims/api`; add `safe-publish-latest`
  * [meta] add `funding` field
  * [meta] Only apps should have lockfiles.
  * [Tests] use shared travis-ci configs
  * [Tests] use `functions-have-names`
  * [Tests] use `npx aud` instead of `nsp` or `npm audit` with hoops
  * [Tests] remove `jscs`
  * [actions] add automatic rebasing / merge commit blocking

2.0.3 / 2016-07-26
=================
  * [Fix] Update implementation to not return `undefined` descriptors
  * [Deps] update `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `@es-shims/api`, `jscs`, `nsp`, `tape`, `semver`
  * [Dev Deps] remove unused eccheck script + dep
  * [Tests] up to `node` `v6.3`, `v5.12`, `v4.4`
  * [Tests] use pretest/posttest for linting/security
  * Update to stage 4

2.0.2 / 2016-01-27
=================
  * [Fix] ensure that `Object.getOwnPropertyDescriptors` does not fail when `Object.prototype` has a poisoned setter (#1, #2)

2.0.1 / 2016-01-27
=================
  * [Deps] move `@es-shims/api` to dev deps

2.0.0 / 2016-01-27
=================
  * [Breaking] implement the es-shims API
  * [Deps] update `define-properties`, `es-abstract`
  * [Dev Deps] update `tape`, `jscs`, `nsp`, `eslint`, `@ljharb/eslint-config`, `semver`
  * [Tests] fix npm upgrades in older nodes
  * [Tests] up to `node` `v5.5`
  * [Docs] Switch from vb.teelaun.ch to versionbadg.es for the npm version badge SVG

1.0.4 / 2015-07-20
=================
  * [Tests] Test on `io.js` `v2.4`
  * [Deps, Dev Deps] Update `define-properties`, `tape`, `eslint`, `semver`

1.0.3 / 2015-06-28
=================
  * Increase robustness by caching `Array#{concat, reduce}`
  * [Deps] Update `define_properties`
  * [Dev Deps] Update `eslint`, `semver`, `nsp`
  * [Tests] Test up to `io.js` `v2.3`

1.0.2 / 2015-05-23
=================
  * Update `es-abstract`, `tape`, `eslint`, `jscs`, `semver`, `covert`
  * Test up to `io.js` `v2.0`

1.0.1 / 2015-03-20
=================
  * Update `es-abstract`, `editorconfig-tools`, `nsp`, `eslint`, `semver`, `replace`

1.0.0 / 2015-02-17
=================
  * v1.0.0
