# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## [1.1.3](https://github.com/vuejs/vue-test-utils/compare/v1.1.2...v1.1.3) (2021-02-04)


### Bug Fixes

* **error.js:** do not console.error handled exceptions ([#1761](https://github.com/vuejs/vue-test-utils/issues/1761)) ([c4133d6](https://github.com/vuejs/vue-test-utils/commit/c4133d6a78cd0ad7efafdfadb4f1ae28e31079b4)), closes [#1760](https://github.com/vuejs/vue-test-utils/issues/1760)
* prevent setProps infinite loop with immediate watchers ([#1752](https://github.com/vuejs/vue-test-utils/issues/1752)) ([db4ab8b](https://github.com/vuejs/vue-test-utils/commit/db4ab8b10872ff1ca492c02ad0f62368ed748631))





## [1.0.5](https://github.com/vuejs/vue-test-utils/compare/v1.0.4...v1.0.5) (2020-08-29)

**Note:** Version bump only for package @vue/test-utils





## [1.0.4](https://github.com/vuejs/vue-test-utils/compare/v1.0.3...v1.0.4) (2020-08-17)


### Bug Fixes

* **setprops:** allowed for setProps to be synced with nextTick intervals ([#1618](https://github.com/vuejs/vue-test-utils/issues/1618)) ([9a3e6f9](https://github.com/vuejs/vue-test-utils/commit/9a3e6f96d71cba790cb2e7f9b918548c00758341)), closes [#1419](https://github.com/vuejs/vue-test-utils/issues/1419)
* allow using findComponent on a functional component ([#1593](https://github.com/vuejs/vue-test-utils/issues/1593)) ([2d6b497](https://github.com/vuejs/vue-test-utils/commit/2d6b49780c7e1d663b877ddf5d6492ed7b510379))





## [1.0.2](https://github.com/vuejs/vue-test-utils/compare/v1.0.1...v1.0.2) (2020-05-06)

**Note:** Version bump only for package @vue/test-utils





# [1.0.0](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.33...v1.0.0) (2020-05-05)


### Features

* add support of arbitrary mounting point via attachTo option ([#1492](https://github.com/vuejs/vue-test-utils/issues/1492)) ([f3d0d3f](https://github.com/vuejs/vue-test-utils/commit/f3d0d3f1717fd3cc3e406d3ac3f4ace316967211))
* Optionally hide deprecation errors ([#1518](https://github.com/vuejs/vue-test-utils/issues/1518)) ([7a0b7e0](https://github.com/vuejs/vue-test-utils/commit/7a0b7e0c695da901f22df2fea53f6fef5e4dadf7))
* return nextTick from setters, fix [#1515](https://github.com/vuejs/vue-test-utils/issues/1515) ([#1517](https://github.com/vuejs/vue-test-utils/issues/1517)) ([aa7b76d](https://github.com/vuejs/vue-test-utils/commit/aa7b76d5996a24bfaca74989907c0982fdeaa013))
* stub out transitions by default ([#1411](https://github.com/vuejs/vue-test-utils/issues/1411)) ([6f0a41a](https://github.com/vuejs/vue-test-utils/commit/6f0a41a8f0b643f2e695c68ead78f4980a2725c7))
* **test-utils:** add 'overview' function ([#1491](https://github.com/vuejs/vue-test-utils/issues/1491)) ([4b0c5c9](https://github.com/vuejs/vue-test-utils/commit/4b0c5c94fb29885bb65e26fea64b8ca64960e301)), closes [#1461](https://github.com/vuejs/vue-test-utils/issues/1461)





# [1.0.0-beta.33](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.32...v1.0.0-beta.33) (2020-04-08)


### Bug Fixes

* **test-utils:** fix cancelable attribute in dom events ([#1460](https://github.com/vuejs/vue-test-utils/issues/1460)) ([b1a532a](https://github.com/vuejs/vue-test-utils/commit/b1a532aa72c71d2f4282f4bc31373cb143e82833))


### Features

* support lazy modifier with setValue ([#1467](https://github.com/vuejs/vue-test-utils/issues/1467)) ([afd7a82](https://github.com/vuejs/vue-test-utils/commit/afd7a82426c2e72fca61bf00881574d81dffbf68))





# [1.0.0-beta.32](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.31...v1.0.0-beta.32) (2020-03-09)


### Bug Fixes

* **types:** emitted can return undefined ([#1431](https://github.com/vuejs/vue-test-utils/issues/1431)) ([b41a09d](https://github.com/vuejs/vue-test-utils/commit/b41a09dcfd616c933bb1e36eba131ba273af6ea4))
* improvement functional component features ([#1427](https://github.com/vuejs/vue-test-utils/issues/1427)) ([ebcf97c](https://github.com/vuejs/vue-test-utils/commit/ebcf97cc3cf230a29bdbe37a5aa6c69e3fa5ec97))





# [1.0.0-beta.31](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.30...v1.0.0-beta.31) (2020-01-18)


### Bug Fixes

* Stop `trigger` from working on disabled html elements ([#1362](https://github.com/vuejs/vue-test-utils/pull/1362))
* Add provide/inject support for Composition API ([#1354](https://github.com/vuejs/vue-test-utils/pull/1354)) 
* Fix issue with keyCodes provided to `trigger` ([#1378](https://github.com/vuejs/vue-test-utils/pull/1378)) closes [#1285](https://github.com/vuejs/vue-test-utils/issues/1285), [#1295](https://github.com/vuejs/vue-test-utils/issues/1295)
* setChecked and setSelected should only work if not already selected ([#1380](https://github.com/vuejs/vue-test-utils/pull/1380)) closes [#1339](https://github.com/vuejs/vue-test-utils/issues/1339)
* Override watch definitions properly ([#1392](https://github.com/vuejs/vue-test-utils/pull/1392)) closes [#1391](https://github.com/vuejs/vue-test-utils/issues/1391)
* Support v-slot ([#1383](https://github.com/vuejs/vue-test-utils/pull/1383)) closes [#1261](https://github.com/vuejs/vue-test-utils/issues/1261)
* Allow find to work on both Pascal case and camel case ([#1398](https://github.com/vuejs/vue-test-utils/pull/1398)) closes [#1232](https://github.com/vuejs/vue-test-utils/issues/1232)
* Pass refs to functional component stubs [#1293](https://github.com/vuejs/vue-test-utils/pull/1293) closes [#1292](https://github.com/vuejs/vue-test-utils/issues/1292)

### Features

* Allow templates to be defined in HTML ([#1362](https://github.com/vuejs/vue-test-utils/pull/1320)) closes [#351](https://github.com/vuejs/vue-test-utils/issues/351)
* Store the selector when using `find` ([#1248](https://github.com/vuejs/vue-test-utils/pull/1248)) closes [#1135](https://github.com/vuejs/vue-test-utils/issues/1135)
* Introduce enableAutoDestroy() helper function ([#1245](https://github.com/vuejs/vue-test-utils/pull/1245)) closes [#1236](https://github.com/vuejs/vue-test-utils/issues/1236)
* Allow negative indices to be passed to .at() ([#1244](https://github.com/vuejs/vue-test-utils/pull/1244))  
* Add a get method to Wrapper ([#1304](https://github.com/vuejs/vue-test-utils/pull/1304)) closes [#1298](https://github.com/vuejs/vue-test-utils/issues/1298)



<a name="1.0.0-beta.30"></a>
# [1.0.0-beta.30](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.29...v1.0.0-beta.30) (2019-11-28)


### Bug Fixes

* polyfill Element.matches for IE < 11 ([#1230](https://github.com/vuejs/vue-test-utils/issues/1230)) ([5e04331](https://github.com/vuejs/vue-test-utils/commit/5e04331)), closes [#1223](https://github.com/vuejs/vue-test-utils/issues/1223)
* **types:** allow `false` as a component stub value ([#1231](https://github.com/vuejs/vue-test-utils/issues/1231)) ([2a4c6ef](https://github.com/vuejs/vue-test-utils/commit/2a4c6ef))
* respect "hidden" attributes in isVisible() ([#1257](https://github.com/vuejs/vue-test-utils/issues/1257)) ([950763f](https://github.com/vuejs/vue-test-utils/commit/950763f))


### Code Refactoring

* remove sync mode ([#1141](https://github.com/vuejs/vue-test-utils/issues/1141)) ([ef613de](https://github.com/vuejs/vue-test-utils/commit/ef613de))


### Features

* **wrapper:** allow destroy() method to work with functional components ([#1188](https://github.com/vuejs/vue-test-utils/issues/1188)) ([f4ea3fd](https://github.com/vuejs/vue-test-utils/commit/f4ea3fd))
* add option to pretty print html components ([#1229](https://github.com/vuejs/vue-test-utils/issues/1229)) ([99336c4](https://github.com/vuejs/vue-test-utils/commit/99336c4))
* stop auto stubbing transition and transition-group ([#1127](https://github.com/vuejs/vue-test-utils/issues/1127)) ([85a972c](https://github.com/vuejs/vue-test-utils/commit/85a972c))


### BREAKING CHANGES

* html output will now be formatted
* * Remove `sync` mode
* Remove TransitionStub
* Remove Transition




<a name="1.0.0-beta.29"></a>
# [1.0.0-beta.29](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.28...v1.0.0-beta.29) (2019-02-02)


### Bug Fixes

* handle errors in destroy ([#1106](https://github.com/vuejs/vue-test-utils/issues/1106)) ([efab983](https://github.com/vuejs/vue-test-utils/commit/efab983))
* use Vue async option for sync mode ([#1062](https://github.com/vuejs/vue-test-utils/issues/1062)) ([4c65dbd](https://github.com/vuejs/vue-test-utils/commit/4c65dbd))


### Code Refactoring

* remove deprecated methods ([#1109](https://github.com/vuejs/vue-test-utils/issues/1109)) ([1d1d003](https://github.com/vuejs/vue-test-utils/commit/1d1d003))
* remove polyfills ([#1110](https://github.com/vuejs/vue-test-utils/issues/1110)) ([ade4398](https://github.com/vuejs/vue-test-utils/commit/ade4398))


### BREAKING CHANGES

* Remove polyfills from library
* hasStyle, hasAttribute, hasClass, hasProp, visible, and setComputed removed




<a name="1.0.0-beta.28"></a>

# [1.0.0-beta.28](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.27...v1.0.0-beta.28) (2018-12-29)

### Bug Fixes

- add custom data to events ([#1076](https://github.com/vuejs/vue-test-utils/issues/1076)) ([73f0e91](https://github.com/vuejs/vue-test-utils/commit/73f0e91))
- improve filter typing ([#1077](https://github.com/vuejs/vue-test-utils/issues/1077)) ([a0528ca](https://github.com/vuejs/vue-test-utils/commit/a0528ca))
- use correct event type for checkbox v-model handler ([#1083](https://github.com/vuejs/vue-test-utils/issues/1083)) ([ef66c26](https://github.com/vuejs/vue-test-utils/commit/ef66c26))

<a name="1.0.0-beta.27"></a>

# [1.0.0-beta.27](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.26...v1.0.0-beta.27) (2018-12-09)

### Bug Fixes

- fix references to documents in warnings ([#1052](https://github.com/vuejs/vue-test-utils/issues/1052)) ([45e2fe4](https://github.com/vuejs/vue-test-utils/commit/45e2fe4))
- remove cached constructors ([#1059](https://github.com/vuejs/vue-test-utils/issues/1059)) ([aea1c94](https://github.com/vuejs/vue-test-utils/commit/aea1c94))
- stop stubs leaking with localVue ([#1056](https://github.com/vuejs/vue-test-utils/issues/1056)) ([5500553](https://github.com/vuejs/vue-test-utils/commit/5500553))

<a name="1.0.0-beta.26"></a>

# [1.0.0-beta.26](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.25...v1.0.0-beta.26) (2018-11-26)

### Bug Fixes

- add functions to scoped slots typing ([#1022](https://github.com/vuejs/vue-test-utils/issues/1022)) ([8db0c20](https://github.com/vuejs/vue-test-utils/commit/8db0c20))
- create stubs in render ([#1038](https://github.com/vuejs/vue-test-utils/issues/1038)) ([e1fd705](https://github.com/vuejs/vue-test-utils/commit/e1fd705)), closes [#973](https://github.com/vuejs/vue-test-utils/issues/973) [#994](https://github.com/vuejs/vue-test-utils/issues/994) [#995](https://github.com/vuejs/vue-test-utils/issues/995)
- do not remove cached constructors ([#962](https://github.com/vuejs/vue-test-utils/issues/962)) ([71ec3b9](https://github.com/vuejs/vue-test-utils/commit/71ec3b9))
- use correct event interface ([#977](https://github.com/vuejs/vue-test-utils/issues/977)) ([8771b8f](https://github.com/vuejs/vue-test-utils/commit/8771b8f))

### Features

- support lazily added components ([#1005](https://github.com/vuejs/vue-test-utils/issues/1005)) ([3653c60](https://github.com/vuejs/vue-test-utils/commit/3653c60))
- undefined attributes parsed as \$attrs ([#1029](https://github.com/vuejs/vue-test-utils/issues/1029)) ([0d3e46d](https://github.com/vuejs/vue-test-utils/commit/0d3e46d))

### BREAKING CHANGES

- The tag name rendered by snapshots will use the rendered component tag, rather than the registered component name

<a name="1.0.0-beta.25"></a>

# [1.0.0-beta.25](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.24...v1.0.0-beta.25) (2018-09-08)

### Bug Fixes

- handle global stubs and functional extended components ([#943](https://github.com/vuejs/vue-test-utils/issues/943)) ([0d1ddd1](https://github.com/vuejs/vue-test-utils/commit/0d1ddd1))
- improve emitted type ([#933](https://github.com/vuejs/vue-test-utils/issues/933)) ([3049c3e](https://github.com/vuejs/vue-test-utils/commit/3049c3e))
- throw error if unsupported options passed in vue < 2.3 ([#910](https://github.com/vuejs/vue-test-utils/issues/910)) ([e8d9547](https://github.com/vuejs/vue-test-utils/commit/e8d9547))

### Features

- **wrapper:** add support for getting prop, attribute and classes by key ([#941](https://github.com/vuejs/vue-test-utils/issues/941)) ([9bb9a87](https://github.com/vuejs/vue-test-utils/commit/9bb9a87))

### Performance Improvements

- use extends over createLocalVue ([#934](https://github.com/vuejs/vue-test-utils/issues/934)) ([af45a9d](https://github.com/vuejs/vue-test-utils/commit/af45a9d))

<a name="1.0.0-beta.24"></a>

# [1.0.0-beta.24](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.23...v1.0.0-beta.24) (2018-08-05)

### Bug Fixes

- handle null in set data ([#896](https://github.com/vuejs/vue-test-utils/issues/896)) ([44c4520](https://github.com/vuejs/vue-test-utils/commit/44c4520))
- wrap extended child components ([#840](https://github.com/vuejs/vue-test-utils/issues/840)) ([4faf5fb](https://github.com/vuejs/vue-test-utils/commit/4faf5fb))

<a name="1.0.0-beta.23"></a>

# [1.0.0-beta.23](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.22...v1.0.0-beta.23) (2018-07-31)

**Note:** Version bump only for package @vue/test-utils

<a name="1.0.0-beta.22"></a>

# [1.0.0-beta.22](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.21...v1.0.0-beta.22) (2018-07-29)

### Bug Fixes

- stub globally registered components ([#859](https://github.com/vuejs/vue-test-utils/issues/859)) ([5af3677](https://github.com/vuejs/vue-test-utils/commit/5af3677))
- support multiple default slot nodes ([#861](https://github.com/vuejs/vue-test-utils/issues/861)) ([85dd3ec](https://github.com/vuejs/vue-test-utils/commit/85dd3ec))

### Features

- export createWrapper method to create wrapper from instance ([#868](https://github.com/vuejs/vue-test-utils/issues/868)) ([ebca3b3](https://github.com/vuejs/vue-test-utils/commit/ebca3b3))
- export wrapper class ([#866](https://github.com/vuejs/vue-test-utils/issues/866)) ([c212ebf](https://github.com/vuejs/vue-test-utils/commit/c212ebf))

<a name="1.0.0-beta.21"></a>

# [1.0.0-beta.21](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.20...v1.0.0-beta.21) (2018-07-22)

### Bug Fixes

- handle textarea correctly in setValue() and setChecked() ([#771](https://github.com/vuejs/vue-test-utils/issues/771)) ([4c9fe3c](https://github.com/vuejs/vue-test-utils/commit/4c9fe3c))
- **types:** remove unnecessary method ([#755](https://github.com/vuejs/vue-test-utils/issues/755)) ([2068208](https://github.com/vuejs/vue-test-utils/commit/2068208))
- broken links for deprecated methods ([#786](https://github.com/vuejs/vue-test-utils/issues/786)) ([5bb6a0b](https://github.com/vuejs/vue-test-utils/commit/5bb6a0b))
- fix type of wrapper.vm ([#759](https://github.com/vuejs/vue-test-utils/issues/759)) ([ff5220d](https://github.com/vuejs/vue-test-utils/commit/ff5220d))
- handle cloneDeep errors in createLocalVue ([#844](https://github.com/vuejs/vue-test-utils/issues/844)) ([17dfdc8](https://github.com/vuejs/vue-test-utils/commit/17dfdc8))
- handle unnamed parent and child components ([#768](https://github.com/vuejs/vue-test-utils/issues/768)) ([71a2ac4](https://github.com/vuejs/vue-test-utils/commit/71a2ac4))
- improve scopedSlots option ([#808](https://github.com/vuejs/vue-test-utils/issues/808)) ([b946997](https://github.com/vuejs/vue-test-utils/commit/b946997))
- recursively call Vue.set in setData ([#843](https://github.com/vuejs/vue-test-utils/issues/843)) ([ef01abf](https://github.com/vuejs/vue-test-utils/commit/ef01abf))
- setProps() throws an error if the property is the same reference ([#791](https://github.com/vuejs/vue-test-utils/issues/791)) ([bf655f3](https://github.com/vuejs/vue-test-utils/commit/bf655f3))
- stubs extended component correctly ([#767](https://github.com/vuejs/vue-test-utils/issues/767)) ([24ab4c5](https://github.com/vuejs/vue-test-utils/commit/24ab4c5))
- support setValue on textarea ([#764](https://github.com/vuejs/vue-test-utils/issues/764)) ([e83cda2](https://github.com/vuejs/vue-test-utils/commit/e83cda2))
- update props when watcher depends on value ([#842](https://github.com/vuejs/vue-test-utils/issues/842)) ([2aeaee3](https://github.com/vuejs/vue-test-utils/commit/2aeaee3))
- use boolean for VueWrapper ([#763](https://github.com/vuejs/vue-test-utils/issues/763)) ([6fa6ecd](https://github.com/vuejs/vue-test-utils/commit/6fa6ecd))

### Features

- add parentComponent option ([#846](https://github.com/vuejs/vue-test-utils/issues/846)) ([1951409](https://github.com/vuejs/vue-test-utils/commit/1951409))
- use setValue() on select element ([#837](https://github.com/vuejs/vue-test-utils/issues/837)) ([2e6de7b](https://github.com/vuejs/vue-test-utils/commit/2e6de7b))

<a name="1.0.0-beta.20"></a>

# [1.0.0-beta.20](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.19...v1.0.0-beta.20) (2018-06-24)

### Bug Fixes

- force update in setProps ([#752](https://github.com/vuejs/vue-test-utils/issues/752)) ([7e23e09](https://github.com/vuejs/vue-test-utils/commit/7e23e09))
- stub child components ([#723](https://github.com/vuejs/vue-test-utils/issues/723)) ([bc736fb](https://github.com/vuejs/vue-test-utils/commit/bc736fb))

### Features

- element, vnode, vm, and options are read-only ([#748](https://github.com/vuejs/vue-test-utils/issues/748)) ([b801c25](https://github.com/vuejs/vue-test-utils/commit/b801c25))
- set wrapper.vm if the element binds Vue instance ([#724](https://github.com/vuejs/vue-test-utils/issues/724)) ([b14afae](https://github.com/vuejs/vue-test-utils/commit/b14afae))
- throw error if the read-only property is tried to change ([#749](https://github.com/vuejs/vue-test-utils/issues/749)) ([fb46268](https://github.com/vuejs/vue-test-utils/commit/fb46268))

<a name="1.0.0-beta.19"></a>

# [1.0.0-beta.19](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.18...v1.0.0-beta.19) (2018-06-14)

### Bug Fixes

- include default props in props object ([#716](https://github.com/vuejs/vue-test-utils/issues/716)) ([5bcf574](https://github.com/vuejs/vue-test-utils/commit/5bcf574))
- wrapper.setSelected() to work on select with optgroups ([#715](https://github.com/vuejs/vue-test-utils/issues/715)) ([dae0b1c](https://github.com/vuejs/vue-test-utils/commit/dae0b1c))

### Features

- silence warnings when updating prop ([#688](https://github.com/vuejs/vue-test-utils/issues/688)) ([7fa2fb3](https://github.com/vuejs/vue-test-utils/commit/7fa2fb3))

<a name="1.0.0-beta.18"></a>

# [1.0.0-beta.18](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.17...v1.0.0-beta.18) (2018-06-09)

### Bug Fixes

- update context after setMethods ([#696](https://github.com/vuejs/vue-test-utils/issues/696)) ([0590b4c](https://github.com/vuejs/vue-test-utils/commit/0590b4c))

<a name="1.0.0-beta.17"></a>

# [1.0.0-beta.17](https://github.com/vuejs/vue-test-utils/compare/v1.0.0-beta.16...v1.0.0-beta.17) (2018-06-09)

### Bug Fixes

- add updated hook ([#675](https://github.com/vuejs/vue-test-utils/issues/675)) ([9a2a25a](https://github.com/vuejs/vue-test-utils/commit/9a2a25a)), closes [#661](https://github.com/vuejs/vue-test-utils/issues/661)
- do not deep merge array data ([#604](https://github.com/vuejs/vue-test-utils/issues/604)) ([934745b](https://github.com/vuejs/vue-test-utils/commit/934745b))
- method should be updated when triggering ([3922ab7](https://github.com/vuejs/vue-test-utils/commit/3922ab7))
- remove includes and findIndex ([#610](https://github.com/vuejs/vue-test-utils/issues/610)) ([a70a887](https://github.com/vuejs/vue-test-utils/commit/a70a887))
- remove throw from errorHandler ([#655](https://github.com/vuejs/vue-test-utils/issues/655)) ([b4517ab](https://github.com/vuejs/vue-test-utils/commit/b4517ab))
- type definition of classes method ([#685](https://github.com/vuejs/vue-test-utils/issues/685)) ([a864ed3](https://github.com/vuejs/vue-test-utils/commit/a864ed3))
- Update links to docs ([#670](https://github.com/vuejs/vue-test-utils/issues/670)) ([2f162e6](https://github.com/vuejs/vue-test-utils/commit/2f162e6)), closes [#3](https://github.com/vuejs/vue-test-utils/issues/3)

### Features

- add parent in create-instance ([#586](https://github.com/vuejs/vue-test-utils/issues/586)) ([0ab5a75](https://github.com/vuejs/vue-test-utils/commit/0ab5a75))
- Add setValue method ([#557](https://github.com/vuejs/vue-test-utils/issues/557)) ([b4331ff](https://github.com/vuejs/vue-test-utils/commit/b4331ff))
- overwrite arrays in setData ([#652](https://github.com/vuejs/vue-test-utils/issues/652)) ([032a7a4](https://github.com/vuejs/vue-test-utils/commit/032a7a4))
- render component name in stub ([#606](https://github.com/vuejs/vue-test-utils/issues/606)) ([dbf63bb](https://github.com/vuejs/vue-test-utils/commit/dbf63bb))

### BREAKING CHANGES

- removes templates from slots
