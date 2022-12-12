## [3.5.2](https://github.com/vuejs/vue-router/compare/v3.5.1...v3.5.2) (2021-06-21)

### Bug Fixes

- **history:** stricter check of base in HTML5 ([#3556](https://github.com/vuejs/vue-router/issues/3556)) ([11dd184](https://github.com/vuejs/vue-router/commit/11dd184dc6a872c6399977fa4b7c259225ce4834))
- **types:** added missing router.match ([#3554](https://github.com/vuejs/vue-router/issues/3554)) ([394a3b6](https://github.com/vuejs/vue-router/commit/394a3b6cce5e395ae4ccf3e2efb0c115d492978c))

## [3.5.1](https://github.com/vuejs/vue-router/compare/v3.5.0...v3.5.1) (2021-01-26)

### Bug Fixes

- **warn:** only warn if "tag" or "event" is used ([#3458](https://github.com/vuejs/vue-router/issues/3458)) ([b7a31b9](https://github.com/vuejs/vue-router/commit/b7a31b9)), closes [#3457](https://github.com/vuejs/vue-router/issues/3457)

# [3.5.0](https://github.com/vuejs/vue-router/compare/v3.4.9...v3.5.0) (2021-01-25)

### Features

- **link:** exact-path prop ([825328e](https://github.com/vuejs/vue-router/commit/825328e)), closes [#2040](https://github.com/vuejs/vue-router/issues/2040)
- **warn:** warn deprecated addRoutes ([2e41445](https://github.com/vuejs/vue-router/commit/2e41445))
- expose START_LOCATION ([53b68dd](https://github.com/vuejs/vue-router/commit/53b68dd)), closes [#2718](https://github.com/vuejs/vue-router/issues/2718)
- **link:** deprecate v-slot without custom prop ([ceeda4c](https://github.com/vuejs/vue-router/commit/ceeda4c))
- **link:** warn deprecated props ([d2cb951](https://github.com/vuejs/vue-router/commit/d2cb951))
- **router:** add getRoutes ([6bc30aa](https://github.com/vuejs/vue-router/commit/6bc30aa))
- **types:** add types for getRoutes addRoute ([fb9bb60](https://github.com/vuejs/vue-router/commit/fb9bb60))
- addRoute as nested route ([ca80c44](https://github.com/vuejs/vue-router/commit/ca80c44)), closes [#1156](https://github.com/vuejs/vue-router/issues/1156)

## [3.4.9](https://github.com/vuejs/vue-router/compare/v3.4.8...v3.4.9) (2020-11-05)

### Bug Fixes

- **encoding:** decode params ([#3350](https://github.com/vuejs/vue-router/issues/3350)) ([63c749c](https://github.com/vuejs/vue-router/commit/63c749c))

## [3.4.8](https://github.com/vuejs/vue-router/compare/v3.4.7...v3.4.8) (2020-10-26)

### Features

- **scroll:** add behavior support on scrollBehavior ([#3351](https://github.com/vuejs/vue-router/issues/3351)) ([4e0b3e0](https://github.com/vuejs/vue-router/commit/4e0b3e0))

## [3.4.7](https://github.com/vuejs/vue-router/compare/v3.4.6...v3.4.7) (2020-10-16)

### Bug Fixes

- **matcher:** should try catch decode only ([1f32f03](https://github.com/vuejs/vue-router/commit/1f32f03))
- **query:** check existing keys ([4b926e3](https://github.com/vuejs/vue-router/commit/4b926e3)), closes [#3341](https://github.com/vuejs/vue-router/issues/3341)

## [3.4.6](https://github.com/vuejs/vue-router/compare/v3.4.5...v3.4.6) (2020-10-07)

### Bug Fixes

- **encoding:** try catch decodes ([607ce2d](https://github.com/vuejs/vue-router/commit/607ce2d))
- **ssr:** memory leak in poll method ([#2875](https://github.com/vuejs/vue-router/issues/2875)) ([7693eb5](https://github.com/vuejs/vue-router/commit/7693eb5))
- remove duplicated decodeURIComponent ([#3323](https://github.com/vuejs/vue-router/issues/3323)) ([560d11d](https://github.com/vuejs/vue-router/commit/560d11d))

## [3.4.5](https://github.com/vuejs/vue-router/compare/v3.4.4...v3.4.5) (2020-09-26)

### Bug Fixes

- **history:** do not call onReady on initial redirection ([a1a290e](https://github.com/vuejs/vue-router/commit/a1a290e)), closes [#3331](https://github.com/vuejs/vue-router/issues/3331)

## [3.4.4](https://github.com/vuejs/vue-router/compare/v3.4.3...v3.4.4) (2020-09-24)

### Bug Fixes

- **abstract:** call afterHooks with go ([4da7021](https://github.com/vuejs/vue-router/commit/4da7021)), closes [#3250](https://github.com/vuejs/vue-router/issues/3250)
- **history:** mark redundant navigation as pending ([893d86b](https://github.com/vuejs/vue-router/commit/893d86b)), closes [#3133](https://github.com/vuejs/vue-router/issues/3133)
- **types:** add missing NavigationFailure types ([fda7067](https://github.com/vuejs/vue-router/commit/fda7067)), closes [#3293](https://github.com/vuejs/vue-router/issues/3293)
- **types:** fix VueRouter.NavigationFailureType ([ecc8e27](https://github.com/vuejs/vue-router/commit/ecc8e27))

### Features

- **history:** Reset history.current when all apps are destroyed ([#3298](https://github.com/vuejs/vue-router/issues/3298)) ([c69ff7b](https://github.com/vuejs/vue-router/commit/c69ff7b))

## [3.4.3](https://github.com/vuejs/vue-router/compare/v3.4.2...v3.4.3) (2020-08-11)

- Revert 4fbaa9f7880276e661227442ef5923131a589210: "fix: keep repeated params in query/hash relative locations" Closes #3289

## [3.4.2](https://github.com/vuejs/vue-router/compare/v3.4.1...v3.4.2) (2020-08-07)

### Bug Fixes

- **query:** leave object as is ([7b3328d](https://github.com/vuejs/vue-router/commit/7b3328d)), closes [#3282](https://github.com/vuejs/vue-router/issues/3282)
- keep repeated params in query/hash relative locations ([4fbaa9f](https://github.com/vuejs/vue-router/commit/4fbaa9f))

## [3.4.1](https://github.com/vuejs/vue-router/compare/v3.4.0...v3.4.1) (2020-08-06)

### Bug Fixes

- **query:** remove undefined values ([b952573](https://github.com/vuejs/vue-router/commit/b952573)), closes [#3276](https://github.com/vuejs/vue-router/issues/3276)
- **router:** properly check null and undefined in isSameRoute ([d6546d9](https://github.com/vuejs/vue-router/commit/d6546d9))

# [3.4.0](https://github.com/vuejs/vue-router/compare/v3.3.4...v3.4.0) (2020-08-05)

### Bug Fixes

- **query:** cast query values to strings (fix [#2131](https://github.com/vuejs/vue-router/issues/2131)) ([#3232](https://github.com/vuejs/vue-router/issues/3232)) ([f0d9c2d](https://github.com/vuejs/vue-router/commit/f0d9c2d))
- **scroll:** run scrollBehavior on initial load (fix [#3196](https://github.com/vuejs/vue-router/issues/3196)) ([#3199](https://github.com/vuejs/vue-router/issues/3199)) ([84398ae](https://github.com/vuejs/vue-router/commit/84398ae))
- **types:** add missing `options` property type ([#3248](https://github.com/vuejs/vue-router/issues/3248)) ([83920c9](https://github.com/vuejs/vue-router/commit/83920c9))

### Features

- add vetur tags and attributes ([bf1e1bd](https://github.com/vuejs/vue-router/commit/bf1e1bd))
- **errors:** capture errors thrown in redirect callback in onError ([#3251](https://github.com/vuejs/vue-router/issues/3251)) ([40e4df7](https://github.com/vuejs/vue-router/commit/40e4df7)), closes [#3201](https://github.com/vuejs/vue-router/issues/3201) [#3201](https://github.com/vuejs/vue-router/issues/3201) [#3201](https://github.com/vuejs/vue-router/issues/3201)
- **errors:** expose `isNavigationFailure` ([8d92dc0](https://github.com/vuejs/vue-router/commit/8d92dc0))
- **errors:** NavigationDuplicated name for backwards compatibility ([b854a20](https://github.com/vuejs/vue-router/commit/b854a20))

## [3.3.4](https://github.com/vuejs/vue-router/compare/v3.3.3...v3.3.4) (2020-06-13)

### Bug Fixes

- **matcher:** navigate to same as current location ([62598b9](https://github.com/vuejs/vue-router/commit/62598b9)), closes [#3216](https://github.com/vuejs/vue-router/issues/3216)
- **types:** missing children ([c1df447](https://github.com/vuejs/vue-router/commit/c1df447)), closes [#3230](https://github.com/vuejs/vue-router/issues/3230)

## [3.3.3](https://github.com/vuejs/vue-router/compare/v3.3.2...v3.3.3) (2020-06-12)

### Bug Fixes

- **history:** initial redirect call onReady's onSuccess ([4d484bf](https://github.com/vuejs/vue-router/commit/4d484bf)), closes [#3225](https://github.com/vuejs/vue-router/issues/3225)
- update ja docs ([#3214](https://github.com/vuejs/vue-router/issues/3214)) ([c05f741](https://github.com/vuejs/vue-router/commit/c05f741))

### Features

- better wording for navigation redirected failure ([1f3aea6](https://github.com/vuejs/vue-router/commit/1f3aea6))
- **types:** RouterConfig for multiple components ([#3217](https://github.com/vuejs/vue-router/issues/3217)) ([#3218](https://github.com/vuejs/vue-router/issues/3218)) ([dab86c5](https://github.com/vuejs/vue-router/commit/dab86c5))

## [3.3.2](https://github.com/vuejs/vue-router/compare/v3.3.1...v3.3.2) (2020-05-29)

### Bug Fixes

- **errors:** NavigationCanceled with async components ([#3211](https://github.com/vuejs/vue-router/issues/3211)) ([be39ca3](https://github.com/vuejs/vue-router/commit/be39ca3))
- remove error.stack modification ([#3212](https://github.com/vuejs/vue-router/issues/3212)) ([a0075ed](https://github.com/vuejs/vue-router/commit/a0075ed))

## [3.3.1](https://github.com/vuejs/vue-router/compare/v3.3.0...v3.3.1) (2020-05-27)

### Bug Fixes

- **errors:** avoid unnecessary log of errors ([2c77247](https://github.com/vuejs/vue-router/commit/2c77247))

# [3.3.0](https://github.com/vuejs/vue-router/compare/v3.2.0...v3.3.0) (2020-05-27)

### Features

- **errors:** create router errors ([#3047](https://github.com/vuejs/vue-router/issues/3047)) ([4c727f9](https://github.com/vuejs/vue-router/commit/4c727f9))
- **history:** Remove event listeners when all apps are destroyed. ([#3172](https://github.com/vuejs/vue-router/issues/3172)) ([4c81be8](https://github.com/vuejs/vue-router/commit/4c81be8)), closes [#3152](https://github.com/vuejs/vue-router/issues/3152) [#2341](https://github.com/vuejs/vue-router/issues/2341)
- **url:** call afterEach hooks after url is ensured ([#2292](https://github.com/vuejs/vue-router/issues/2292)) ([1575a18](https://github.com/vuejs/vue-router/commit/1575a18)), closes [#2079](https://github.com/vuejs/vue-router/issues/2079)

# [3.2.0](https://github.com/vuejs/vue-router/compare/v3.1.6...v3.2.0) (2020-05-19)

### Bug Fixes

- **html5:** make base case insensitive ([04a2143](https://github.com/vuejs/vue-router/commit/04a2143)), closes [#2154](https://github.com/vuejs/vue-router/issues/2154)
- check for pushState being a function ([bc41f67](https://github.com/vuejs/vue-router/commit/bc41f67)), closes [#3154](https://github.com/vuejs/vue-router/issues/3154)

### Features

- **link:** add aria-current to active links (close [#2116](https://github.com/vuejs/vue-router/issues/2116)) ([#3073](https://github.com/vuejs/vue-router/issues/3073)) ([6ec0ee5](https://github.com/vuejs/vue-router/commit/6ec0ee5))
- **scroll:** use manual scrollRestoration with scrollBehavior ([#1814](https://github.com/vuejs/vue-router/issues/1814)) ([1261363](https://github.com/vuejs/vue-router/commit/1261363))
- **types:** NavigationGuardNext ([#2497](https://github.com/vuejs/vue-router/issues/2497)) ([d18c497](https://github.com/vuejs/vue-router/commit/d18c497))

## [3.1.6](https://github.com/vuejs/vue-router/compare/v3.1.5...v3.1.6) (2020-02-26)

### Bug Fixes

- preserve history state when reloading ([a4ec3e2](https://github.com/vuejs/vue-router/commit/a4ec3e2))
- **ts:** add null to Route.name ([#3117](https://github.com/vuejs/vue-router/issues/3117)) ([8f831f2](https://github.com/vuejs/vue-router/commit/8f831f2))
- correctly calculate `path` when `pathMatch` is empty string ([#3111](https://github.com/vuejs/vue-router/issues/3111)) ([38e6ccd](https://github.com/vuejs/vue-router/commit/38e6ccd)), closes [#3106](https://github.com/vuejs/vue-router/issues/3106)

## [3.1.5](https://github.com/vuejs/vue-router/compare/v3.1.4...v3.1.5) (2020-01-15)

### Bug Fixes

- **view:** add passing props to inactive component ([#2773](https://github.com/vuejs/vue-router/issues/2773)) ([0fb1343](https://github.com/vuejs/vue-router/commit/0fb1343)), closes [#2301](https://github.com/vuejs/vue-router/issues/2301)
- **view:** fix deeply nested keep-alive router-views displaying ([#2930](https://github.com/vuejs/vue-router/issues/2930)) ([0c2b1aa](https://github.com/vuejs/vue-router/commit/0c2b1aa)), closes [#2923](https://github.com/vuejs/vue-router/issues/2923)

## [3.1.4](https://github.com/vuejs/vue-router/compare/v3.1.3...v3.1.4) (2020-01-14)

### Bug Fixes

- suppress warning if `pathMatch` is empty ([#3081](https://github.com/vuejs/vue-router/issues/3081)) ([ddc6bc7](https://github.com/vuejs/vue-router/commit/ddc6bc7)), closes [#3072](https://github.com/vuejs/vue-router/issues/3072)
- **link:** correctly warn wrong v-slot usage ([a150291](https://github.com/vuejs/vue-router/commit/a150291)), closes [#3091](https://github.com/vuejs/vue-router/issues/3091)
- **location:** add a copy for params with named locations ([#2802](https://github.com/vuejs/vue-router/issues/2802)) ([2b39f5a](https://github.com/vuejs/vue-router/commit/2b39f5a)), closes [#2800](https://github.com/vuejs/vue-router/issues/2800) [#2938](https://github.com/vuejs/vue-router/issues/2938) [#2938](https://github.com/vuejs/vue-router/issues/2938)

### Features

- **history:** preserve existing history.state ([c0d3376](https://github.com/vuejs/vue-router/commit/c0d3376)), closes [#3006](https://github.com/vuejs/vue-router/issues/3006)

## [3.1.3](https://github.com/vuejs/vue-router/compare/v3.1.2...v3.1.3) (2019-08-30)

### Bug Fixes

- **link:** merge event listeners when provided in an anchor ([e0d4dc4](https://github.com/vuejs/vue-router/commit/e0d4dc4)), closes [#2890](https://github.com/vuejs/vue-router/issues/2890)

### Features

- **errors:** add stack trace to NavigationDuplicated ([5ef5d73](https://github.com/vuejs/vue-router/commit/5ef5d73)), closes [#2881](https://github.com/vuejs/vue-router/issues/2881)
- warn about root paths without a leading slash ([#2591](https://github.com/vuejs/vue-router/issues/2591)) ([7d7e048](https://github.com/vuejs/vue-router/commit/7d7e048)), closes [#2550](https://github.com/vuejs/vue-router/issues/2550) [#2550](https://github.com/vuejs/vue-router/issues/2550)

## [3.1.2](https://github.com/vuejs/vue-router/compare/v3.1.1...v3.1.2) (2019-08-08)

### Bug Fixes

- **types:** prioritize promise based push/replace ([1243e8b](https://github.com/vuejs/vue-router/commit/1243e8b))

### Reverts

- "fix(hash): correctly place query if placed before hash ([#2851](https://github.com/vuejs/vue-router/issues/2851))" ([9b30e4c](https://github.com/vuejs/vue-router/commit/9b30e4c)), closes [#2876](https://github.com/vuejs/vue-router/issues/2876). See more information at https://github.com/vuejs/vue-router/issues/2125#issuecomment-519521424

## [3.1.1](https://github.com/vuejs/vue-router/compare/v3.1.0...v3.1.1) (2019-08-06)

### Bug Fixes

- **link:** silence back navigations errors ([59b6da3](https://github.com/vuejs/vue-router/commit/59b6da3))

# [3.1.0](https://github.com/vuejs/vue-router/compare/v3.0.7...v3.1.0) (2019-08-06)

### Bug Fixes

- **abstract history:** allow router.back in abstract mode when 2 consecutive same routes appear in history stack ([#2771](https://github.com/vuejs/vue-router/issues/2771)) ([8910979](https://github.com/vuejs/vue-router/commit/8910979)), closes [#2607](https://github.com/vuejs/vue-router/issues/2607)
- **hash:** correctly place query if placed before hash ([#2851](https://github.com/vuejs/vue-router/issues/2851)) ([b7715dc](https://github.com/vuejs/vue-router/commit/b7715dc)), closes [#2125](https://github.com/vuejs/vue-router/issues/2125) [#2262](https://github.com/vuejs/vue-router/issues/2262)
- **link:** Fix active links when parent link redirects to child ([#2772](https://github.com/vuejs/vue-router/issues/2772)) ([64785a9](https://github.com/vuejs/vue-router/commit/64785a9)), closes [#2724](https://github.com/vuejs/vue-router/issues/2724)
- adapt error to work on IE9 ([527d6d5](https://github.com/vuejs/vue-router/commit/527d6d5))

### Features

- **alias:** warn against redundant aliases ([04a02c0](https://github.com/vuejs/vue-router/commit/04a02c0)), closes [#2461](https://github.com/vuejs/vue-router/issues/2461) [#2462](https://github.com/vuejs/vue-router/issues/2462)
- **scroll:** handle id selectors starting with a number ([799ceca](https://github.com/vuejs/vue-router/commit/799ceca)), closes [#2163](https://github.com/vuejs/vue-router/issues/2163)
- return a promise with push and replace ([#2862](https://github.com/vuejs/vue-router/issues/2862)) ([d907a13](https://github.com/vuejs/vue-router/commit/d907a13)), closes [#1769](https://github.com/vuejs/vue-router/issues/1769) [#1769](https://github.com/vuejs/vue-router/issues/1769)
- scoped slot for link ([e289dde](https://github.com/vuejs/vue-router/commit/e289dde))
- warn the user for invalid uses of v-slot with Link ([44c63a9](https://github.com/vuejs/vue-router/commit/44c63a9))

## [3.0.7](https://github.com/vuejs/vue-router/compare/v3.0.6...v3.0.7) (2019-07-03)

### Bug Fixes

- apps loaded from Windows file shares not mapped to network drives ([#2774](https://github.com/vuejs/vue-router/issues/2774)) ([c2c78a3](https://github.com/vuejs/vue-router/commit/c2c78a3))
- make callback of next in beforeRouterEnter more consistent ([#2738](https://github.com/vuejs/vue-router/issues/2738)) ([8ac478f](https://github.com/vuejs/vue-router/commit/8ac478f)), closes [#2761](https://github.com/vuejs/vue-router/issues/2761) [#2728](https://github.com/vuejs/vue-router/issues/2728)

## [3.0.6](https://github.com/vuejs/vue-router/compare/v3.0.5...v3.0.6) (2019-04-17)

### Bug Fixes

- revert [#2713](https://github.com/vuejs/vue-router/issues/2713) ([#2723](https://github.com/vuejs/vue-router/issues/2723)) ([ec6eab7](https://github.com/vuejs/vue-router/commit/ec6eab7)), closes [#2719](https://github.com/vuejs/vue-router/issues/2719)

## [3.0.5](https://github.com/vuejs/vue-router/compare/v3.0.4...v3.0.5) (2019-04-15)

### Bug Fixes

- push before creating Vue instance ([#2713](https://github.com/vuejs/vue-router/issues/2713)) ([6974a6f](https://github.com/vuejs/vue-router/commit/6974a6f)), closes [#2712](https://github.com/vuejs/vue-router/issues/2712)
- **router-view:** add condition to see whether the tree is inactive (fix [#2552](https://github.com/vuejs/vue-router/issues/2552)) ([#2592](https://github.com/vuejs/vue-router/issues/2592)) ([e6d8fd2](https://github.com/vuejs/vue-router/commit/e6d8fd2))
- **router-view:** register instance in init hook ([c3abdf6](https://github.com/vuejs/vue-router/commit/c3abdf6)), closes [#2561](https://github.com/vuejs/vue-router/issues/2561) [#2689](https://github.com/vuejs/vue-router/issues/2689) [#2561](https://github.com/vuejs/vue-router/issues/2561) [#2561](https://github.com/vuejs/vue-router/issues/2561)

## [3.0.4](https://github.com/vuejs/vue-router/compare/v3.0.3...v3.0.4) (2019-04-12)

### Bug Fixes

- prevent memory leaks by removing app references ([#2706](https://github.com/vuejs/vue-router/issues/2706)) ([8056105](https://github.com/vuejs/vue-router/commit/8056105)), closes [#2639](https://github.com/vuejs/vue-router/issues/2639)
- **hash:** prevent double decoding ([#2711](https://github.com/vuejs/vue-router/issues/2711)) ([a775fb1](https://github.com/vuejs/vue-router/commit/a775fb1)), closes [#2708](https://github.com/vuejs/vue-router/issues/2708)

### Features

- **esm build:** build ES modules for browser ([#2705](https://github.com/vuejs/vue-router/issues/2705)) ([627027f](https://github.com/vuejs/vue-router/commit/627027f))

## [3.0.3](https://github.com/vuejs/vue-router/compare/v3.0.2...v3.0.3) (2019-04-08)

### Bug Fixes

- removes warning resolving asterisk routes ([e224637](https://github.com/vuejs/vue-router/commit/e224637)), closes [#2505](https://github.com/vuejs/vue-router/issues/2505) [#2505](https://github.com/vuejs/vue-router/issues/2505)
- **normalizeLocation:** create a copy with named locations ([#2286](https://github.com/vuejs/vue-router/issues/2286)) ([53cce99](https://github.com/vuejs/vue-router/commit/53cce99)), closes [#2121](https://github.com/vuejs/vue-router/issues/2121)
- **resolve:** use current location if not provided ([#2390](https://github.com/vuejs/vue-router/issues/2390)) ([7ff4de4](https://github.com/vuejs/vue-router/commit/7ff4de4)), closes [#2385](https://github.com/vuejs/vue-router/issues/2385)
- **types:** allow null/undefined in query params ([ca30a75](https://github.com/vuejs/vue-router/commit/ca30a75)), closes [#2605](https://github.com/vuejs/vue-router/issues/2605)

## [3.0.2](https://github.com/vuejs/vue-router/compare/v3.0.1...v3.0.2) (2018-11-23)

### Bug Fixes

- **errors:** throws with invalid route objects ([#1893](https://github.com/vuejs/vue-router/issues/1893)) ([c837666](https://github.com/vuejs/vue-router/commit/c837666))
- fix the test in async.spec.js ([#1953](https://github.com/vuejs/vue-router/issues/1953)) ([4e9e66b](https://github.com/vuejs/vue-router/commit/4e9e66b))
- initial url path for non ascii urls ([#2375](https://github.com/vuejs/vue-router/issues/2375)) ([c3b0a33](https://github.com/vuejs/vue-router/commit/c3b0a33))
- only setupScroll when support pushState due to possible fallback: false ([#1835](https://github.com/vuejs/vue-router/issues/1835)) ([fac60f6](https://github.com/vuejs/vue-router/commit/fac60f6)), closes [#1834](https://github.com/vuejs/vue-router/issues/1834)
- workaround replaceState bug in Safari ([#2295](https://github.com/vuejs/vue-router/issues/2295)) ([3c7d8ab](https://github.com/vuejs/vue-router/commit/3c7d8ab)), closes [#2195](https://github.com/vuejs/vue-router/issues/2195)
- **hash:** support unicode in initial route ([8369c6b](https://github.com/vuejs/vue-router/commit/8369c6b))
- **history-mode:** correcting indentation in web.config example ([#1948](https://github.com/vuejs/vue-router/issues/1948)) ([4b071f9](https://github.com/vuejs/vue-router/commit/4b071f9))
- **match:** use pathMatch for the param of \* routes ([#1995](https://github.com/vuejs/vue-router/issues/1995)) ([ca1fccd](https://github.com/vuejs/vue-router/commit/ca1fccd)), closes [#1994](https://github.com/vuejs/vue-router/issues/1994)

### Features

- call scrollBehavior with app context ([#1804](https://github.com/vuejs/vue-router/issues/1804)) ([c93a734](https://github.com/vuejs/vue-router/commit/c93a734))

## [3.0.1](https://github.com/vuejs/vue-router/compare/v3.0.0...v3.0.1) (2017-10-13)

### Bug Fixes

- fix props-passing regression ([02ff792](https://github.com/vuejs/vue-router/commit/02ff792)), closes [#1800](https://github.com/vuejs/vue-router/issues/1800)

## [3.0.0](https://github.com/vuejs/vue-router/compare/v2.8.0...v3.0.0) (2017-10-11)

### Features

- **typings:** adapt to the new Vue typings ([#1685](https://github.com/vuejs/vue-router/issues/1685)) ([8855e36](https://github.com/vuejs/vue-router/commit/8855e36))

### BREAKING CHANGES

- **typings:** It is no longer compatible with the old Vue typings

## [2.8.0](https://github.com/vuejs/vue-router/compare/v2.7.0...v2.8.0) (2017-10-11)

### Bug Fixes

- allow insllation on extended Vue copies ([f62c5d6](https://github.com/vuejs/vue-router/commit/f62c5d6))
- avoid first popstate event with async guard together (fix [#1508](https://github.com/vuejs/vue-router/issues/1508)) ([#1661](https://github.com/vuejs/vue-router/issues/1661)) ([3cbc0f3](https://github.com/vuejs/vue-router/commit/3cbc0f3))
- deep clone query when creating routes ([effb114](https://github.com/vuejs/vue-router/commit/effb114)), closes [#1690](https://github.com/vuejs/vue-router/issues/1690)
- fix scroll when going back to initial route ([#1586](https://github.com/vuejs/vue-router/issues/1586)) ([c166822](https://github.com/vuejs/vue-router/commit/c166822))
- handle null values when comparing objects ([#1568](https://github.com/vuejs/vue-router/issues/1568)) ([4e95bd8](https://github.com/vuejs/vue-router/commit/4e95bd8)), closes [#1566](https://github.com/vuejs/vue-router/issues/1566)
- resolve native ES modules ([8a28426](https://github.com/vuejs/vue-router/commit/8a28426))
- send props not defined on the route component in \$attrs. Fixes [#1695](https://github.com/vuejs/vue-router/issues/1695). ([#1702](https://github.com/vuejs/vue-router/issues/1702)) ([a722b6a](https://github.com/vuejs/vue-router/commit/a722b6a))

### Features

- enhance hashHistory to support scrollBehavior ([#1662](https://github.com/vuejs/vue-router/issues/1662)) ([1422eb5](https://github.com/vuejs/vue-router/commit/1422eb5))
- scrollBehavior accept returning a promise ([#1758](https://github.com/vuejs/vue-router/issues/1758)) ([ce13b55](https://github.com/vuejs/vue-router/commit/ce13b55))

# [2.7.0](https://github.com/vuejs/vue-router/compare/v2.6.0...v2.7.0) (2017-06-29)

### Features

- auto resolve ES module default when resolving async components ([d539788](https://github.com/vuejs/vue-router/commit/d539788))
