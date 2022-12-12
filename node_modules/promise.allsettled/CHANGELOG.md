# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.4](https://github.com/es-shims/Promise.allSettled/compare/v1.0.3...v1.0.4) - 2021-01-20

### Commits

- [Fix] properly call-bind `Promise.all` and `Promise.reject` [`1f90b0e`](https://github.com/es-shims/Promise.allSettled/commit/1f90b0efc3208486709391ffe1dd16b79ca214d4)

## [v1.0.3](https://github.com/es-shims/Promise.allSettled/compare/v1.0.2...v1.0.3) - 2021-01-20

### Commits

- [Tests] migrate tests to Github Actions [`a066121`](https://github.com/es-shims/Promise.allSettled/commit/a0661218570a7815a5328e36ee5b2378e16820d2)
- [meta] use `auto-changelog` [`7b27067`](https://github.com/es-shims/Promise.allSettled/commit/7b270677baf74ddfedcf4869b869b44e89d30a28)
- [meta] do not publish github action workflow files [`aae74fd`](https://github.com/es-shims/Promise.allSettled/commit/aae74fd7c0a1abf9a9609d7fcd9755b3a8d2a364)
- [Tests] run `nyc` on all tests; use `tape` runner; add implementation tests [`fbd8198`](https://github.com/es-shims/Promise.allSettled/commit/fbd81984b88abb6fc2089e15090a4861f24642a8)
- [Deps] update `array.prototype.map`, `es-abstract`; add `call-bind` [`424f760`](https://github.com/es-shims/Promise.allSettled/commit/424f7606f6ec04aefd36e61dcd83ba1a96d04bbb)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `aud`, `call-bind`, `functions-have-names`, `tape` [`47c5df1`](https://github.com/es-shims/Promise.allSettled/commit/47c5df1ddb55ae59bf57dabf62b6030a92a2adc4)
- [actions] add "Allow Edits" workflow [`d931b6c`](https://github.com/es-shims/Promise.allSettled/commit/d931b6c00bab078e5562b7392374d48de9ffc1cd)
- [Refactor] use es-abstract’s `callBind` instead of `function-bind` directly [`09c25e8`](https://github.com/es-shims/Promise.allSettled/commit/09c25e81af2050ade7d4be35a522753422e7843a)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `functions-have-names`, `tape`; add `aud` [`03aedb0`](https://github.com/es-shims/Promise.allSettled/commit/03aedb0e6365f0ea6f76a373148f3e1ed2c6e8a2)
- [Deps] update `array.prototype.map`, `es-abstract`, `iterate-value` [`f28e1aa`](https://github.com/es-shims/Promise.allSettled/commit/f28e1aa6a83d201de8a81862890c713f60c1680c)
- [Tests] test in older nodes that 3e873f7 now supports [`5feffee`](https://github.com/es-shims/Promise.allSettled/commit/5feffeecb8d9a535cd24f6563023f841a455ebee)
- [actions] switch Automatic Rebase workflow to `pull_request_target` event [`b30a268`](https://github.com/es-shims/Promise.allSettled/commit/b30a2686337efa13454ce754c32287b4aec11bdf)
- [meta] only run `aud` on prod deps [`bf97e5f`](https://github.com/es-shims/Promise.allSettled/commit/bf97e5fad6e5ab554ec8780d1a5f0d955dbce4e4)
- [Deps] update `es-abstract` [`6a6ae55`](https://github.com/es-shims/Promise.allSettled/commit/6a6ae556058aba575b8cd335618f846b3c1fe8c8)
- [Deps] update `iterate-value` [`13507f3`](https://github.com/es-shims/Promise.allSettled/commit/13507f3b7b87de8b26ea3cd0d40949c8c9747f77)

## [v1.0.2](https://github.com/es-shims/Promise.allSettled/compare/v1.0.1...v1.0.2) - 2019-12-13

### Commits

- [Tests] use shared travis-ci configs [`3a5a379`](https://github.com/es-shims/Promise.allSettled/commit/3a5a379ad6da1a7fe988e8e1eb708be4f7abb008)
- [meta] move repo to es-shims org [`240a87c`](https://github.com/es-shims/Promise.allSettled/commit/240a87c480ab7a3119c192476c6317d5f5ce59e2)
- [Fix] no longer require `Array.from`; works in older envs [`3e873f7`](https://github.com/es-shims/Promise.allSettled/commit/3e873f78e15b275d6e10db12ac6cde1716be2f60)
- [actions] add automatic rebasing / merge commit blocking [`4ab52ef`](https://github.com/es-shims/Promise.allSettled/commit/4ab52efa9466c535cd15a1bcb54b3250c989b174)
- [Tests] skip "`undefined` receiver" test [`9612591`](https://github.com/es-shims/Promise.allSettled/commit/96125915f35386940fce8eb52331346ffe3b45d6)
- [Refactor] use split-up `es-abstract` (44% bundle size decrease) [`ed49521`](https://github.com/es-shims/Promise.allSettled/commit/ed49521b2f03a4a63ef0e15a017dc973217d03bb)
- [Dev Deps] update `eslint`, `@ljharb/eslint-config`, `functions-have-names`, `safe-publish-latest` [`7f97708`](https://github.com/es-shims/Promise.allSettled/commit/7f977086e2f685d29d1ae821b4083c9b4e1256d8)
- [Tests] temporarily comment out failing test in node 12+ [`275507f`](https://github.com/es-shims/Promise.allSettled/commit/275507f89a3c672acd867cbe7432c0c08f0abef9)
- [meta] add `funding` field [`96b75aa`](https://github.com/es-shims/Promise.allSettled/commit/96b75aab5a8bb3586303baafe462b4b4114fb2da)
- [Tests] suppress unhandled rejection warnings [`8ee2263`](https://github.com/es-shims/Promise.allSettled/commit/8ee226357bb92417ac5d596abaa86cc600c97aa1)
- [Tests] use `functions-have-names` [`43ed9ca`](https://github.com/es-shims/Promise.allSettled/commit/43ed9ca63e41795c8f96764da33dee3d11fa533a)
- [Dev Deps] update `tape` [`df12368`](https://github.com/es-shims/Promise.allSettled/commit/df123681fd26b8b18d0f89aa56e57d927fd63bc6)

## [v1.0.1](https://github.com/es-shims/Promise.allSettled/compare/v1.0.0...v1.0.1) - 2019-05-06

### Fixed

- [Fix] when a promise has a poisoned `.then` method, reject the overarching promise [`#1`](https://github.com/es-shims/Promise.allSettled/issues/1)

### Commits

- [Tests] up to `node` `v12.1`, `v11.15` [`4d76716`](https://github.com/es-shims/Promise.allSettled/commit/4d76716fc0a002af216962d177bd197688b27e1f)
- [Dev Deps] update `eslint` [`fc23682`](https://github.com/es-shims/Promise.allSettled/commit/fc23682b807812ab5288d9a100b60f735f41f089)

## v1.0.0 - 2019-03-27

### Commits

- [Tests] add `travis-ci` [`0201190`](https://github.com/es-shims/Promise.allSettled/commit/02011908060b52218b21b04c88d85fb521f09c93)
- Initial tests [`1a519d1`](https://github.com/es-shims/Promise.allSettled/commit/1a519d1f7ae673a4b109baa81fa02fdd95bd5788)
- Initial implementation [`562952d`](https://github.com/es-shims/Promise.allSettled/commit/562952d201c3d0c43b8549c6399cf56555125983)
- Initial commit [`cee4c56`](https://github.com/es-shims/Promise.allSettled/commit/cee4c561deba91556b697d329149bfd9c32c7927)
- readme [`60f133f`](https://github.com/es-shims/Promise.allSettled/commit/60f133f4b11d15b479b0c8d5de634005e4992ede)
- package.json [`6b9cc53`](https://github.com/es-shims/Promise.allSettled/commit/6b9cc53e884da0847bebea738bfbb93d2993f060)
- Require `Array.from`; fix tests [`53ff455`](https://github.com/es-shims/Promise.allSettled/commit/53ff455a67d06f86b250e4584d3de417c1937966)
- [Tests] add `npm run lint` [`d61e9f7`](https://github.com/es-shims/Promise.allSettled/commit/d61e9f79ef7df73eb55caa95f552aea09559574e)
- Only apps should have lockfiles [`cb2ea36`](https://github.com/es-shims/Promise.allSettled/commit/cb2ea3689931a5a4502e5f771347cff6919a0305)
- [Tests] use `npx aud` for posttest, and `safe-publish-latest` for prepublish [`68995cd`](https://github.com/es-shims/Promise.allSettled/commit/68995cdf499a3d6e124c76e4e31c1daa55387c46)
