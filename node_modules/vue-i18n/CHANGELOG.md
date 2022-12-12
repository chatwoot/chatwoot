## v8.24.3 (2021-04-09)

#### :bug: Bug Fixes
* [#1175](https://github.com/kazupon/vue-i18n/pull/1175) [perf] Use Set so lookup of _dataListeners can be O(1) ([@exoego](https://github.com/exoego))

#### :chart_with_upwards_trend: Performance Fixes
* [#1175](https://github.com/kazupon/vue-i18n/pull/1175) [perf] Use Set so lookup of _dataListeners can be O(1) ([@exoego](https://github.com/exoego))

#### Committers: 1
- TATSUNO Yasuhiro ([@exoego](https://github.com/exoego))

## v8.24.2 (2021-03-23)

#### :bug: Bug Fixes
* [#1151](https://github.com/kazupon/vue-i18n/pull/1151) fix: i18n reference to root causes memory leak (#1044) ([@lzxb](https://github.com/lzxb))

#### :pencil: Documentation
* [#1152](https://github.com/kazupon/vue-i18n/pull/1152) $tc return type ([@Glandos](https://github.com/Glandos))

#### Committers: 2
- Glandos ([@Glandos](https://github.com/Glandos))
- 狼族小狈 ([@lzxb](https://github.com/lzxb))

## v8.24.1 (2021-03-11)

#### :bug: Bug Fixes
* [#1145](https://github.com/kazupon/vue-i18n/pull/1145) Allowing paths to be null for lookups. ([@martinheidegger](https://github.com/martinheidegger))

#### Committers: 1
- Martin Heidegger ([@martinheidegger](https://github.com/martinheidegger))

## v8.24.0 (2021-03-08)

#### :star: New Features
* [#1139](https://github.com/kazupon/vue-i18n/pull/1139) experimental: add meta info for intlify tools ([@kazupon](https://github.com/kazupon))

#### Committers: 1
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))

## v8.23.0 (2021-02-24)

#### :zap: Improved Features
* [#1118](https://github.com/kazupon/vue-i18n/pull/1118) Fix wrong LocaleMatcher type for TS 4.2 ('best-fit' to 'best fit'). ([@mpawelski](https://github.com/mpawelski))

#### :pencil: Documentation
* [#1124](https://github.com/kazupon/vue-i18n/pull/1124) Add documentation for directive `choice` argument ([@Gameghostify](https://github.com/Gameghostify))
* [#1114](https://github.com/kazupon/vue-i18n/pull/1114) Update tooling.md ([@fanlinqiang](https://github.com/fanlinqiang))
* [#1104](https://github.com/kazupon/vue-i18n/pull/1104) Documentation improvemation ([@lucasferreiralimax](https://github.com/lucasferreiralimax))

#### Committers: 4
- Lucas ([@lucasferreiralimax](https://github.com/lucasferreiralimax))
- Mariusz Pawelski ([@mpawelski](https://github.com/mpawelski))
- [@Gameghostify](https://github.com/Gameghostify)
- [@fanlinqiang](https://github.com/fanlinqiang)


## v8.22.4 (2021-01-16)

#### :chart_with_upwards_trend: Performance Fixes
* [#1101](https://github.com/kazupon/vue-i18n/pull/1101) Improve performance of mergeLocaleMessage (#1099) ([@cslee](https://github.com/cslee))

#### Committers: 2
- Eric Lee ([@cslee](https://github.com/cslee))
- Lucas ([@lucasferreiralimax](https://github.com/lucasferreiralimax))


## v8.22.3 (2021-01-08)

#### :zap: Improved Features
* [#1096](https://github.com/kazupon/vue-i18n/pull/1096) @types: Fixed too narrow option types in n() and d() methods ([@gehlert](https://github.com/gehlert))

#### Committers: 3
- MASONGZHI ([@masongzhi](https://github.com/masongzhi))
- TATSUNO Yasuhiro ([@exoego](https://github.com/exoego))
- [@gehlert](https://github.com/gehlert)


## v8.22.2 (2020-11-18)

#### :bug: Bug Fixes
* [#1048](https://github.com/kazupon/vue-i18n/pull/1048) fix: number format keys missing compared the Intl.Number object ([@jevillard](https://github.com/jevillard))

#### Committers: 2
- Alexander Sokolov ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
- Jérémy Villard ([@jevillard](https://github.com/jevillard))


## v8.22.1 (2020-10-19)

#### :boom: Breaking Change
* [#1020](https://github.com/kazupon/vue-i18n/pull/1020) escapeParameterHtml flag: Don't escape ampersand #1019 ([@gardarh](https://github.com/gardarh))

#### Committers: 1
- Gardar Hauksson ([@gardarh](https://github.com/gardarh))


## v8.22.0 (2020-10-06)

#### :star: New Features
* [#1009](https://github.com/kazupon/vue-i18n/pull/1009) Add escapeParameterHtml parameter. #1002 ([@gardarh](https://github.com/gardarh))

#### :bug: Bug Fixes
* [#1003](https://github.com/kazupon/vue-i18n/pull/1003) Bugfix in index.js: wrong if condition in fetchChoice ([@cimchd](https://github.com/cimchd))

#### Committers: 4
- Andreas ([@devmount](https://github.com/devmount))
- Gardar Hauksson ([@gardarh](https://github.com/gardarh))
- Raffaele Pizzari ([@pixari](https://github.com/pixari))
- [@cimchd](https://github.com/cimchd)


## v8.21.1 (2020-09-11)

#### :bug: Bug Fixes
* [#995](https://github.com/kazupon/vue-i18n/pull/995) Update mixin.js ([@ferencbeutel4711](https://github.com/ferencbeutel4711))

#### Committers: 1
- Ferenc Beutel ([@ferencbeutel4711](https://github.com/ferencbeutel4711))


## v8.21.0 (2020-08-13)

#### :star: New Features
* [#972](https://github.com/kazupon/vue-i18n/pull/972) feat: message function ([@kazupon](https://github.com/kazupon))

#### :pencil: Documentation
* [#961](https://github.com/kazupon/vue-i18n/pull/961) Update link to Formatter Interface ([@JohJohan](https://github.com/JohJohan))

#### Committers: 3
- Alexander Sokolov ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
- Johan ([@JohJohan](https://github.com/JohJohan))
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.20.0 (2020-07-30)

#### :star: New Features
* [#959](https://github.com/kazupon/vue-i18n/pull/959) i18n-n component local components passing ([@kazupon](https://github.com/kazupon))
* [#928](https://github.com/kazupon/vue-i18n/pull/928) :zap: improvement(interpolation): enable passage of local components to tag prop ([@vhoyer](https://github.com/vhoyer))

#### Committers: 2
- Vinícius Hoyer ([@vhoyer](https://github.com/vhoyer))
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.19.0 (2020-07-25)

#### :star: New Features
* [#942](https://github.com/kazupon/vue-i18n/pull/942) Add vetur support for tags and attributes ([@phiter](https://github.com/phiter))

#### :pencil: Documentation
* [#925](https://github.com/kazupon/vue-i18n/pull/925) Added missing quote ([@fschlag](https://github.com/fschlag))
* [#921](https://github.com/kazupon/vue-i18n/pull/921) Add lost pluralizationRules option to documentation ([@AleksandrSl](https://github.com/AleksandrSl))
* [#920](https://github.com/kazupon/vue-i18n/pull/920) Make link to API and Guide top level ([@AleksandrSl](https://github.com/AleksandrSl))

#### Committers: 3
- Aleksandr ([@AleksandrSl](https://github.com/AleksandrSl))
- Florian Schlag ([@fschlag](https://github.com/fschlag))
- Phiter Fernandes ([@phiter](https://github.com/phiter))


## v8.18.2 (2020-06-08)

#### :zap: Improved Features
* [#917](https://github.com/kazupon/vue-i18n/pull/917) fix: improve IVueI18n interface ([@kazupon](https://github.com/kazupon))

#### :pencil: Documentation
* [#902](https://github.com/kazupon/vue-i18n/pull/902) docs: [RU] Translation update ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
* [#901](https://github.com/kazupon/vue-i18n/pull/901) docs: (zh) inverse $d $n ([@stan-chen](https://github.com/stan-chen))

#### Committers: 4
- Alexander Sokolov ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
- Rafał Chłodnicki ([@rchl](https://github.com/rchl))
- Stanley Chen ([@stan-chen](https://github.com/stan-chen))
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.18.1 (2020-05-27)

#### :bug: Bug Fixes
* [#896](https://github.com/kazupon/vue-i18n/pull/896) Fix flow types and enable flow types testing on CI ([@rchl](https://github.com/rchl))

#### Committers: 1
- Rafał Chłodnicki ([@rchl](https://github.com/rchl))


## v8.18.0 (2020-05-26)

#### :star: New Features
* [#892](https://github.com/kazupon/vue-i18n/pull/892) Add onComponentInstanceCreated constructor option ([@rchl](https://github.com/rchl))

#### :zap: Improved Features
* [#890](https://github.com/kazupon/vue-i18n/pull/890) chore: set up linting for typescript definitions ([@rchl](https://github.com/rchl))

#### Committers: 1
- Rafał Chłodnicki ([@rchl](https://github.com/rchl))


## v8.17.7 (2020-05-19)

#### :bug: Bug Fixes
* [#882](https://github.com/kazupon/vue-i18n/pull/882) fix v-t pluralisation when choice is 0 ([@mikejacoutot](https://github.com/mikejacoutot))

#### Committers: 1
- [@mikejacoutot](https://github.com/mikejacoutot)


## v8.17.6 (2020-05-15)

#### :bug: Bug Fixes
* [#880](https://github.com/kazupon/vue-i18n/pull/880) Don't delete _i18n in beforeDestroy ([@danimoh](https://github.com/danimoh))

#### :zap: Improved Features
* [#878](https://github.com/kazupon/vue-i18n/pull/878) Allow component interpolation without root element ([@danimoh](https://github.com/danimoh))

#### :pencil: Documentation
* [#875](https://github.com/kazupon/vue-i18n/pull/875) Add new 3rd party tool ([@danigayosog](https://github.com/danigayosog))
* [#872](https://github.com/kazupon/vue-i18n/pull/872) docs: fixes ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
* [#871](https://github.com/kazupon/vue-i18n/pull/871) update pluralization.md ([@Timibadass](https://github.com/Timibadass))

#### Committers: 4
- Alexander Sokolov ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
- Daniel ([@danigayosog](https://github.com/danigayosog))
- Timi Omoyeni ([@Timibadass](https://github.com/Timibadass))
- [@danimoh](https://github.com/danimoh)


## v8.17.5 (2020-05-10)

#### :bug: Bug Fixes
* [#869](https://github.com/kazupon/vue-i18n/pull/869) fix: not string method access error ([@kazupon](https://github.com/kazupon))

#### :pencil: Documentation
* [#867](https://github.com/kazupon/vue-i18n/pull/867) docs: [RU] Translation ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
* [#865](https://github.com/kazupon/vue-i18n/pull/865) improvement(docs): extend Hot reloading section ([@caugner](https://github.com/caugner))

#### Committers: 3
- Alexander Sokolov ([@Alex-Sokolov](https://github.com/Alex-Sokolov))
- Claas Augner ([@caugner](https://github.com/caugner))
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.17.4 (2020-04-26)

#### :bug: Bug Fixes
* [#859](https://github.com/kazupon/vue-i18n/pull/859) fix datetime format cache ([@kazupon](https://github.com/kazupon))
* [#858](https://github.com/kazupon/vue-i18n/pull/858) fix datetime and number format fallbacking ([@kazupon](https://github.com/kazupon))
* [#857](https://github.com/kazupon/vue-i18n/pull/857) fix: alternative array includes ([@kazupon](https://github.com/kazupon))

#### Committers: 1
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.17.3 (2020-04-19)

#### :zap: Improved Features
* [#846](https://github.com/kazupon/vue-i18n/pull/846) add key to postTranslation ([@dmitryuk](https://github.com/dmitryuk))

#### :pencil: Documentation
* [#847](https://github.com/kazupon/vue-i18n/pull/847) docs: Update /api/README.md ([@Alex-Sokolov](https://github.com/Alex-Sokolov))

#### Committers: 2
- Alexander Dmitryuk ([@dmitryuk](https://github.com/dmitryuk))
- Alexander Sokolov ([@Alex-Sokolov](https://github.com/Alex-Sokolov))


## v8.17.2 (2020-04-18)

#### :zap: Improved Features
* [#844](https://github.com/kazupon/vue-i18n/pull/844) Use plain object instead of Map, which is not supported in IE9/10 ([@exoego](https://github.com/exoego))

#### Committers: 1
- TATSUNO Yasuhiro ([@exoego](https://github.com/exoego))


## v8.17.1 (2020-04-16)

#### :bug: Bug Fixes
* [#840](https://github.com/kazupon/vue-i18n/pull/840) fix: altnative endsWidth ([@kazupon](https://github.com/kazupon))

#### :pencil: Documentation
* [#837](https://github.com/kazupon/vue-i18n/pull/837) Fix typo ([@ninofiliu](https://github.com/ninofiliu))

#### Committers: 2
- Nino Filiu ([@ninofiliu](https://github.com/ninofiliu))
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.17.0 (2020-04-11)

#### :star: New Features
* [#829](https://github.com/kazupon/vue-i18n/pull/829) #138 Fallback Locale as array for cascading fallbacks ([@mmokross](https://github.com/mmokross))

#### :pencil: Documentation
* [#834](https://github.com/kazupon/vue-i18n/pull/834) Add capitalize default modifier in doc ([@alexandreDavid](https://github.com/alexandreDavid))
* [#832](https://github.com/kazupon/vue-i18n/pull/832) fix in examples of "Custom pluralization" ([@Perlover](https://github.com/Perlover))

#### Committers: 4
- Alexandre David ([@alexandreDavid](https://github.com/alexandreDavid))
- Kobayashi Kazuhiro ([@kzhrk](https://github.com/kzhrk))
- Michael Mokroß ([@mmokross](https://github.com/mmokross))
- Perlover ([@Perlover](https://github.com/Perlover))


## v8.16.0 (2020-03-27)

#### :star: New Features
* [#822](https://github.com/kazupon/vue-i18n/pull/822) post translation hooking feature ([@kazupon](https://github.com/kazupon))

#### Committers: 1
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))


## v8.15.7 (2020-03-25)

#### :bug: Bug Fixes
* [#819](https://github.com/kazupon/vue-i18n/pull/819) Fixed bug when changing number format runtime ([@slischka](https://github.com/slischka))

#### Committers: 1
- Jiří Slischka ([@slischka](https://github.com/slischka))


## v8.15.6 (2020-03-23)

#### :bug: Bug Fixes
* [#817](https://github.com/kazupon/vue-i18n/pull/817) Bugfix : 'setLocaleMessage' / 'mergeLocaleMessage' doesn't work if 'warnHtmlInMessage' is set to 'error'  ([@aym3nb](https://github.com/aym3nb))

#### :pencil: Documentation
* [#816](https://github.com/kazupon/vue-i18n/pull/816) Update fallback.md ([@scoutrul](https://github.com/scoutrul))

#### Committers: 3
- Anton ([@scoutrul](https://github.com/scoutrul))
- Aymen Bareche ([@aym3nb](https://github.com/aym3nb))
- TATSUNO Yasuhiro ([@exoego](https://github.com/exoego))


## v8.15.5 (2020-03-07)

#### :star: Features
* [#787](https://github.com/kazupon/vue-i18n/pull/787) Add a 'capitalize' default modifier for linked message ([@charlesmass](https://github.com/charlesmass))

#### :zap: Improvement Features
* [#794](https://github.com/kazupon/vue-i18n/pull/794) Support returning 'string' type for customized interpolation ([@sihyeonn](https://github.com/sihyeonn))

#### :pencil: Documentation
* [#791](https://github.com/kazupon/vue-i18n/pull/791) Revise fallback.md ([@jlebar](https://github.com/jlebar))

#### Committers: 4
- Justin Lebar ([@jlebar](https://github.com/jlebar))
- L M ([@charlesmass](https://github.com/charlesmass))
- Sihyeon Jang ([@sihyeonn](https://github.com/sihyeonn))
- kazuya kawaguchi ([@kazupon](https://github.com/kazupon))

<a name="8.15.4"></a>
## [8.15.4](https://github.com/kazupon/vue-i18n/compare/v8.15.3...v8.15.4) (2020-02-25)


### :bug: Bug Fixes

* **index:** improve formatFallbackMessages code (#779) (#783) by [@masongzhi](https://github.com/masongzhi) ([53895b9](https://github.com/kazupon/vue-i18n/commit/53895b9)))

### :up: Updates

* some fixes ([8a9a950](https://github.com/kazupon/vue-i18n/commit/8a9a950))



<a name="8.15.3"></a>
## [8.15.3](https://github.com/kazupon/vue-i18n/compare/v8.15.2...v8.15.3) (2019-12-18)


### :zap: Improvements

* **index:** fix mergeLocaleMessage. add changes notification on merging with an empty target object ([#752](https://github.com/kazupon/vue-i18n/issues/752)) by [@jekill](https://github.com/jekill) ([048eac5](https://github.com/kazupon/vue-i18n/commit/048eac5)), closes [#752](https://github.com/kazupon/vue-i18n/issues/752)



<a name="8.15.2"></a>
## [8.15.2](https://github.com/kazupon/vue-i18n/compare/v8.15.1...v8.15.2) (2019-12-18)


### :bug: Bug Fixes

* **index:** Fix exception when using unit number formatting by [@simonjodet](https://github.com/simonjodet) ([194b801](https://github.com/kazupon/vue-i18n/commit/194b801)), closes [#750](https://github.com/kazupon/vue-i18n/issues/750) [#751](https://github.com/kazupon/vue-i18n/issues/751)



<a name="8.15.1"></a>
## [8.15.1](https://github.com/kazupon/vue-i18n/compare/v8.15.0...v8.15.1) (2019-11-27)


### :zap: Improvements

* **mixin:** change to custom blocks parse error ([a9858be](https://github.com/kazupon/vue-i18n/commit/a9858be))



<a name="8.15.0"></a>
# [8.15.0](https://github.com/kazupon/vue-i18n/compare/v8.14.1...v8.15.0) (2019-10-16)


### :star: New Features

* Add constructor option for custom modifiers ([#724](https://github.com/kazupon/vue-i18n/issues/724)) by [@epaezrubio](https://github.com/epaezrubio) ([3217212](https://github.com/kazupon/vue-i18n/commit/3217212)), closes [#724](https://github.com/kazupon/vue-i18n/issues/724)



<a name="8.14.1"></a>
## [8.14.1](https://github.com/kazupon/vue-i18n/compare/v8.14.0...v8.14.1) (2019-09-12)


### :bug: Bug Fixes

* **path:** fix branket key error ([8d2aba7](https://github.com/kazupon/vue-i18n/commit/8d2aba7))
* **component:** Fix interpolation component when there are empty text nodes ([547cdd1](https://github.com/kazupon/vue-i18n/commit/547cdd1)) by [@Demivan](https://github.com/Demivan)



<a name="8.14.0"></a>
# [8.14.0](https://github.com/kazupon/vue-i18n/compare/v8.13.0...v8.14.0) (2019-08-12)


### :star: New Features

* fallback formatting ([#637](https://github.com/kazupon/vue-i18n/issues/637)) by [@sebwas](https://github.com/sebwas) ([bf9929c](https://github.com/kazupon/vue-i18n/commit/bf9929c)), closes [#637](https://github.com/kazupon/vue-i18n/issues/637)
* support slots syntax for component interpolation ([#685](https://github.com/kazupon/vue-i18n/issues/685)) by [@aavondet](https://github.com/aavondet) ([71ca843](https://github.com/kazupon/vue-i18n/commit/71ca843)), closes [#685](https://github.com/kazupon/vue-i18n/issues/685)



<a name="8.13.0"></a>
# [8.13.0](https://github.com/kazupon/vue-i18n/compare/v8.12.0...v8.13.0) (2019-08-09)


### :star: New Features

* datetime/number formats fallback warning filter ([46de19e](https://github.com/kazupon/vue-i18n/commit/46de19e)), closes [#558](https://github.com/kazupon/vue-i18n/issues/558)
* fallback translation warning filter ([69fc798](https://github.com/kazupon/vue-i18n/commit/69fc798))
* translation missing warning filter ([666dc9d](https://github.com/kazupon/vue-i18n/commit/666dc9d))



<a name="8.12.0"></a>
# [8.12.0](https://github.com/kazupon/vue-i18n/compare/v8.11.2...v8.12.0) (2019-07-09)


### :star: New Features

* **mixin:** shared locale messages feature ([82543de](https://github.com/kazupon/vue-i18n/commit/82543de))


### :zap: Improvements

* **typing:** sharedMessages option type ([6967a15](https://github.com/kazupon/vue-i18n/commit/6967a15))



<a name="8.11.2"></a>
## [8.11.2](https://github.com/kazupon/vue-i18n/compare/v8.11.1...v8.11.2) (2019-04-30)


### :bug: Bug Fixes

* bug(mixin): fix SSR memory leak by moving subscribeDataChanging calls into beforeMount ([#572](https://github.com/kazupon/vue-i18n/issues/572)) by [@Pindar](https://github.com/Pindar) ([32b5795](https://github.com/kazupon/vue-i18n/commit/32b5795)), closes [#572](https://github.com/kazupon/vue-i18n/issues/572)



<a name="8.11.1"></a>
## [8.11.1](https://github.com/kazupon/vue-i18n/compare/v8.11.0...v8.11.1) (2019-04-26)


### :bug: Bug Fixes

* fix ES Modules distribution ([bb631a1](https://github.com/kazupon/vue-i18n/commit/bb631a1))



<a name="8.11.0"></a>
# [8.11.0](https://github.com/kazupon/vue-i18n/compare/v8.10.0...v8.11.0) (2019-04-26)


### :star: New Features

* ES modules for browser ([#561](https://github.com/kazupon/vue-i18n/issues/561)) ([c9b9adf](https://github.com/kazupon/vue-i18n/commit/c9b9adf)), closes [#561](https://github.com/kazupon/vue-i18n/issues/561)
* HTML locale message warning option ([#567](https://github.com/kazupon/vue-i18n/issues/567)) ([4aecf03](https://github.com/kazupon/vue-i18n/commit/4aecf03)), closes [#567](https://github.com/kazupon/vue-i18n/issues/567)



<a name="8.10.0"></a>
# [8.10.0](https://github.com/kazupon/vue-i18n/compare/v8.9.0...v8.10.0) (2019-03-28)


### :star: New Features

* **number:** i18n-n functional component ([#541](https://github.com/kazupon/vue-i18n/issues/541)) by [@bponomarenko](https://github.com/bponomarenko) ([b33579d](https://github.com/kazupon/vue-i18n/commit/b33579d)), closes [#541](https://github.com/kazupon/vue-i18n/issues/541)
* **path:** Keypath should parse if sub path contains spaces. ([#533](https://github.com/kazupon/vue-i18n/issues/533)) by [@exoego](https://github.com/exoego) ([640daaf](https://github.com/kazupon/vue-i18n/commit/640daaf)), closes [#533](https://github.com/kazupon/vue-i18n/issues/533)


### :zap: Improvements

* **number:** support data fall through in i18n-n ([#545](https://github.com/kazupon/vue-i18n/issues/545)) ([71cadbf](https://github.com/kazupon/vue-i18n/commit/71cadbf)), closes [#545](https://github.com/kazupon/vue-i18n/issues/545)


### :pencil: docs

* **vuepress:** translate documents for chinese ([#536](https://github.com/kazupon/vue-i18n/issues/536)) by [@xuhongbo](https://github.com/xuhongbo) ([ccf29f8](https://github.com/kazupon/vue-i18n/commit/ccf29f8)), closes [#536](https://github.com/kazupon/vue-i18n/issues/536) [#531](https://github.com/kazupon/vue-i18n/issues/531) [#1](https://github.com/kazupon/vue-i18n/issues/1) [#533](https://github.com/kazupon/vue-i18n/issues/533) [#540](https://github.com/kazupon/vue-i18n/issues/540) [#541](https://github.com/kazupon/vue-i18n/issues/541) [#1](https://github.com/kazupon/vue-i18n/issues/1) [#2](https://github.com/kazupon/vue-i18n/issues/2)


<a name="8.9.0"></a>
# [8.9.0](https://github.com/kazupon/vue-i18n/compare/v8.8.2...v8.9.0) (2019-03-08)


### :bug: Bug Fixes

* **index:** Fix [#515](https://github.com/kazupon/vue-i18n/issues/515) empty string not returning true ([#525](https://github.com/kazupon/vue-i18n/issues/525)) by [@kimuraz](https://github.com/kimuraz) ([396c5ca](https://github.com/kazupon/vue-i18n/commit/396c5ca)), closes [#515](https://github.com/kazupon/vue-i18n/issues/515) [#525](https://github.com/kazupon/vue-i18n/issues/525) [#515](https://github.com/kazupon/vue-i18n/issues/515)


### :star: New Features

* **index:** add availableLocales (related issue [#193](https://github.com/kazupon/vue-i18n/issues/193), PR [#528](https://github.com/kazupon/vue-i18n/issues/528)) by [@exoego](https://github.com/exoego) ([8f75b1f](https://github.com/kazupon/vue-i18n/commit/8f75b1f)), closes [#193](https://github.com/kazupon/vue-i18n/issues/193) [#528](https://github.com/kazupon/vue-i18n/issues/528) [#193](https://github.com/kazupon/vue-i18n/issues/193) [#193](https://github.com/kazupon/vue-i18n/issues/193) [#193](https://github.com/kazupon/vue-i18n/issues/193) [#193](https://github.com/kazupon/vue-i18n/issues/193)


### :zap: Improvements

* **flowtype:** Fix missing type declarations in flow type ([#529](https://github.com/kazupon/vue-i18n/issues/529)) by [@exoego](https://github.com/exoego) ([4173764](https://github.com/kazupon/vue-i18n/commit/4173764)), closes [#529](https://github.com/kazupon/vue-i18n/issues/529)



<a name="8.8.2"></a>
## [8.8.2](https://github.com/kazupon/vue-i18n/compare/v8.8.1...v8.8.2) (2019-02-17)


### :bug: Bug Fixes

* **mixin:** fix memory leak ([135058d](https://github.com/kazupon/vue-i18n/commit/135058d)), closes [#514](https://github.com/kazupon/vue-i18n/issues/514)



<a name="8.8.1"></a>
## [8.8.1](https://github.com/kazupon/vue-i18n/compare/v8.8.0...v8.8.1) (2019-02-10)


### :bug: Bug Fixes

* **index:** fixed [#478](https://github.com/kazupon/vue-i18n/issues/478) ([#518](https://github.com/kazupon/vue-i18n/issues/518)) by [@stroncium](https://github.com/stroncium) ([469edd9](https://github.com/kazupon/vue-i18n/commit/469edd9)), closes [#478](https://github.com/kazupon/vue-i18n/issues/478) [#518](https://github.com/kazupon/vue-i18n/issues/518) [#478](https://github.com/kazupon/vue-i18n/issues/478)


### :zap: Improvements

* **flowtype:** update typings ([44e04e7](https://github.com/kazupon/vue-i18n/commit/44e04e7))
* **typescript:** update typings ([dee35b9](https://github.com/kazupon/vue-i18n/commit/dee35b9))



<a name="8.8.0"></a>
# [8.8.0](https://github.com/kazupon/vue-i18n/compare/v8.7.0...v8.8.0) (2019-01-29)


### :bug: Bug Fixes

* **index:** fix flat path based key issue ([bed9c39](https://github.com/kazupon/vue-i18n/commit/bed9c39)), closes [#349](https://github.com/kazupon/vue-i18n/issues/349)
* **mixin:** fix beforeDestroy can not find this.$t ([#500](https://github.com/kazupon/vue-i18n/issues/500)) by [@masongzhi](https://github.com/masongzhi) ([311b8f3](https://github.com/kazupon/vue-i18n/commit/311b8f3)), closes [#500](https://github.com/kazupon/vue-i18n/issues/500)


### :zap: Improvements

* **directive:** Fix typo on warning message ([#509](https://github.com/kazupon/vue-i18n/issues/509)) by [@kimuraz](https://github.com/kimuraz) ([e879024](https://github.com/kazupon/vue-i18n/commit/e879024)), closes [#509](https://github.com/kazupon/vue-i18n/issues/509)
* **index:** silence fallback warnings ([#510](https://github.com/kazupon/vue-i18n/issues/510)) by [@SzNagyMisu](https://github.com/SzNagyMisu) ([ddc0c79](https://github.com/kazupon/vue-i18n/commit/ddc0c79)), closes [#510](https://github.com/kazupon/vue-i18n/issues/510) [#139](https://github.com/kazupon/vue-i18n/issues/139)



<a name="8.7.0"></a>
# [8.7.0](https://github.com/kazupon/vue-i18n/compare/v8.6.0...v8.7.0) (2019-01-02)


### :zap: Improvements

* **directive:** Preserve directive content ([#495](https://github.com/kazupon/vue-i18n/issues/495)) by [@bponomarenko](https://github.com/bponomarenko) ([c29edba](https://github.com/kazupon/vue-i18n/commit/c29edba)), closes [#495](https://github.com/kazupon/vue-i18n/issues/495) [#408](https://github.com/kazupon/vue-i18n/issues/408) [#408](https://github.com/kazupon/vue-i18n/issues/408)



<a name="8.6.0"></a>
# [8.6.0](https://github.com/kazupon/vue-i18n/compare/v8.5.0...v8.6.0) (2018-12-25)


### :bug: Bug Fixes

* **pluralization:** inherit pluralization rules ⚠ ([#493](https://github.com/kazupon/vue-i18n/issues/493)) by [@Raiondesu](https://github.com/Raiondesu) ([7a23f32](https://github.com/kazupon/vue-i18n/commit/7a23f32)), closes [#493](https://github.com/kazupon/vue-i18n/issues/493)


### :zap: Improvements

* **format:** Add the path as argument to the custom formatter ([#489](https://github.com/kazupon/vue-i18n/issues/489)) by [@Raiondesu](https://github.com/Raiondesu) ([b9437ea](https://github.com/kazupon/vue-i18n/commit/b9437ea)), closes [#489](https://github.com/kazupon/vue-i18n/issues/489) [#484](https://github.com/kazupon/vue-i18n/issues/484) [#484](https://github.com/kazupon/vue-i18n/issues/484)



<a name="8.5.0"></a>
# [8.5.0](https://github.com/kazupon/vue-i18n/compare/v8.4.0...v8.5.0) (2018-12-17)


### :bug: Bug Fixes

* **index:** evaluate availabilities lazily (fix [#477](https://github.com/kazupon/vue-i18n/issues/477)) ([#483](https://github.com/kazupon/vue-i18n/issues/483)) by [@gamtiq](https://github.com/gamtiq) ([b66f02e](https://github.com/kazupon/vue-i18n/commit/b66f02e)), closes [#477](https://github.com/kazupon/vue-i18n/issues/477) [#483](https://github.com/kazupon/vue-i18n/issues/483)


### :zap: Improvements

* **index:** Allow pluralization customization via constructor options (closes [#464](https://github.com/kazupon/vue-i18n/issues/464)) ([#482](https://github.com/kazupon/vue-i18n/issues/482)) by [@Raiondesu](https://github.com/Raiondesu) ([ef4b1a6](https://github.com/kazupon/vue-i18n/commit/ef4b1a6)), closes [#464](https://github.com/kazupon/vue-i18n/issues/464) [#482](https://github.com/kazupon/vue-i18n/issues/482) [#464](https://github.com/kazupon/vue-i18n/issues/464) [#464](https://github.com/kazupon/vue-i18n/issues/464) [#464](https://github.com/kazupon/vue-i18n/issues/464) [#464](https://github.com/kazupon/vue-i18n/issues/464) [#451](https://github.com/kazupon/vue-i18n/issues/451)
* **index:** make silentTranslationWarn work for dates and numbers too ([#481](https://github.com/kazupon/vue-i18n/issues/481)) by [@Raiondesu](https://github.com/Raiondesu) ([402092b](https://github.com/kazupon/vue-i18n/commit/402092b)), closes [#481](https://github.com/kazupon/vue-i18n/issues/481)
* **types:** typed autocomplete in date and number format options ([#485](https://github.com/kazupon/vue-i18n/issues/485)) by [@Raiondesu](https://github.com/Raiondesu) ([e2e5993](https://github.com/kazupon/vue-i18n/commit/e2e5993)), closes [#485](https://github.com/kazupon/vue-i18n/issues/485)



<a name="8.4.0"></a>
# [8.4.0](https://github.com/kazupon/vue-i18n/compare/v8.3.2...v8.4.0) (2018-11-30)


### :star: New Features

* **index:** Add linked message formatting ([#467](https://github.com/kazupon/vue-i18n/issues/467)) by [@exoego](https://github.com/exoego) ([776b81b](https://github.com/kazupon/vue-i18n/commit/776b81b)), closes [#467](https://github.com/kazupon/vue-i18n/issues/467)



<a name="8.3.2"></a>
## [8.3.2](https://github.com/kazupon/vue-i18n/compare/v8.3.1...v8.3.2) (2018-11-16)


### :chart_with_upwards_trend: Performance Fixes

* **index:** Optimize unnecessary capturing. ([#462](https://github.com/kazupon/vue-i18n/issues/462)) by [@exoego](https://github.com/exoego) ([116845e](https://github.com/kazupon/vue-i18n/commit/116845e)), closes [#462](https://github.com/kazupon/vue-i18n/issues/462)



<a name="8.3.1"></a>
## [8.3.1](https://github.com/kazupon/vue-i18n/compare/v8.3.0...v8.3.1) (2018-11-08)


### :bug: Bug Fixes

* **directive:** fix cannnot update with v-t when had been changed locale message ([4895a2e](https://github.com/kazupon/vue-i18n/commit/4895a2e)), closes [#450](https://github.com/kazupon/vue-i18n/issues/450)
* **index:** fix merge bug ([1798490](https://github.com/kazupon/vue-i18n/commit/1798490)), closes [#458](https://github.com/kazupon/vue-i18n/issues/458)
* **missing:** fix vm argument passing ([dc48099](https://github.com/kazupon/vue-i18n/commit/dc48099)), closes [#453](https://github.com/kazupon/vue-i18n/issues/453)


### :zap: Improvements

* Optimize path.js and format.js ([#456](https://github.com/kazupon/vue-i18n/issues/456)) by [@exoego](https://github.com/exoego) ([639453c](https://github.com/kazupon/vue-i18n/commit/639453c)), closes [#456](https://github.com/kazupon/vue-i18n/issues/456)



<a name="8.3.0"></a>
# [8.3.0](https://github.com/kazupon/vue-i18n/compare/v8.2.1...v8.3.0) (2018-10-29)


### :zap: Improvements

* **pluralization:** Extendable pluralization by [@Raiondesu](https://github.com/Raiondesu) ([bbab90b](https://github.com/kazupon/vue-i18n/commit/bbab90b))



<a name="8.2.1"></a>
## [8.2.1](https://github.com/kazupon/vue-i18n/compare/v8.2.0...v8.2.1) (2018-10-15)


### :bug: Bug Fixes

* **extend:** fix TypeError: Cannot redefine property: $i18n ([#422](https://github.com/kazupon/vue-i18n/issues/422)) by [@HadiChen](https://github.com/HadiChen) ([cb19082](https://github.com/kazupon/vue-i18n/commit/cb19082)), closes [#422](https://github.com/kazupon/vue-i18n/issues/422)


### :zap: Improvements

* **index:** Suppress some warnings in production: smaller min.js and performance gain. ([#441](https://github.com/kazupon/vue-i18n/issues/441)) by @	exoego ([43931f5](https://github.com/kazupon/vue-i18n/commit/43931f5)), closes [#441](https://github.com/kazupon/vue-i18n/issues/441)



<a name="8.2.0"></a>
# [8.2.0](https://github.com/kazupon/vue-i18n/compare/v8.1.1...v8.2.0) (2018-10-13)


### :bug: Bug Fixes

* **index:** Add warning for circular reference in linked message ([#438](https://github.com/kazupon/vue-i18n/issues/438)) by [@exoego](https://github.com/exoego) ([7583485](https://github.com/kazupon/vue-i18n/commit/7583485)), closes [#438](https://github.com/kazupon/vue-i18n/issues/438)


### :zap: Improvements

* **index:** Allow escaping link key like @:(foo.bar). ([#437](https://github.com/kazupon/vue-i18n/issues/437)) by [@exoego](https://github.com/exoego) ([acfc458](https://github.com/kazupon/vue-i18n/commit/acfc458)), closes [#437](https://github.com/kazupon/vue-i18n/issues/437)
* **index:** Pre-defined named arguments for Pluraization ([#440](https://github.com/kazupon/vue-i18n/issues/440)) by [@exoego](https://github.com/exoego) ([e84f0fb](https://github.com/kazupon/vue-i18n/commit/e84f0fb)), closes [#440](https://github.com/kazupon/vue-i18n/issues/440)
* **path:** Allow non-ascii chars including numbers. ([#436](https://github.com/kazupon/vue-i18n/issues/436)) by [@exoego](https://github.com/exoego) ([a556c58](https://github.com/kazupon/vue-i18n/commit/a556c58)), closes [#436](https://github.com/kazupon/vue-i18n/issues/436)



<a name="8.1.1"></a>
## [8.1.1](https://github.com/kazupon/vue-i18n/compare/v8.1.0...v8.1.1) (2018-10-12)


### :bug: Bug Fixes

* **build:** fix rollup building issues ([1a1958a](https://github.com/kazupon/vue-i18n/commit/1a1958a))
* **format:** Should warn as unknown if named format is not closed. ([#435](https://github.com/kazupon/vue-i18n/issues/435)) by [@exoego](https://github.com/exoego) ([d1f6ed0](https://github.com/kazupon/vue-i18n/commit/d1f6ed0)), closes [#435](https://github.com/kazupon/vue-i18n/issues/435)
* **install:** fix cannot redfine error ([6d5ec61](https://github.com/kazupon/vue-i18n/commit/6d5ec61))


### :zap: Improvements

* **package.json:** tree shaking optimization ([38948c5](https://github.com/kazupon/vue-i18n/commit/38948c5))



<a name="8.1.0"></a>
# [8.1.0](https://github.com/kazupon/vue-i18n/compare/v8.0.0...v8.1.0) (2018-09-03)


### :bug: Bug Fixes

* **install:** add support for Vue.extend vue-i18n instance ([#420](https://github.com/kazupon/vue-i18n/issues/420)) by [@jaredzhu1993](https://github.com/jaredzhu1993) ([a60ea8b](https://github.com/kazupon/vue-i18n/commit/a60ea8b)), closes [#420](https://github.com/kazupon/vue-i18n/issues/420)


### :zap: Improvements

* **warnings:** make warning messages clearer ([#396](https://github.com/kazupon/vue-i18n/issues/396)) by [@kimuraz](https://github.com/kimuraz) ([79eee1b](https://github.com/kazupon/vue-i18n/commit/79eee1b)), closes [#396](https://github.com/kazupon/vue-i18n/issues/396)



<a name="8.0.0"></a>
# [8.0.0](https://github.com/kazupon/vue-i18n/compare/v7.8.1...v8.0.0) (2018-06-23)


### :boom: Breaking changes

* **extend:** fix this context binding ([aa0e831](https://github.com/kazupon/vue-i18n/commit/aa0e831)), closes [#306](https://github.com/kazupon/vue-i18n/issues/306) [#286](https://github.com/kazupon/vue-i18n/issues/286) [#259](https://github.com/kazupon/vue-i18n/issues/259), revert [#260](https://github.com/kazupon/vue-i18n/issues/260)

Note that you need to guarantee this context equal to component instance in lifecycle methods (e.g. in `data` options, `const $t = this.$t.bind(this)`).

```js
export default {
  data () {
    const $t = this.$t.bind(this)
    return { msg: $t('msg') }
  }
}
```

see the [API docs](https://kazupon.github.io/vue-i18n/api/)

### :bug: Bug Fixes

* bug(directive): fix guard checking at unbind ([c74888c](https://github.com/kazupon/vue-i18n/commit/c74888c)), closes [#340](https://github.com/kazupon/vue-i18n/issues/340)


### NOTE

* extend:



<a name="7.8.1"></a>
## [7.8.1](https://github.com/kazupon/vue-i18n/compare/v7.8.0...v7.8.1) (2018-06-18)


### :bug: Bug Fixes

* **directive:** fix cannot unbind bug ([105888d](https://github.com/kazupon/vue-i18n/commit/105888d)), closes [#377](https://github.com/kazupon/vue-i18n/issues/377)



<a name="7.8.0"></a>
# [7.8.0](https://github.com/kazupon/vue-i18n/compare/v7.7.0...v7.8.0) (2018-06-01)


### :zap: Improvements

* **typescript:** add type exportings ([a7cb8da](https://github.com/kazupon/vue-i18n/commit/a7cb8da))



<a name="7.7.0"></a>
# [7.7.0](https://github.com/kazupon/vue-i18n/compare/v7.6.0...v7.7.0) (2018-05-20)


### :zap: Improvements

* **index:** resource reactivity ([887a137](https://github.com/kazupon/vue-i18n/commit/887a137)), closes [#253](https://github.com/kazupon/vue-i18n/issues/253)
* **typescript:** Fix typings in components ([#344](https://github.com/kazupon/vue-i18n/issues/344)) by [@Demivan](https://github.com/Demivan) ([2402893](https://github.com/kazupon/vue-i18n/commit/2402893)), closes [#344](https://github.com/kazupon/vue-i18n/issues/344)



<a name="7.6.0"></a>
# [7.6.0](https://github.com/kazupon/vue-i18n/compare/v7.5.0...v7.6.0) (2018-03-13)


### :zap: Improvements

* **index:** support retunable missing handler ([#256](https://github.com/kazupon/vue-i18n/issues/256)) by [@houd1ni](https://github.com/houd1ni) ([9fbe467](https://github.com/kazupon/vue-i18n/commit/9fbe467))
* **typescript:** update TranslateResult type interface ([dffc678](https://github.com/kazupon/vue-i18n/commit/dffc678))



<a name="7.5.0"></a>
# [7.5.0](https://github.com/kazupon/vue-i18n/compare/v7.4.2...v7.5.0) (2018-03-11)


### :star: New Features

* **directive:** Add pluralization feature to directive ([#304](https://github.com/kazupon/vue-i18n/issues/304)) by [@SirLamer](https://github.com/SirLamer) ([8378859](https://github.com/kazupon/vue-i18n/commit/8378859))


### :zap: Improvements

* **flow:** update TranslateResult type interface ([59f4658](https://github.com/kazupon/vue-i18n/commit/59f4658))
* **index:** support object localization ([#311](https://github.com/kazupon/vue-i18n/issues/311)) by [@manniL](https://github.com/manniL) ([99e5006](https://github.com/kazupon/vue-i18n/commit/99e5006))
* **missing:** Add interpolation values to missing handler ([#308](https://github.com/kazupon/vue-i18n/issues/308)) by [@sebwas](https://github.com/sebwas) ([b912d8a](https://github.com/kazupon/vue-i18n/commit/b912d8a))
* **numberformat:** Explicit number format options ([#305](https://github.com/kazupon/vue-i18n/issues/305)) by [@bponomarenko](https://github.com/bponomarenko) ([aa07450](https://github.com/kazupon/vue-i18n/commit/aa07450))



<a name="7.4.2"></a>
## [7.4.2](https://github.com/kazupon/vue-i18n/compare/v7.4.1...v7.4.2) (2018-02-01)


### :zap: Improvements

* **index:** Fixes global auto installation ([#291](https://github.com/kazupon/vue-i18n/issues/291)) by [@emileber](https://github.com/emileber) ([2f016ff](https://github.com/kazupon/vue-i18n/commit/2f016ff)), closes [#291](https://github.com/kazupon/vue-i18n/issues/291)



<a name="7.4.1"></a>
## [7.4.1](https://github.com/kazupon/vue-i18n/compare/v7.4.0...v7.4.1) (2018-01-25)


### :bug: Bug Fixes

* fix cannot react ([2a8ea1c](https://github.com/kazupon/vue-i18n/commit/2a8ea1c)), closes [#261](https://github.com/kazupon/vue-i18n/issues/261)


### :zap: Improvements

* **formatter:** interpolate messages without values ([#282](https://github.com/kazupon/vue-i18n/issues/282)) by [@cb8](https://github.com/cb8) ([b792ce2](https://github.com/kazupon/vue-i18n/commit/b792ce2))



<a name="7.4.0"></a>
# [7.4.0](https://github.com/kazupon/vue-i18n/compare/v7.3.4...v7.4.0) (2018-01-10)


### :star: New Features

* **typescript:** Allow module augmentation ([#273](https://github.com/kazupon/vue-i18n/issues/273)) by [@CKGrafico](https://github.com/CKGrafico) ([4371344](https://github.com/kazupon/vue-i18n/commit/4371344))



<a name="7.3.4"></a>
## [7.3.4](https://github.com/kazupon/vue-i18n/compare/v7.3.3...v7.3.4) (2018-01-07)


### :bug: Bug Fixes

* **formatter:** Inherit formatter ([#269](https://github.com/kazupon/vue-i18n/issues/269)) by [@podkot](https://github.com/podkot) ([26a33ad](https://github.com/kazupon/vue-i18n/commit/26a33ad))



<a name="7.3.3"></a>
## [7.3.3](https://github.com/kazupon/vue-i18n/compare/v7.3.2...v7.3.3) (2017-12-19)


### :bug: Bug Fixes

* **extend:** Fix this not found [#259](https://github.com/kazupon/vue-i18n/issues/259) ([#260](https://github.com/kazupon/vue-i18n/issues/260)) by [@lzxb](https://github.com/lzxb) ([c29007e](https://github.com/kazupon/vue-i18n/commit/c29007e)), closes [#259](https://github.com/kazupon/vue-i18n/issues/259) [#260](https://github.com/kazupon/vue-i18n/issues/260)
* **types:** fix using old export ([#263](https://github.com/kazupon/vue-i18n/issues/263)) by [@jmigual](https://github.com/jmigual) ([b295fee](https://github.com/kazupon/vue-i18n/commit/b295fee)), closes [#263](https://github.com/kazupon/vue-i18n/issues/263)


<a name="7.3.2"></a>
## [7.3.2](https://github.com/kazupon/vue-i18n/compare/v7.3.1...v7.3.2) (2017-10-19)


### :zap: Improvements

* **typescript:** fix import problem of vue2.5 because of the types update ([#238](https://github.com/kazupon/vue-i18n/issues/238)) by [@peterchealse](https://github.com/peterchealse) ([cb98347](https://github.com/kazupon/vue-i18n/commit/cb98347)), closes [#238](https://github.com/kazupon/vue-i18n/issues/238)



<a name="7.3.1"></a>
## [7.3.1](https://github.com/kazupon/vue-i18n/compare/v7.3.0...v7.3.1) (2017-10-04)


### :bug: Bug Fixes

* **directive:** fix cannot locale reactivity ([e1fc12e](https://github.com/kazupon/vue-i18n/commit/e1fc12e)), closes [#227](https://github.com/kazupon/vue-i18n/issues/227)



<a name="7.3.0"></a>
# [7.3.0](https://github.com/kazupon/vue-i18n/compare/v7.2.0...v7.3.0) (2017-09-22)


### :star: New Features

* **directives:** support v-t custom directive (welcome back!) ([af9a2e7](https://github.com/kazupon/vue-i18n/commit/af9a2e7))


### :up: Updates

* **typing:** fix flowtype ([fa06f44](https://github.com/kazupon/vue-i18n/commit/fa06f44))



<a name="7.2.0"></a>
# [7.2.0](https://github.com/kazupon/vue-i18n/compare/v7.1.2...v7.2.0) (2017-08-28)


### :star: New Features

* **interpolation:** list formatting refactor and places/place feature ([#218](https://github.com/kazupon/vue-i18n/issues/218)) by [@myst729](https://github.com/myst729) ([0f0f3ff](https://github.com/kazupon/vue-i18n/commit/0f0f3ff))



<a name="7.1.2"></a>
## [7.1.2](https://github.com/kazupon/vue-i18n/compare/v7.1.1...v7.1.2) (2017-08-25)


### :zap: Improvements

* **interpolation:** skip non-element VNode in interpolation ([#211](https://github.com/kazupon/vue-i18n/issues/211)) by [@myst729](https://github.com/myst729) ([6be1756](https://github.com/kazupon/vue-i18n/commit/6be1756))



<a name="7.1.1"></a>
## [7.1.1](https://github.com/kazupon/vue-i18n/compare/v7.1.0...v7.1.1) (2017-08-03)


### :bug: Bug Fixes

* **mixin:** fix cannot setup VueI18n instance ([13585a4](https://github.com/kazupon/vue-i18n/commit/13585a4)), closes [#203](https://github.com/kazupon/vue-i18n/issues/203)



<a name="7.1.0"></a>
# [7.1.0](https://github.com/kazupon/vue-i18n/compare/v7.0.5...v7.1.0) (2017-07-30)


### :zap: Improvements

* **custom-block:** support multiple custom blocks ([ab955a5](https://github.com/kazupon/vue-i18n/commit/ab955a5)), closes [#189](https://github.com/kazupon/vue-i18n/issues/189)



<a name="7.0.5"></a>
## [7.0.5](https://github.com/kazupon/vue-i18n/compare/v7.0.4...v7.0.5) (2017-07-08)


### :bug: Bug Fixes

* **format:** fix cannot collectly parse percent ([fc71eda](https://github.com/kazupon/vue-i18n/commit/fc71eda)), closes [#191](https://github.com/kazupon/vue-i18n/issues/191)



<a name="7.0.4"></a>
## [7.0.4](https://github.com/kazupon/vue-i18n/compare/v7.0.3...v7.0.4) (2017-07-01)


### :bug: Bug Fixes

* **link:** fix ie traverse custom Array.prototype method ([#188](https://github.com/kazupon/vue-i18n/issues/188)) by [@632781460](https://github.com/632781460) ([d3b308b](https://github.com/kazupon/vue-i18n/commit/d3b308b)), closes [#188](https://github.com/kazupon/vue-i18n/issues/188)


### :chart_with_upwards_trend: Performance Fixes

* fix blocking at beforeDestroy ([570b215](https://github.com/kazupon/vue-i18n/commit/570b215)), closes [#187](https://github.com/kazupon/vue-i18n/issues/187)



<a name="7.0.3"></a>
## [7.0.3](https://github.com/kazupon/vue-i18n/compare/v7.0.2...v7.0.3) (2017-06-13)


### :bug: Bug Fixes

* **fallback:** fix cannot fallabck localization ([694e6f2](https://github.com/kazupon/vue-i18n/commit/694e6f2)), closes [#176](https://github.com/kazupon/vue-i18n/issues/176)
* **fallback:** fix fallback locale issue ([d9ceddc](https://github.com/kazupon/vue-i18n/commit/d9ceddc)), closes [#174](https://github.com/kazupon/vue-i18n/issues/174)
* **linked:** fix cannot fallback linked localization ([0c572f3](https://github.com/kazupon/vue-i18n/commit/0c572f3)), closes [#172](https://github.com/kazupon/vue-i18n/issues/172)



<a name="7.0.2"></a>
## [7.0.2](https://github.com/kazupon/vue-i18n/compare/v7.0.1...v7.0.2) (2017-06-10)


### :bug: Bug Fixes

* **sfc:** fix cannot parse custom block locale messages ([32eb3a7](https://github.com/kazupon/vue-i18n/commit/32eb3a7)), closes [#173](https://github.com/kazupon/vue-i18n/issues/173)



<a name="7.0.1"></a>
## [7.0.1](https://github.com/kazupon/vue-i18n/compare/v7.0.0...v7.0.1) (2017-06-04)


### :bug: Bug Fixes

* fix cannat single file component translation ([687d406](https://github.com/kazupon/vue-i18n/commit/687d406)), closes [#169](https://github.com/kazupon/vue-i18n/issues/169)
* fix cannnot resolve linked localization with component interpolation ([c973619](https://github.com/kazupon/vue-i18n/commit/c973619)), closes [#171](https://github.com/kazupon/vue-i18n/issues/171)
* fix datetime and number fallback localization ([be9e1bd](https://github.com/kazupon/vue-i18n/commit/be9e1bd)), closes [#168](https://github.com/kazupon/vue-i18n/issues/168)
* fix linked translation with using hyphen or underscore keypath ([6e9f151](https://github.com/kazupon/vue-i18n/commit/6e9f151)), closes [#170](https://github.com/kazupon/vue-i18n/issues/170)


<a name="7.0.0"></a>
# [7.0.0](https://github.com/kazupon/vue-i18n/compare/v7.0.0-rc.1...v7.0.0) (2017-05-29)

:tada: :tada: :tada:

See the [docs](https://kazupon.github.io/vue-i18n/en/)


### :star: New Features

* **datetime localization:**
    * [documentation](https://github.com/kazupon/vue-i18n/blob/dev/gitbook/en/datetime.md)
    * [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/datetime)
* **number localization:**
    * [documentation](https://github.com/kazupon/vue-i18n/blob/dev/gitbook/en/number.md)
    * [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/number)
* **component interpolation:**
    * [documentation](https://github.com/kazupon/vue-i18n/blob/dev/gitbook/en/interpolation.md)
    * [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/interpolation)
* **typescript:**
    * [type definitions](https://github.com/kazupon/vue-i18n/blob/dev/types/index.d.ts)


### :chart_with_upwards_trend: Performance Fixes

* fix translation performance issue ([6032a51](https://github.com/kazupon/vue-i18n/commit/6032a51))


### :zap: Improvements

* **path:** tweak for ssr


### :boom: Breaking changes

* **format:** re-impelement formatter
* **formatter:** change method nam
* **flowtype:** fix locale message related type changing and remove underscore type


### :bug: Bug Fixes

* **examples:** fix ssr demo ([059034f](https://github.com/kazupon/vue-i18n/commit/059034f))
* **pluralization:** fix default choice ([240cfed](https://github.com/kazupon/vue-i18n/commit/240cfed))


<a name="7.0.0-rc.1"></a>
# [7.0.0-rc.1](https://github.com/kazupon/vue-i18n/compare/v7.0.0-beta.4...v7.0.0-rc.1) (2017-05-26)


### :chart_with_upwards_trend: Performance Fixes

* fix translation performance issue ([6032a51](https://github.com/kazupon/vue-i18n/commit/6032a51)), closes [#165](https://github.com/kazupon/vue-i18n/issues/165)


### :up: Updates

* **flowtype:** remove unneccesary type ([eb60156](https://github.com/kazupon/vue-i18n/commit/eb60156))



<a name="7.0.0-beta.4"></a>
# [7.0.0-beta.4](https://github.com/kazupon/vue-i18n/compare/v7.0.0-beta.3...v7.0.0-beta.4) (2017-05-23)


### :bug: Bug Fixes

* **pluralization:** fix default choice ([240cfed](https://github.com/kazupon/vue-i18n/commit/240cfed)), closes [#164](https://github.com/kazupon/vue-i18n/issues/164)



<a name="7.0.0-beta.3"></a>
# [7.0.0-beta.3](https://github.com/kazupon/vue-i18n/compare/v7.0.0-beta.2...v7.0.0-beta.3) (2017-05-15)

### :up: Updates

* bring back from bug fix ([95be4ea](https://github.com/kazupon/vue-i18n/commit/95be4ea))


<a name="7.0.0-beta.2"></a>
# [7.0.0-beta.2](https://github.com/kazupon/vue-i18n/compare/v7.0.0-beta.1...v7.0.0-beta.2) (2017-05-14)


### :zap: Improvements

* **path:** tweak for ssr ([eb21921](https://github.com/kazupon/vue-i18n/commit/eb21921))
* **typescript:** change custom formatter method name ([c5f043f](https://github.com/kazupon/vue-i18n/commit/c5f043f))



<a name="7.0.0-beta.1"></a>
# [7.0.0-beta.1](https://github.com/kazupon/vue-i18n/compare/v6.1.1...v7.0.0-beta.1) (2017-05-11)

### :star: New Features

* **datetime localization:** add datetime localization ([3282075](https://github.com/kazupon/vue-i18n/commit/3282075))
    * [documentation](https://github.com/kazupon/vue-i18n/blob/dev/gitbook/en/datetime.md)
    * [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/datetime)
* **number localization:** add number localization ([87ee7b3](https://github.com/kazupon/vue-i18n/commit/87ee7b3))
    * [documentation](https://github.com/kazupon/vue-i18n/blob/dev/gitbook/en/number.md)
    * [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/number)
* **component interpolation:** ([23f7d34](https://github.com/kazupon/vue-i18n/commit/23f7d34)), closes [#145](https://github.com/kazupon/vue-i18n/issues/145) [#144](https://github.com/kazupon/vue-i18n/issues/144) [#37](https://github.com/kazupon/vue-i18n/issues/37)
    * [documentation](https://github.com/kazupon/vue-i18n/blob/dev/gitbook/en/interpolation.md)
    * [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/interpolation)
* **typescript:** add TypeScript type definitions ([#161](https://github.com/kazupon/vue-i18n/issues/161)) by [@aicest](https://github.com/aicest) ([61cebca](https://github.com/kazupon/vue-i18n/commit/61cebca))
    * [type definitions](https://github.com/kazupon/vue-i18n/blob/dev/types/index.d.ts)


### :boom: Breaking changes

* **format:** re-impelement formatter ([a8c046d](https://github.com/kazupon/vue-i18n/commit/a8c046d))
* **formatter:** change method name ([6eed51c](https://github.com/kazupon/vue-i18n/commit/6eed51c))
* **flowtype:** fix locale message related type changing ([c30d576](https://github.com/kazupon/vue-i18n/commit/c30d576))


### :bug: Bug Fixes

* **examples:** fix ssr demo ([059034f](https://github.com/kazupon/vue-i18n/commit/059034f)), closes [#151](https://github.com/kazupon/vue-i18n/issues/151)


<a name="6.1.3"></a>
## [6.1.3](https://github.com/kazupon/vue-i18n/compare/v6.1.1...v6.1.3) (2017-05-15)


### :bug: Bug Fixes

* fix memory leaks ([95be4ea](https://github.com/kazupon/vue-i18n/commit/95be4ea)), closes [#162](https://github.com/kazupon/vue-i18n/issues/162)



<a name="6.1.2"></a>
## [6.1.2](https://github.com/kazupon/vue-i18n/compare/v6.1.1...v6.1.2) (2017-05-15)


<a name="6.1.1"></a>
## [6.1.1](https://github.com/kazupon/vue-i18n/compare/v6.1.0...v6.1.1) (2017-04-19)


### :bug: Bug Fixes

* **te:** Fix `te()` that always uses `this.locale`, even when `locale` supplied ([#147](https://github.com/kazupon/vue-i18n/issues/147)) by [@aicest](https://github.com/aicest) ([bf15eeb](https://github.com/kazupon/vue-i18n/commit/bf15eeb)), closes [#147](https://github.com/kazupon/vue-i18n/issues/147)



<a name="6.1.0"></a>
# [6.1.0](https://github.com/kazupon/vue-i18n/compare/v6.0.0...v6.1.0) (2017-04-14)


### :star: New Features

* **api:** add 'mergeLocaleMessage' method ([ef21621](https://github.com/kazupon/vue-i18n/commit/ef21621)), closes [#131](https://github.com/kazupon/vue-i18n/issues/131)
* **silent:** add silent translation missing option ([29b3a17](https://github.com/kazupon/vue-i18n/commit/29b3a17)), closes [#139](https://github.com/kazupon/vue-i18n/issues/139)


### :zap: Improvements

* change to method from computed property ([9135a59](https://github.com/kazupon/vue-i18n/commit/9135a59)), closes [#141](https://github.com/kazupon/vue-i18n/issues/141)



<a name="6.0.0"></a>
# [6.0.0](https://github.com/kazupon/vue-i18n/compare/v6.0.0-beta.1...v6.0.0) (2017-04-05)

:tada: :tada: :tada:

See the [docs](https://kazupon.github.io/vue-i18n/en/)

### :zap: Improvements

- Server-Side Rendering: [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/ssr)
- Custom formatter: [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/formatting/custom)


### :star: NEW Features

- Single File Components: [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/sfc)


### :boom: Breaking changes

- API
- Dynamic locale <sup>DEPRECATED</sup>


<a name="6.0.0-beta.1"></a>
# [6.0.0-beta.1](https://github.com/kazupon/vue-i18n/compare/v6.0.0-alpha.6...v6.0.0-beta.1) (2017-03-22)


### :boom: Breaking changes

* change `fallbackRoot` and `sync` option default `true` value ([0890b44](https://github.com/kazupon/vue-i18n/commit/0890b44))
* remove messages settter, and add getLocaleMessage API ([0f0914d](https://github.com/kazupon/vue-i18n/commit/0f0914d))


### :bug: Bug Fixes

* **mixin:** fix computed props errors ([a6b7e37](https://github.com/kazupon/vue-i18n/commit/a6b7e37))


### :up: Updates

* **flowtype:** argument names ([cf14425](https://github.com/kazupon/vue-i18n/commit/cf14425))


### :zap: Improvements

* **fallbackLocale:** support reactivity ([ed758be](https://github.com/kazupon/vue-i18n/commit/ed758be))
* **warn:** suppress warning messages for production ([6e417d2](https://github.com/kazupon/vue-i18n/commit/6e417d2))



<a name="6.0.0-alpha.6"></a>
# [6.0.0-alpha.6](https://github.com/kazupon/vue-i18n/compare/v6.0.0-alpha.5...v6.0.0-alpha.6) (2017-03-16)


### :star: New Features

* add 'setLocaleMessage' API ([8b71eda](https://github.com/kazupon/vue-i18n/commit/8b71eda))



<a name="6.0.0-alpha.5"></a>
# [6.0.0-alpha.5](https://github.com/kazupon/vue-i18n/compare/v6.0.0-alpha.3...v6.0.0-alpha.5) (2017-03-11)


### :bug: Bug Fixes

* **mixin:** fix cannot create VueI18n instance error for minify production ([7eeb29f](https://github.com/kazupon/vue-i18n/commit/7eeb29f))



<a name="6.0.0-alpha.4"></a>
# [6.0.0-alpha.4](https://github.com/kazupon/vue-i18n/compare/v6.0.0-alpha.3...v6.0.0-alpha.4) (2017-03-11)



<a name="6.0.0-alpha.3"></a>
# [6.0.0-alpha.3](https://github.com/kazupon/vue-i18n/compare/v6.0.0-alpha.2...v6.0.0-alpha.3) (2017-03-08)


### :star: New Features

* add `sync` option ([5c46c07](https://github.com/kazupon/vue-i18n/commit/5c46c07))


### :zap: Improvements

* **mixin:** add error throwings and a warning ([0e4ac39](https://github.com/kazupon/vue-i18n/commit/0e4ac39))



<a name="6.0.0-alpha.2"></a>
# [6.0.0-alpha.2](https://github.com/kazupon/vue-i18n/compare/v6.0.0-alpha.1...v6.0.0-alpha.2) (2017-02-27)


### :zap: Improvements

* **mixin:** release i18n instance ([cc362a3](https://github.com/kazupon/vue-i18n/commit/cc362a3))
* **vue:** support vue 2.2 ([5e7bf5e](https://github.com/kazupon/vue-i18n/commit/5e7bf5e))



<a name="6.0.0-alpha.1"></a>
# [6.0.0-alpha.1](https://github.com/kazupon/vue-i18n/compare/v5.0.2...v6.0.0-alpha.1) (2017-02-23)

This is the first release of 6.0.
In this version, we are some big breaking changes.

- Recommended for: experiments, prototypes, upgrading small, non-critical apps
- **NOT** recommended for: production use, upgrading production apps

:warning: Documentation still needs to be worked on. And also, we might change some APIs and features.

In the examples, please refer to this [examples](https://github.com/kazupon/vue-i18n/tree/dev/examples) directory.


## Improvements
- Server-Side Rendering: [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/formatting/custom)
- Custom formatter: [example](https://github.com/kazupon/vue-i18n/tree/dev/examples/ssr)

## Features
- Formatting <sup>support</sup>
- Pluralization <sup>support</sup>
- Locale and KeyPath Syntax <sup>support</sup>
- Linked translation <sup>support</sup>
- Fallback translation <sup>support</sup>
- Component locale <sup>support</sup>
- Dynamic locale <sup>DEPRECATED</sup>
- Hot reload <sup>support</sup>

## API

### Global Config
- Vue.config.lang <sup>DEPRECATED, use VueI18n constructor `locale` option, or VueI18n#locale</sup>
- Vue.config.fallbackLang <sup>DEPRECATED, use VueI18n constructor `fallbackLocale` option, or VueI18n#fallbackLocale</sup>
- Vue.config.missingHandler <sup>DEPRECATED, use VueI18n constructor `missing` option, or VueI18n#missing</sup>
- Vue.config.i18nFormatter <sup>DEPRECATED, use VueI18n constructor `formatter` option, or VueI18n#formatter</sup>

### Global Method
- Vue.locale <sup>DEPRECATED, use VueI18n constructor `messages` option, or VueI18n#messages</sup>
- Vue.t <sup>DEPRECATED, use VueI18n#t</sup>
- Vue.tc <sup>DEPRECATED, use VueI18n#tc</sup>
- Vue.te <sup>DEPRECATED, use VueI18n#te</sup>

### Constructor Options
- locales <sup>DEPRECATED, use `messages` of `i18n` option (e.g `{ i18n: { messaes: ... } }`)</sup>

### Instance Properties
- $lang <sup>DEPRECATED, use `locale` of Vue instance property `$i18n` (e.g `vm.$i18n.locale = 'en'`)

### VueI18n class <sup>NEW</sup>
- constructor options: See the [`I18nOptions` type](https://github.com/kazupon/vue-i18n/blob/dev/decls/i18n.js#L7-L15) of flowtype.
- methods / properties: See the [`I18n` interface definition](https://github.com/kazupon/vue-i18n/blob/dev/decls/i18n.js#L17-L33) of flowtype.


<a name="5.0.2"></a>
## [5.0.2](https://github.com/kazupon/vue-i18n/compare/v5.0.1...v5.0.2) (2017-02-18)


### :zap: Improvements

* **npm:** revert node >= 6.0 engine restriction ([#110](https://github.com/kazupon/vue-i18n/issues/110)) by [@syxolk](https://github.com/syxolk) ([92b1bd1](https://github.com/kazupon/vue-i18n/commit/92b1bd1)), closes [#109](https://github.com/kazupon/vue-i18n/issues/109)



<a name="5.0.1"></a>
## [5.0.1](https://github.com/kazupon/vue-i18n/compare/v5.0.0...v5.0.1) (2017-02-16)


### :zap: Improvements

* **asset:** update locale reactivity setting ([b42fd9a](https://github.com/kazupon/vue-i18n/commit/b42fd9a))



<a name="5.0.0"></a>
# [5.0.0](https://github.com/kazupon/vue-i18n/compare/v4.10.0...v5.0.0) (2017-02-04)


### :boom: Breaking changes

* drop vue 1.0 supporting ([4da26cf](https://github.com/kazupon/vue-i18n/commit/4da26cf)), closes [#105](https://github.com/kazupon/vue-i18n/issues/105)



<a name="4.10.0"></a>
# [4.10.0](https://github.com/kazupon/vue-i18n/compare/v4.9.0...v4.10.0) (2017-01-01)


### :star: New Features

* `$lang` property for all component ([#99](https://github.com/kazupon/vue-i18n/issues/99)) by [@albert](https://github.com/albert)-zhang ([5ed69f8](https://github.com/kazupon/vue-i18n/commit/5ed69f8))


### :up: Updates

* **override:** change langVM keeping variable name ([3ec1bb2](https://github.com/kazupon/vue-i18n/commit/3ec1bb2))



<a name="4.9.0"></a>
# [4.9.0](https://github.com/kazupon/vue-i18n/compare/v4.8.0...v4.9.0) (2016-12-17)


### :bug: Bug Fixes

* **path:** fix nested key translation ([e15ead4](https://github.com/kazupon/vue-i18n/commit/e15ead4)), closes [#97](https://github.com/kazupon/vue-i18n/issues/97)


### :star: New Features

* add globally locale checking ([4cac8b9](https://github.com/kazupon/vue-i18n/commit/4cac8b9))
* locale checking ([#98](https://github.com/kazupon/vue-i18n/issues/98)) by [@long](https://github.com/long)-long-float ([0bc0a6b](https://github.com/kazupon/vue-i18n/commit/0bc0a6b))


<a name="4.8.0"></a>
# [4.8.0](https://github.com/kazupon/vue-i18n/compare/v4.7.4...v4.8.0) (2016-12-08)


### :zap: Improvements

* **extend:** disable no translation warning when set missingHandler ([168a97c](https://github.com/kazupon/vue-i18n/commit/168a97c)), closes [#96](https://github.com/kazupon/vue-i18n/issues/96)



<a name="4.7.4"></a>
## [4.7.4](https://github.com/kazupon/vue-i18n/compare/v4.7.3...v4.7.4) (2016-11-29)


### :bug: Bug Fixes

* **extend:** fix interpolate error [@tariq86](https://github.com/tariq86) ([5f24e17](https://github.com/kazupon/vue-i18n/commit/5f24e17))



<a name="4.7.3"></a>
## [4.7.3](https://github.com/kazupon/vue-i18n/compare/v4.7.2...v4.7.3) (2016-11-24)


### :bug: Bug Fixes

* **extend:** fix array local ([35c268a](https://github.com/kazupon/vue-i18n/commit/35c268a)), closes [#91](https://github.com/kazupon/vue-i18n/issues/91) [#59](https://github.com/kazupon/vue-i18n/issues/59)



<a name="4.7.2"></a>
## [4.7.2](https://github.com/kazupon/vue-i18n/compare/v4.7.1...v4.7.2) (2016-11-19)


### :bug: Bug Fixes

* **observer:** fix dep undefined error ([#88](https://github.com/kazupon/vue-i18n/issues/88)) by [@fandaa](https://github.com/fandaa) ([724974e](https://github.com/kazupon/vue-i18n/commit/724974e)), closes [#88](https://github.com/kazupon/vue-i18n/issues/88)


### :zap: Improvements

* **extend:** support translate empty string ([#86](https://github.com/kazupon/vue-i18n/issues/86)) by [@QingWei](https://github.com/QingWei)-Li ([8e6d154](https://github.com/kazupon/vue-i18n/commit/8e6d154))



<a name="4.7.1"></a>
## [4.7.1](https://github.com/kazupon/vue-i18n/compare/v4.7.0...v4.7.1) (2016-10-29)


### :bug: Bug Fixes

* **interpolate:** named formatting: use name if value is missing ([#77](https://github.com/kazupon/vue-i18n/issues/77)) by [@SebastianS90](https://github.com/SebastianS90) ([a0cc343](https://github.com/kazupon/vue-i18n/commit/a0cc343))


### :zap: Improvements

* **named:** using default use nmae when value is missing ([c34e8f1](https://github.com/kazupon/vue-i18n/commit/c34e8f1))



<a name="4.7.0"></a>
# [4.7.0](https://github.com/kazupon/vue-i18n/compare/v4.6.0...v4.7.0) (2016-10-28)


### :star: New Features

* hot reloading ([#71](https://github.com/kazupon/vue-i18n/issues/71)) by [@gglnx](https://github.com/gglnx) ([7bb94ac](https://github.com/kazupon/vue-i18n/commit/7bb94ac))


### :zap: Improvements

* **pluralization:** zero choice ([#70](https://github.com/kazupon/vue-i18n/issues/70)) by [@sebwas](https://github.com/sebwas) ([5f0004f](https://github.com/kazupon/vue-i18n/commit/5f0004f))



<a name="4.6.0"></a>
# [4.6.0](https://github.com/kazupon/vue-i18n/compare/v4.5.0...v4.6.0) (2016-09-24)


### :star: New Features

* **config:** custom message formatter ([#57](https://github.com/kazupon/vue-i18n/issues/57)) by [@jvmccarthy](https://github.com/jvmccarthy) ([2748eb4](https://github.com/kazupon/vue-i18n/commit/2748eb4))



<a name="4.5.0"></a>
# [4.5.0](https://github.com/kazupon/vue-i18n/compare/v4.4.1...v4.5.0) (2016-09-15)


### :star: New Features

* **config:** translation miss capturing configration ([aca0ed6](https://github.com/kazupon/vue-i18n/commit/aca0ed6)), closes [#54](https://github.com/kazupon/vue-i18n/issues/54)



<a name="4.4.1"></a>
## [4.4.1](https://github.com/kazupon/vue-i18n/compare/v4.4.0...v4.4.1) (2016-09-10)


### :zap: Improvements

* **translate:** support hyphenated key ([#52](https://github.com/kazupon/vue-i18n/issues/52)) by [@tariq86](https://github.com/tariq86) ([a40acfd](https://github.com/kazupon/vue-i18n/commit/a40acfd))



<a name="4.4.0"></a>
# [4.4.0](https://github.com/kazupon/vue-i18n/compare/v4.3.1...v4.4.0) (2016-08-29)


### :star: New Features

* add linked translations ([#50](https://github.com/kazupon/vue-i18n/issues/50)) by [@mmochetti](https://github.com/mmochetti) ([f7ae073](https://github.com/kazupon/vue-i18n/commit/f7ae073))



<a name="4.3.1"></a>
## [4.3.1](https://github.com/kazupon/vue-i18n/compare/v4.3.0...v4.3.1) (2016-08-26)


### :bug: Bug Fixes

* **npm:** fix installing bug ([57e66aa](https://github.com/kazupon/vue-i18n/commit/57e66aa)), closes [#46](https://github.com/kazupon/vue-i18n/issues/46)



<a name="4.3.0"></a>
# [4.3.0](https://github.com/kazupon/vue-i18n/compare/v4.2.3...v4.3.0) (2016-08-26)


### :star: New Features

* add pluralization ([#44](https://github.com/kazupon/vue-i18n/issues/44)) by [@mmochetti](https://github.com/mmochetti) ([b5b84d8](https://github.com/kazupon/vue-i18n/commit/b5b84d8))



<a name="4.2.3"></a>
## [4.2.3](https://github.com/kazupon/vue-i18n/compare/v4.2.2...v4.2.3) (2016-08-23)


### :chart_with_upwards_trend: Performance Fixes

* improve re-rendering cost when change the lang ([0707338](https://github.com/kazupon/vue-i18n/commit/0707338))



<a name="4.2.2"></a>
## [4.2.2](https://github.com/kazupon/vue-i18n/compare/v4.2.1...v4.2.2) (2016-08-15)


### :bug: Bug Fixes

* **path:** fix array path syntax error ([bc9dbee](https://github.com/kazupon/vue-i18n/commit/bc9dbee)), closes [#42](https://github.com/kazupon/vue-i18n/issues/42) [#43](https://github.com/kazupon/vue-i18n/issues/43)



<a name="4.2.1"></a>
## [4.2.1](https://github.com/kazupon/vue-i18n/compare/v4.2.0...v4.2.1) (2016-08-13)


### :zap: Improvements

* **translate:** fallback translation warning ([5f6b271](https://github.com/kazupon/vue-i18n/commit/5f6b271))



<a name="4.2.0"></a>
# [4.2.0](https://github.com/kazupon/vue-i18n/compare/v4.1.0...v4.2.0) (2016-08-12)


### :chart_with_upwards_trend: Performance Fixes

* **format:** use hasOwn function of Vue.util ([a8a19a0](https://github.com/kazupon/vue-i18n/commit/a8a19a0))


### :star: New Features

* **fallback:** add fallback translation feature ([1d1f0f2](https://github.com/kazupon/vue-i18n/commit/1d1f0f2)), closes [#36](https://github.com/kazupon/vue-i18n/issues/36)



<a name="4.1.0"></a>
# [4.1.0](https://github.com/kazupon/vue-i18n/compare/v4.0.1...v4.1.0) (2016-07-25)


### :bug: Bug Fixes

* **util:** fixed isArray reference errors ([0c6f6a0](https://github.com/kazupon/vue-i18n/commit/0c6f6a0))


### :star: New Features

* support vue 2.0.0.beta later ([0e1d2f7](https://github.com/kazupon/vue-i18n/commit/0e1d2f7))



<a name="4.0.1"></a>
## [4.0.1](https://github.com/kazupon/vue-i18n/compare/v4.0.0...v4.0.1) (2016-06-06)


### :bug: Bug Fixes

* **translate:** fix underscore named argument translate issue ([eeaf936](https://github.com/kazupon/vue-i18n/commit/eeaf936))



<a name="4.0.0"></a>
# [4.0.0](https://github.com/kazupon/vue-i18n/compare/v3.1.1...v4.0.0) (2016-05-10)


### :zap: Improvements

* support vue 2.0-pre-alpha ([f6517bc](https://github.com/kazupon/vue-i18n/commit/f6517bc))



<a name="3.1.1"></a>
## [3.1.1](https://github.com/kazupon/vue-i18n/compare/v3.1.0...v3.1.1) (2016-05-09)


### :star: New Features

* auto installation for standalone ([2b0dc09](https://github.com/kazupon/vue-i18n/commit/2b0dc09))



<a name="3.1.0"></a>
# [3.1.0](https://github.com/kazupon/vue-i18n/compare/v3.0.0...v3.1.0) (2016-05-09)


### :star: New Features

* component locales ([12fe695](https://github.com/kazupon/vue-i18n/commit/12fe695)), closes [#29](https://github.com/kazupon/vue-i18n/issues/29)


### :warning: Depcreted

* **options:** remove Vue.use options ([d87b59b](https://github.com/kazupon/vue-i18n/commit/d87b59b))


### :zap: Improvements

* **keypath:** port the object path parser ([3ae04b7](https://github.com/kazupon/vue-i18n/commit/3ae04b7))
* **translation:** fix hypenate included key translating ([d0a415f](https://github.com/kazupon/vue-i18n/commit/d0a415f)), closes [#24](https://github.com/kazupon/vue-i18n/issues/24)
* **translation:** warning outputing when cannot translate with keypath ([b4c7c0e](https://github.com/kazupon/vue-i18n/commit/b4c7c0e)), closes [#22](https://github.com/kazupon/vue-i18n/issues/22)



<a name="3.0.0"></a>
# [3.0.0](https://github.com/kazupon/vue-i18n/compare/v2.4.1...v3.0.0) (2016-04-18)


### Features

* **lang:** support lang reactive changing ([203ee85](https://github.com/kazupon/vue-i18n/commit/203ee85)), closes [#2](https://github.com/kazupon/vue-i18n/issues/2) [#15](https://github.com/kazupon/vue-i18n/issues/15)
* **locale:** support dynamic local ([4d61e8d](https://github.com/kazupon/vue-i18n/commit/4d61e8d)), closes [#6](https://github.com/kazupon/vue-i18n/issues/6) [#21](https://github.com/kazupon/vue-i18n/issues/21)

### DEPRECATED

* **index:** plugin install `Vue.use` options (`options.locales`, `options.lang`). See [README](https://github.com/kazupon/vue-i18n/blob/dev/README.md)


<a name="2.4.1"></a>
## [2.4.1](https://github.com/kazupon/vue-i18n/compare/v2.4.0...v2.4.1) (2016-02-29)

### Features

* **i18n:** support ruby on rails i18n interpolation format ([b6b2490](https://github.com/kazupon/vue-i18n/commit/b6b2490))



<a name="2.4.0"></a>
# [2.4.0](https://github.com/kazupon/vue-i18n/compare/v2.3.3...v2.4.0) (2016-02-06)


### Features

* **i18n:** add Vue.t function ([68935e3](https://github.com/kazupon/vue-i18n/commit/68935e3)), closes [#17](https://github.com/kazupon/vue-i18n/issues/17)



<a name="2.3.3"></a>
## [2.3.3](https://github.com/kazupon/vue-i18n/compare/v2.3.2...v2.3.3) (2015-12-09)


### Bug Fixes

* **npm:** npm install error ([e31e89e](https://github.com/kazupon/vue-i18n/commit/e31e89e))

### Features

* **bower:** good-bye bower :wink: ([d99eb15](https://github.com/kazupon/vue-i18n/commit/d99eb15))


### BREAKING CHANGES

* bower: not support `bower` package manager

I think that bower is dead. :no_good:



<a name="2.3.2"></a>
## [2.3.2](https://github.com/kazupon/vue-i18n/compare/v2.3.1...v2.3.2) (2015-12-09)


### Features

* **bundle:** more compact the vue-i18n distribution file ([2f32ecc](https://github.com/kazupon/vue-i18n/commit/2f32ecc))



<a name="2.3.1"></a>
## [2.3.1](https://github.com/kazupon/vue-i18n/compare/v2.3.0...v2.3.1) (2015-12-01)

### Reverts

* **index:** automatically install for standalone ([25b8059](https://github.com/kazupon/vue-i18n/commit/25b8059))



<a name="2.3.0"></a>
# [2.3.0](https://github.com/kazupon/vue-i18n/compare/v2.2.0...v2.3.0) (2015-11-26)


### Bug Fixes

* **index:** cannot work at Vue 1.0.10 later ([6fd543e](https://github.com/kazupon/vue-i18n/commit/6fd543e)), closes [#9](https://github.com/kazupon/vue-i18n/issues/9)

### Features

* **index:** support automatically install for standalone ([ada2673](https://github.com/kazupon/vue-i18n/commit/ada2673))



# v2.2.0 / 2015-09-16

* Re-implemetation with ES6 (babel)

# v2.1.0 / 2015-07-03

* Add global local language setting with `Vue.config.lang`

# v2.0.0 / 2015-06-29

* Support Vue.js 0.12
* Remove the followings (Breaking Changes)
    * `Vue.t` function
    * `v-t` directive

# v1.1.1 / 2015-04-21

* Fix unit test error

# v1.1.0 / 2015-01-10

* Support template string in `$t` method
* Support language changing in `$t` method

# v1.0.0 / 2015-01-10

* Add `$t` method

# v0.11.0 / 2014-11-07

* Bump to 0.11.0

# v0.2.0 / 2014-10-08

* Support Vue.js 0.11.0-rc

# v0.1.2 / 2014-10-07

* Support bower

# v0.1.1 / 2014-10-06

* Add `Vue.t` function

# v0.1.0 / 2014-05-06

* Release first

# v0.0.0 / 2014-05-03

* Initial project
