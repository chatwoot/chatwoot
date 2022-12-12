# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.4](https://github.com/es-shims/Symbol.prototype.description/compare/v1.0.3...v1.0.4) - 2021-02-21

### Commits

- [meta] do not publish github action workflow files [`c95b746`](https://github.com/es-shims/Symbol.prototype.description/commit/c95b746be2b15fee94090a65431623a45e79d96a)
- [readme] fix repo URLs; remove travis badge [`91f9c78`](https://github.com/es-shims/Symbol.prototype.description/commit/91f9c781ef4873a4c5bb08d5f7d2f8187045660e)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `has-strict-mode`, `reflect-ownkeys`, `tape` [`c14b5eb`](https://github.com/es-shims/Symbol.prototype.description/commit/c14b5ebd86e715d04e6253edf5706c957869bea2)
- [actions] update workflows [`828203c`](https://github.com/es-shims/Symbol.prototype.description/commit/828203cbc4ab4d9ac2bab5e104c916caf737cd97)
- [Deps] update `call-bind`, `es-abstract`, `object.getownpropertydescriptors` [`a5816d2`](https://github.com/es-shims/Symbol.prototype.description/commit/a5816d2e08ec046462591ce23604036f29e2b1b1)
- [Tests] increase coverage [`73d9e5b`](https://github.com/es-shims/Symbol.prototype.description/commit/73d9e5b60238f39f3f17ea45e3e396af518aa36e)

## [v1.0.3](https://github.com/es-shims/Symbol.prototype.description/compare/v1.0.2...v1.0.3) - 2020-11-23

### Fixed

- [Fix] ensure `Symbol` shim retains the same own properties as the original [`#13`](https://github.com/es-shims/Symbol.prototype.description/issues/13)

### Commits

- [Tests] migrate tests to Github Actions [`e9a2754`](https://github.com/es-shims/Symbol.prototype.description/commit/e9a2754a441c3c6e66dc57563501d237527e671e)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `auto-changelog`, `tape` [`d5cff61`](https://github.com/es-shims/Symbol.prototype.description/commit/d5cff61d53786139227575115c9cc0260451a24e)
- [Tests] add `implementation` test; use `tape` runner [`9a0afe5`](https://github.com/es-shims/Symbol.prototype.description/commit/9a0afe50a9f1183f5ca8e6e3435671a1f0f2b453)
- [Tests] run `nyc` on all tests [`a33e2d6`](https://github.com/es-shims/Symbol.prototype.description/commit/a33e2d62d6a51321dde40d05dcf582d1a28d47cd)
- [actions] add "Allow Edits" workflow [`b5f001e`](https://github.com/es-shims/Symbol.prototype.description/commit/b5f001eebd5149c2fa8a6397750994635cb7b83a)
- [Deps] update `es-abstract`; use `call-bind` where applicable [`fe59e37`](https://github.com/es-shims/Symbol.prototype.description/commit/fe59e375a8d9906b415a504c53a17582eefef5be)
- [Dev Deps] update `eslint`, `aud`, `auto-changelog` [`ee0c319`](https://github.com/es-shims/Symbol.prototype.description/commit/ee0c319d9b46d86666d8959487691f0d125dc5e5)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `tape` [`66d8264`](https://github.com/es-shims/Symbol.prototype.description/commit/66d826443587a4fbb232edd658473f48eaa618cc)
- [Deps] update `es-abstract` [`fc88f15`](https://github.com/es-shims/Symbol.prototype.description/commit/fc88f154a4a980c5e989016b7d0dc1b1460509e4)
- [Tests] fix failing tests [`86825ca`](https://github.com/es-shims/Symbol.prototype.description/commit/86825ca79b93439a576902cf2e40a4f7b4a7e5ff)
- [Dev Deps] update `auto-changelog`; add `aud` [`94de63f`](https://github.com/es-shims/Symbol.prototype.description/commit/94de63f6722338f98b5e54dfc9774d6f9ac65eb0)
- [meta] fix auto-changelog npmrc settings [`4c09543`](https://github.com/es-shims/Symbol.prototype.description/commit/4c09543bbcb28f331d60458021c5bae5bfab68b9)
- [Deps] update `es-abstract` [`0a85899`](https://github.com/es-shims/Symbol.prototype.description/commit/0a85899de2faab0c73ec476bd087e0bf079b3e35)
- [actions] switch Automatic Rebase workflow to `pull_request_target` event [`cf95a5c`](https://github.com/es-shims/Symbol.prototype.description/commit/cf95a5c72a752f9ac828cc8e280a14ae4b0a39b1)
- [Dev Deps] update `auto-changelog` [`38e903a`](https://github.com/es-shims/Symbol.prototype.description/commit/38e903a9fb35eddde3730683e7d0af29dc1fdb87)
- [Tests] only audit prod deps [`66fc2ad`](https://github.com/es-shims/Symbol.prototype.description/commit/66fc2ad1fab791162d2a6e3d9091e1bf28295114)
- [Deps] update `es-abstract` [`4d9967e`](https://github.com/es-shims/Symbol.prototype.description/commit/4d9967e8beb5b01a07499162f34fad6122ffd6b2)
- [Dev Deps] update `tape` [`749632c`](https://github.com/es-shims/Symbol.prototype.description/commit/749632c4c79386dc9feb7cdc12d6a9e7bbc639cf)

## [v1.0.2](https://github.com/es-shims/Symbol.prototype.description/compare/v1.0.1...v1.0.2) - 2019-12-13

### Commits

- [Tests] use shared travis-ci configs [`0dbbf50`](https://github.com/es-shims/Symbol.prototype.description/commit/0dbbf506744c6c0f3f1ec4535ece7c14e6990f47)
- [actions] add automatic rebasing / merge commit blocking [`82a587a`](https://github.com/es-shims/Symbol.prototype.description/commit/82a587af8b44dd20871cf48251dfe48ce02e14db)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `auto-changelog`, `safe-publish-latest` [`61fdc06`](https://github.com/es-shims/Symbol.prototype.description/commit/61fdc06365fd740c6c13a3289e02f253893108dc)
- [Deps] update `es-abstract`, `has-symbols` [`2e1377f`](https://github.com/es-shims/Symbol.prototype.description/commit/2e1377f6993581b6fcd7e2d75d1fe1b1a28dcead)
- [readme] remove testling [`bd843f6`](https://github.com/es-shims/Symbol.prototype.description/commit/bd843f699cc8db82b52f70495e1c95146cf5806a)
- [meta] add `funding` field [`057b03f`](https://github.com/es-shims/Symbol.prototype.description/commit/057b03ff30a58e35b6f42a2694195e27f6145fb3)

## [v1.0.1](https://github.com/es-shims/Symbol.prototype.description/compare/v1.0.0...v1.0.1) - 2019-10-18

### Fixed

- [Fix] `polyfill`: fix always-true logic [`#3`](https://github.com/es-shims/Symbol.prototype.description/issues/3)

### Commits

- [Tests] up to `node` `v12.12`, `v11.15`, `v10.16`, `v8.16`, `v6.17` [`66278dd`](https://github.com/es-shims/Symbol.prototype.description/commit/66278dd1d06771eb13a9b02903740bb751e0f39d)
- [Tests] up to `node` `v10.4`, `v9.11`, `v8.11`, `v6.14`, `v4.9` [`8bdca03`](https://github.com/es-shims/Symbol.prototype.description/commit/8bdca03cb3296b0f2a73815255dd1d2cde7114cd)
- [Refactor] use `getSymbolDescription` and `getInferredName` helpers from `es-abstract` [`d6b2c51`](https://github.com/es-shims/Symbol.prototype.description/commit/d6b2c51d2f7d1489cef94705be0c9ced8becd779)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `tape`; add `safe-publish-latest` [`ea4841b`](https://github.com/es-shims/Symbol.prototype.description/commit/ea4841b269810db4d788ff1913c47494a3bab6de)
- [meta] add `auto-changelog` [`415dcaf`](https://github.com/es-shims/Symbol.prototype.description/commit/415dcafd2f95836497fdf2e4336ebd2d5319434c)
- [Dev Deps] update `eslint`, `nsp`, `tape` [`25d2c71`](https://github.com/es-shims/Symbol.prototype.description/commit/25d2c71074f7f8e7844196c00df908528a6dc3e9)
- [Tests] use `npx aud` instead of `nsp` or `npm audit` with hoops [`32f79e9`](https://github.com/es-shims/Symbol.prototype.description/commit/32f79e9e1eeacb14cb968113c16becdf73477ba3)

## v1.0.0 - 2018-01-23

### Merged

- [Fix] use function name inference and computed properties to distinguish `Symbol()` from `Symbol(‘’)`, when available [`#2`](https://github.com/es-shims/Symbol.prototype.description/pull/2)

### Fixed

- [Fix] use function name inference and computed properties to distinguish `Symbol()` from `Symbol(‘’)`, when available. [`#1`](https://github.com/es-shims/Symbol.prototype.description/issues/1)

### Commits

- [Tests] add travis-ci and `npm run security` [`b889123`](https://github.com/es-shims/Symbol.prototype.description/commit/b8891233987b6d3b3805d25071f7353d30275f41)
- Implementation. [`5bafd04`](https://github.com/es-shims/Symbol.prototype.description/commit/5bafd04c3efdb20feb62a9512cc74572ce44fe72)
- Tests [`96aee94`](https://github.com/es-shims/Symbol.prototype.description/commit/96aee940ec05d288462e109f0e531b128963d262)
- Initial commit [`fff1a67`](https://github.com/es-shims/Symbol.prototype.description/commit/fff1a671c95a111fe782014f2be56c3ee9567fa8)
- Read me [`3d21280`](https://github.com/es-shims/Symbol.prototype.description/commit/3d21280e12c8c24c2ba059b9bd3224bce5ee3439)
- [Tests] up to `node` `v9.2`, `v8.9`, `v6.12`; use `nvm install-latest-npm`; pin included builds to LTSr [`c6d1807`](https://github.com/es-shims/Symbol.prototype.description/commit/c6d18077067a5fc2835a0d38bbc90b28fb98e8e4)
- [Tests] add `npm run lint` [`1e4562c`](https://github.com/es-shims/Symbol.prototype.description/commit/1e4562c1f13aa0d9a7fc08f1801d47f13ba2d644)
- package.json [`6d53036`](https://github.com/es-shims/Symbol.prototype.description/commit/6d530361a2c930490d0e6799992c0639b01b95c8)
- [Fix] only shim global Symbol when needed [`10f4fa2`](https://github.com/es-shims/Symbol.prototype.description/commit/10f4fa2f8d6102ef8f5a07b23438d6a793c65c6b)
- Flesh out es-shim-api requirements. [`6bf128a`](https://github.com/es-shims/Symbol.prototype.description/commit/6bf128a0e383d6dc1acbc33e394644dca7e3e4dc)
- [Dev Deps] update `@es-shims/api`, `@ljharb/eslint-config`, `eslint`, `nsp`, `tape` [`9651fb6`](https://github.com/es-shims/Symbol.prototype.description/commit/9651fb616ca37ae24f85ebc9c4bd57bf6f722f24)
- Rename and move the repo. [`e136d90`](https://github.com/es-shims/Symbol.prototype.description/commit/e136d90b2213102cb4b60c00039b394d0ebba33d)
- Only apps should have lockfiles. [`74239df`](https://github.com/es-shims/Symbol.prototype.description/commit/74239df051bb8bf488aa08b16be04a7e672f4d74)
- [Dev Deps] update `@es-shims/api`, `eslint` [`e3c8d64`](https://github.com/es-shims/Symbol.prototype.description/commit/e3c8d64ea4016682298c8ac97a2726e9b61f77b0)
