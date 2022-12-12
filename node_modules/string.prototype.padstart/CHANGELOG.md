3.1.2 / 2021-02-20
=================
  * [meta] do not publish github action workflow files
  * [Deps] update `call-bind`, `es-abstract`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `functions-have-names`, `has-strict-mode`, `tape`
  * [actions] update workflows
  * [Tests] increase coverage

3.1.1 / 2020-11-21
=================
  * [Deps] update `es-abstract`; use `call-bind` where applicable
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `functions-have-names`, `tape`; add `aud`
  * [actions] add "Allow Edits" workflow
  * [actions] switch Automatic Rebase workflow to `pull_request_target` event
  * [meta] gitignore nyc output
  * [meta] add `safe-publish-latest`
  * [Tests] migrate tests to Github Actions
  * [Tests] run `nyc` on all tests
  * [Tests] add `implementation` test; run `es-shim-api` in postlint; use `tape` runner
  * [Tests] update `function-bind`

3.1.0 / 2019-12-14
=================
  * [New] add `auto` entry point
  * [Refactor] use split-up `es-abstract` (77% bundle size decrease)
  * [readme] remove testling
  * [readme] Fixed syntax error in README (#12)
  * [readme] Stage 4
  * [Deps] update `define-properties`, `es-abstract`, `function-bind`
  * [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `functions-have-names`, `covert`, `tape`, `@es-shims/api`
  * [meta] add `funding` field
  * [meta] Only apps should have lockfiles.
  * [Tests] use pretest/posttest for linting/security
  * [Tests] use `functions-have-names`
  * [Tests] use `npx aud` instead of `nsp` or `npm audit` with hoops
  * [Tests] remove `jscs`
  * [Tests] use shared travis-ci configs
  * [actions] add automatic rebasing / merge commit blocking

3.0.0 / 2015-11-17
=================
  * Renamed to `padStart`/`padEnd` per November 2015 TC39 meeting.

2.0.0 / 2015-09-25
=================
  * [Breaking] Take the *first* part of the `fillStr` when truncating (#1)
  * Implement the [es-shim API](es-shims/api)
  * [Tests] up to `io.js` `v3.3`, `node` `v4.1`
  * [Deps] update `es-abstract`
  * [Dev Deps] Update `tape`, `jscs`, `eslint`, `@ljharb/eslint-config`, `nsp`
  * [Refactor] Remove redundant `max` operation, per https://github.com/ljharb/proposal-string-pad-left-right/pull/2

1.0.0 / 2015-07-30
=================
  * v1.0.0
