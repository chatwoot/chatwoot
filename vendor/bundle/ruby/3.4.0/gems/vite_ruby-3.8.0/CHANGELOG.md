# [3.8.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.7.0...vite_ruby@3.8.0) (2024-08-12)


### Bug Fixes

* remove `vite:clean` rake task as it can potentially break apps ([824b4ef](https://github.com/ElMassimo/vite_ruby/commit/824b4ef8397828423d2ddda117bf27e365954961)), closes [#438](https://github.com/ElMassimo/vite_ruby/issues/438) [#490](https://github.com/ElMassimo/vite_ruby/issues/490) [#404](https://github.com/ElMassimo/vite_ruby/issues/404)


### Features

* remove `ostruct` dependency (closes [#489](https://github.com/ElMassimo/vite_ruby/issues/489)) ([1dfec47](https://github.com/ElMassimo/vite_ruby/commit/1dfec4759bf2c107433c5f1618d97439f6d5bd01))



# [3.7.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.6.2...vite_ruby@3.7.0) (2024-07-17)


### Features

* add `package_manager` config option, experimental support for bun ([#481](https://github.com/ElMassimo/vite_ruby/issues/481)) ([4426cb1](https://github.com/ElMassimo/vite_ruby/commit/4426cb1007dbb58f4637a4423b1e7d640db96841)), closes [#324](https://github.com/ElMassimo/vite_ruby/issues/324)
* change default execution to use `npx vite` instead ([#480](https://github.com/ElMassimo/vite_ruby/issues/480)) ([330f61f](https://github.com/ElMassimo/vite_ruby/commit/330f61fedadf1274547a069856125e52002d0065)), closes [#462](https://github.com/ElMassimo/vite_ruby/issues/462)



## [3.6.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.6.1...vite_ruby@3.6.2) (2024-07-16)



## [3.6.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.6.0...vite_ruby@3.6.1) (2024-07-16)


### Bug Fixes

* use ESM by default in new installations ([#479](https://github.com/ElMassimo/vite_ruby/issues/479)) ([cc379ca](https://github.com/ElMassimo/vite_ruby/commit/cc379ca613dd4e5863f8556be62ea623b56cfe0c)), closes [#431](https://github.com/ElMassimo/vite_ruby/issues/431)



# [3.6.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.5.0...vite_ruby@3.6.0) (2024-06-07)


### Features

* allow skipping dependency install in assets:precompile ([#451](https://github.com/ElMassimo/vite_ruby/issues/451)) ([5a922b2](https://github.com/ElMassimo/vite_ruby/commit/5a922b2071446e3880b17503474a0c7806eab6a7))



# [3.5.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.4.0...vite_ruby@3.5.0) (2023-11-16)


### Bug Fixes

* prevent clean from deleting assets referenced in the manifests ([8a581c1](https://github.com/ElMassimo/vite_ruby/commit/8a581c15ff480049bbb14dab1b5a3497308521b5))


### Features

* use vite 5 in new installations ([f063f28](https://github.com/ElMassimo/vite_ruby/commit/f063f283f939d15b3c48c1a9b6efcd589fafbaf1))



# [3.4.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.3.4...vite_ruby@3.4.0) (2023-11-16)


### Bug Fixes

* **breaking:** check for any existing manifest path before cleaning ([c450483](https://github.com/ElMassimo/vite_ruby/commit/c4504839e11006d50d6503288469cb3de0c6a9cd))


### Features

* add support for vite 5, which changed default manifest path ([818132a](https://github.com/ElMassimo/vite_ruby/commit/818132a07af3f17ba27ae09c44fcd59029064238))



## [3.3.4](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.3.3...vite_ruby@3.3.4) (2023-06-27)


### Bug Fixes

* check only once per second when dev server is not running ([#377](https://github.com/ElMassimo/vite_ruby/issues/377)) ([fb33f0a](https://github.com/ElMassimo/vite_ruby/commit/fb33f0a28077f9912deed257b7be3a7e050c2d94))



## [3.3.3](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.3.2...vite_ruby@3.3.3) (2023-06-19)


### Features

* allow skipping dev dependencies on install ([#374](https://github.com/ElMassimo/vite_ruby/issues/374)) ([a309f4f](https://github.com/ElMassimo/vite_ruby/commit/a309f4f9fc62fb7b9d0728b66b30ad90e68ba7bf))
* Use javascript_tag helper for vite_react_refresh_tag ([#372](https://github.com/ElMassimo/vite_ruby/issues/372)) ([238c6bd](https://github.com/ElMassimo/vite_ruby/commit/238c6bd211c0fafaa6170f0bdd631a0f6e41d992)), closes [#249](https://github.com/ElMassimo/vite_ruby/issues/249)



## [3.3.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.3.1...vite_ruby@3.3.2) (2023-05-09)


### Bug Fixes

* ensure assets:precompile task is displayed when using `rake -T` ([66af6eb](https://github.com/ElMassimo/vite_ruby/commit/66af6eb0268e7a989562feb38da74072817f0d49))



## [3.3.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.3.0...vite_ruby@3.3.1) (2023-04-28)


### Features

* upgrade default vite version to 4.3 ([b186456](https://github.com/ElMassimo/vite_ruby/commit/b18645605dd40b312da1137a6440abc8fe4c5ae7))



# [3.3.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.15...vite_ruby@3.3.0) (2023-03-16)


### Features

* add support for the --profile flag when running vite build ([4a949fd](https://github.com/ElMassimo/vite_ruby/commit/4a949fde1672b899c7c0382e99a669195c7ea639)), closes [#332](https://github.com/ElMassimo/vite_ruby/issues/332)
* change defaults to vite@4.2.0 and vite-plugin-ruby@3.2.0 ([e9f5702](https://github.com/ElMassimo/vite_ruby/commit/e9f570294c34682a6dd18fdc2ef13675f33375e6))



## [3.2.15](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.14...vite_ruby@3.2.15) (2023-03-01)


### Features

* install dependencies with yarn if npx is not available ([#343](https://github.com/ElMassimo/vite_ruby/issues/343)) ([90c5db2](https://github.com/ElMassimo/vite_ruby/commit/90c5db2e45ed89aedfa02f0f167925e4ccb02d6d)), closes [#342](https://github.com/ElMassimo/vite_ruby/issues/342)



## [3.2.14](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.13...vite_ruby@3.2.14) (2022-12-22)



## [3.2.13](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.12...vite_ruby@3.2.13) (2022-12-09)


### Features

* install vite 4 by default ([c1a2e16](https://github.com/ElMassimo/vite_ruby/commit/c1a2e16a5b47225c53ad73b4f6371f2108881850))



## [3.2.12](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.11...vite_ruby@3.2.12) (2022-12-02)


### Features

* add experimental `skipProxy` setting ([#315](https://github.com/ElMassimo/vite_ruby/issues/315)) ([e9285f6](https://github.com/ElMassimo/vite_ruby/commit/e9285f62c76cc0cbbc5dc99d977e8aef30d08b6f))
* add ViteRuby.instance.configure API to be used in config/vite.rb ([b5b8681](https://github.com/ElMassimo/vite_ruby/commit/b5b8681f85f5388a56d72c9b05dbfc95d5ba607b))


### Performance Improvements

* avoid calculating digest on each lookup ([#314](https://github.com/ElMassimo/vite_ruby/issues/314)) ([62df93a](https://github.com/ElMassimo/vite_ruby/commit/62df93a15c09c652a8b7496e26cf85d5d69acce7))



## [3.2.11](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.10...vite_ruby@3.2.11) (2022-11-13)


### Bug Fixes

* avoid removing double extension for non-preprocessor assets ([#301](https://github.com/ElMassimo/vite_ruby/issues/301)) ([2024f62](https://github.com/ElMassimo/vite_ruby/commit/2024f62af917cabcb817c32a5fbbe709d477c19f))



## [3.2.10](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.9...vite_ruby@3.2.10) (2022-11-03)



## [3.2.9](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.8...vite_ruby@3.2.9) (2022-11-02)


### Features

* allow different ViteRuby instances to set different env vars ([25628a7](https://github.com/ElMassimo/vite_ruby/commit/25628a752cbd4828547c1f454cc4cb2217a591e0))
* output exit code when vite process fails ([#294](https://github.com/ElMassimo/vite_ruby/issues/294)) ([eb8f678](https://github.com/ElMassimo/vite_ruby/commit/eb8f678248a02b693fffe5a49309984fed92a051)), closes [#292](https://github.com/ElMassimo/vite_ruby/issues/292)



## [3.2.8](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.7...vite_ruby@3.2.8) (2022-10-28)


### Features

* default to vite@3.2.0 ([2ef83a5](https://github.com/ElMassimo/vite_ruby/commit/2ef83a52148f46534c4106015f3f54ec9ee807cb))



## [3.2.7](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.6...vite_ruby@3.2.7) (2022-10-19)


### Bug Fixes

* yarn berry pnp mode support ([#278](https://github.com/ElMassimo/vite_ruby/issues/278)) ([1890447](https://github.com/ElMassimo/vite_ruby/commit/189044746e536847cb33fb471cc7c42251a61072))


### Features

* create vite-plugin-rails, an opinionated version of `vite-plugin-ruby` ([#282](https://github.com/ElMassimo/vite_ruby/issues/282)) ([16375fb](https://github.com/ElMassimo/vite_ruby/commit/16375fb1f6f2bf86dff935ca3aaf91c333a796ff))



## [3.2.6](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.5...vite_ruby@3.2.6) (2022-10-07)


### Features

* always trigger a build if the manifest is missing ([#275](https://github.com/ElMassimo/vite_ruby/issues/275)) ([53ffdb9](https://github.com/ElMassimo/vite_ruby/commit/53ffdb9559409cb813198b4fd8a7a5ccb0c3cd21))



## [3.2.5](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.4...vite_ruby@3.2.5) (2022-10-07)


### Features

* display last build errors in MissingEntrypointError ([#274](https://github.com/ElMassimo/vite_ruby/issues/274)) ([107c980](https://github.com/ElMassimo/vite_ruby/commit/107c980449546ef73c527b88f1db11a7201e4438))



## [3.2.4](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.3...vite_ruby@3.2.4) (2022-10-04)


### Bug Fixes

* **BREAKING CHANGE:** lookup now returns nil if auto-build fails ([#268](https://github.com/ElMassimo/vite_ruby/issues/268)) ([cf2dec1](https://github.com/ElMassimo/vite_ruby/commit/cf2dec1bfec2279179c1671e5b42479549fd11c4)), closes [#267](https://github.com/ElMassimo/vite_ruby/issues/267)



## [3.2.3](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.2...vite_ruby@3.2.3) (2022-08-28)


### Bug Fixes

* prevent yarn 2+ error in `assets:precompile` ([#241](https://github.com/ElMassimo/vite_ruby/issues/241)) ([e7e857a](https://github.com/ElMassimo/vite_ruby/commit/e7e857ac763dd053a8bda4b27d26a2090269f6d8))



## [3.2.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.1...vite_ruby@3.2.2) (2022-08-12)


### Features

* allow framework-specific libraries to extend the CLI ([a0ed66f](https://github.com/ElMassimo/vite_ruby/commit/a0ed66fe64fb2549cecc358ccd60c82be44255aa))



## [3.2.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.2.0...vite_ruby@3.2.1) (2022-08-11)


### Bug Fixes

* require the version after defining namespace (close [#239](https://github.com/ElMassimo/vite_ruby/issues/239)) ([7b92062](https://github.com/ElMassimo/vite_ruby/commit/7b920627f0f551166b3ab321e50b6cee746168c2))



# [3.2.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.7...vite_ruby@3.2.0) (2022-07-13)


### Features

* use Vite 3 as the default ([#225](https://github.com/ElMassimo/vite_ruby/issues/225)) ([8fab191](https://github.com/ElMassimo/vite_ruby/commit/8fab1912dc8c7c600854b490c09a603644714266))



## [3.1.7](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.6...vite_ruby@3.1.7) (2022-07-13)


### Bug Fixes

* npm deprecation warning on assets:precompile ([#226](https://github.com/ElMassimo/vite_ruby/issues/226)) ([e4f4b75](https://github.com/ElMassimo/vite_ruby/commit/e4f4b7540ef34296f1a8a4d8f1d2838549ee8460)), closes [#220](https://github.com/ElMassimo/vite_ruby/issues/220)
# [](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.6...vite_ruby@) (2022-07-01)


## [3.1.6](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.5...vite_ruby@3.1.6)  (2022-06-02)

### Bug Fixes

* Catch npm command not found, for folks who install deps with yarn ([7a0407b3211e682bc1da40d29225af58d3396cbd](https://github.com/ElMassimo/vite_ruby/commit/7a0407b3211e682bc1da40d29225af58d3396cbd))


## [3.1.5](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.4...vite_ruby@3.1.5) (2022-05-30)


### Bug Fixes

* install dependencies without confirmation in modern versions of npm ([967fbf5](https://github.com/ElMassimo/vite_ruby/commit/967fbf52aac5e52e1a059bffda79c7472874775f)), closes [#216](https://github.com/ElMassimo/vite_ruby/issues/216)



## [3.1.4](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.3...vite_ruby@3.1.4) (2022-05-13)


### Features

* expose `ViteRuby.digest` to simplify asset versioning. ([ff92ce6](https://github.com/ElMassimo/vite_ruby/commit/ff92ce6011d857efa83987d3c20d48767111e700))



## [3.1.3](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.2...vite_ruby@3.1.3) (2022-05-13)


### Bug Fixes

* change default for ssrOutputDir so it's ignored by default ([2f93b76](https://github.com/ElMassimo/vite_ruby/commit/2f93b762b29462cc619527ed47e6fa3cf8d3c8c9))



## [3.1.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.1...vite_ruby@3.1.2) (2022-05-12)


### Features

* add support for SSR builds (experimental) ([#212](https://github.com/ElMassimo/vite_ruby/issues/212)) ([4d6cd2b](https://github.com/ElMassimo/vite_ruby/commit/4d6cd2b84f670b1703e3bde7033e822be97bf505))
* ignore any vite dirs in .gitignore installation (for ssr builds) ([fd68420](https://github.com/ElMassimo/vite_ruby/commit/fd68420dfaeb79b97f8edade5bf17bfe81fd2486))



## [3.1.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.1.0...vite_ruby@3.1.1) (2022-04-14)


### Bug Fixes

* prevent error when using a proc in asset_host (close [#202](https://github.com/ElMassimo/vite_ruby/issues/202)) ([#203](https://github.com/ElMassimo/vite_ruby/issues/203)) ([cb23a81](https://github.com/ElMassimo/vite_ruby/commit/cb23a81037651ac01d993935f68cc526ec2c844d))



# [3.1.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.11...vite_ruby@3.1.0) (2022-04-01)


### Features

* improve capistrano-rails integration by extending asset tasks ([#200](https://github.com/ElMassimo/vite_ruby/issues/200)) ([d5704ab](https://github.com/ElMassimo/vite_ruby/commit/d5704ab55abf27cbdb5b00841bce3136147a0200))



## [3.0.11](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.10...vite_ruby@3.0.11) (2022-04-01)


### Features

* bump the default vite version ([2cb8952](https://github.com/ElMassimo/vite_ruby/commit/2cb895246b3154322273989057bf9bdc67634bc6))



## [3.0.10](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.9...vite_ruby@3.0.10) (2022-03-17)


### Bug Fixes

* avoid proxying requests starting with @ ([93d071b](https://github.com/ElMassimo/vite_ruby/commit/93d071b2b807c2e09e24d5d7ea4228974b370960))
* MissingExecutableError when deploying with Capistrano (close [#192](https://github.com/ElMassimo/vite_ruby/issues/192)) ([22e1691](https://github.com/ElMassimo/vite_ruby/commit/22e1691a0685b1fdeec3904657be5e69a57e6456))


### Features

* bump up default vite version to 2.8.6 ([fd53030](https://github.com/ElMassimo/vite_ruby/commit/fd5303017760dc176b3fb15908f08a16a175c22f))



## [3.0.9](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.8...vite_ruby@3.0.9) (2022-02-09)


### Bug Fixes

* support older versions of npm (v6) that ship with node 12 and 14 ([0accc36](https://github.com/ElMassimo/vite_ruby/commit/0accc36e9ef82fa0923af4f94253433433c0b074))



## [3.0.8](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.7...vite_ruby@3.0.8) (2022-01-18)


### Bug Fixes

* remove .DS_Store from installation .gitignore ([#178](https://github.com/ElMassimo/vite_ruby/issues/178)) ([5a0931d](https://github.com/ElMassimo/vite_ruby/commit/5a0931d63318ab5b1bf9ead680540c015afd471a))



## [3.0.7](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.6...vite_ruby@3.0.7) (2021-12-27)



## [3.0.6](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.5...vite_ruby@3.0.6) (2021-12-24)


### Bug Fixes

* allow providing an empty public output dir (close [#161](https://github.com/ElMassimo/vite_ruby/issues/161)) ([#164](https://github.com/ElMassimo/vite_ruby/issues/164)) ([ef48c9b](https://github.com/ElMassimo/vite_ruby/commit/ef48c9b39084a96364a783fa670bd6ec68dfa289))


### Features

* support ruby config file for advanced configuration (close [#162](https://github.com/ElMassimo/vite_ruby/issues/162)) ([34e63fd](https://github.com/ElMassimo/vite_ruby/commit/34e63fdd546078dfc94f2c546b096aa296a47d37))



## [3.0.5](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.4...vite_ruby@3.0.5) (2021-12-17)


### Bug Fixes

* ensure vite_plugin_legacy is upgraded by the upgrade command ([2f9437d](https://github.com/ElMassimo/vite_ruby/commit/2f9437d248e27aa03b5b8a1df3e3d6a52c791cd1))



## [3.0.4](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.3...vite_ruby@3.0.4) (2021-12-17)

### BREAKING CHANGES

* if using `vite_plugin_legacy`, make sure to upgrade to 3.0.1

### Bug Fixes

* handle new virtual legacy-polyfill name ([#157](https://github.com/ElMassimo/vite_ruby/issues/157)) ([a34e77f](https://github.com/ElMassimo/vite_ruby/commit/a34e77f3b342c9171adc50adfd5220b57bddb961))


## [3.0.3](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.2...vite_ruby@3.0.3) (2021-12-09)


### Bug Fixes

* ensure bundler does not keep generating binstubs ([0dc133a](https://github.com/ElMassimo/vite_ruby/commit/0dc133a23f6caa5526fc071e0afd98f91fc1f9f6))
* explicitly require socket to enable usage in bare ruby ([cf22165](https://github.com/ElMassimo/vite_ruby/commit/cf22165fa3cc58df4c52bed154372abef4f3eff1))


### Features

* add 'base' setting ([#152](https://github.com/ElMassimo/vite_ruby/issues/152)) ([fb7642f](https://github.com/ElMassimo/vite_ruby/commit/fb7642f849b7fe879c02e543962a72dcc1b1c48c))



## [3.0.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.1...vite_ruby@3.0.2) (2021-10-29)


### Features

* enable hmr when running tests in development with vite dev server ([e253bba](https://github.com/ElMassimo/vite_ruby/commit/e253bba26d164aabc7a9526df504c207ad2cf6f9))



## [3.0.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@3.0.0...vite_ruby@3.0.1) (2021-10-27)


### Features

* expose the `--watch` flag for the build command ([4e20d0a](https://github.com/ElMassimo/vite_ruby/commit/4e20d0a7b697b535e13335dac5a75fb8a193a133))



# [3.0.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.20...vite_ruby@3.0.0) (2021-08-16)

See https://github.com/ElMassimo/vite_ruby/pull/116 for features and breaking changes.

## [1.2.20](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.18...vite_ruby@1.2.20) (2021-07-30)


### Features

* use `asset_host` for Vite client if set during development ([89a338c](https://github.com/ElMassimo/vite_ruby/commit/89a338c2f23e6b43af9dadfd937fe29c82a08b10))
* Watch Windi CSS config file by default if it exists ([842c5eb](https://github.com/ElMassimo/vite_ruby/commit/842c5eb46cd12887f28ed62cb656d81645c7239c))



## [1.2.18](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.17...vite_ruby@1.2.18) (2021-07-19)

* fix: Proxy entrypoint HMR requests only after verifying the file exists (close #102) ([67c22ec](https://github.com/ElMassimo/vite_ruby/commit/67c22ec)), closes [#102](https://github.com/ElMassimo/vite_ruby/issues/102)


## [1.2.17](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.16...vite_ruby@1.2.17) (2021-07-12)

* fix: Proxy CSS Modules requests to Vite.js with the correct extension (close #98) ([8976872](https://github.com/ElMassimo/vite_ruby/commit/8976872)), closes [#98](https://github.com/ElMassimo/vite_ruby/issues/98)



## [1.2.16](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.15...vite_ruby@1.2.16) (2021-07-07)

* feat: Enable usage in engines by using `run` from the current instance ([023a61d](https://github.com/ElMassimo/vite_ruby/commit/023a61d))



## [1.2.15](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.14...vite_ruby@1.2.15) (2021-07-01)



## [1.2.14](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.13...vite_ruby@1.2.14) (2021-07-01)


### Features

* Add support for Jekyll installer ([7b942ec](https://github.com/ElMassimo/vite_ruby/commit/7b942ec745eb28092d684056b02df675ad6ececa))



## [1.2.13](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.12...vite_ruby@1.2.13) (2021-06-30)


### Features

* Improve the error message when npm packages are missing ([9159557](https://github.com/ElMassimo/vite_ruby/commit/9159557e5152547554cfe519fae8dbefe26686fb))



## [1.2.12](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.11...vite_ruby@1.2.12) (2021-06-08)


### Features

* Support Ruby 2.4 ([#87](https://github.com/ElMassimo/vite_ruby/issues/87)) ([8fc4d49](https://github.com/ElMassimo/vite_ruby/commit/8fc4d49c82817623df81d6f9f94654ea726eb050))



## [1.2.11](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.10...vite_ruby@1.2.11) (2021-05-10)

### Refactor

* Upgrade to dry-cli 0.7 while avoiding dependency on `dry-files` ([f5b87e](https://github.com/ElMassimo/vite_ruby/commit/f5b87e69790e48397d15e609b44118e399c9493d))


## [1.2.10](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.9...vite_ruby@1.2.10) (2021-05-09)


### Bug Fixes

* Lock dry-cli to 0.6 since 0.7 has breaking changes (close [#76](https://github.com/ElMassimo/vite_ruby/issues/76)) ([9883458](https://github.com/ElMassimo/vite_ruby/commit/9883458443cb0047cd4cceaf02de2a86066d624e))



## [1.2.9](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.8...vite_ruby@1.2.9) (2021-05-04)


### Bug Fixes

* Stream output during installation and don't skip installation of npm packages when no lockfile is detected ([#73](https://github.com/ElMassimo/vite_ruby/issues/73)) ([028a5ba](https://github.com/ElMassimo/vite_ruby/commit/028a5bae359085a36aa942d2ad63c23616a00ffb))



## [1.2.8](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.7...vite_ruby@1.2.8) (2021-04-29)


### Bug Fixes

* Don't modify url for minified css when proxying a request ([#71](https://github.com/ElMassimo/vite_ruby/issues/71)) ([d30a577](https://github.com/ElMassimo/vite_ruby/commit/d30a577a8436c4987d7c2e08e7eae68e589eb2a7))



## [1.2.7](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.6...vite_ruby@1.2.7) (2021-04-28)


### Bug Fixes

* Support Rails 5.1 by avoiding [incorrectly monkeypatched](https://github.com//github.com/rails/rails/blob/5-1-stable/activesupport/lib/active_support/core_ext/array/prepend_and_append.rb/issues/L2-L3) `Array#append` ([1b59551](https://github.com/ElMassimo/vite_ruby/commit/1b5955170b33a528a2b13d7e7e308e8493d97a91))



## [1.2.6](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.5...vite_ruby@1.2.6) (2021-04-26)


### Bug Fixes

* Update installation to use the latest version of the plugin ([#67](https://github.com/ElMassimo/vite_ruby/issues/67)) ([7e10636](https://github.com/ElMassimo/vite_ruby/commit/7e10636f5396f496bd099a03e069cf8572b9585b))



## [1.2.5](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.4...vite_ruby@1.2.5) (2021-04-21)


### Features

* Add helpers to enable HMR when using @vitejs/plugin-react-refresh ([a80f286](https://github.com/ElMassimo/vite_ruby/commit/a80f286d4305bbae29ea7cea42a4329a530f43fa))



## [1.2.4](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.3...vite_ruby@1.2.4) (2021-04-21)


### Bug Fixes

* Avoid removing `base` from proxied requests to avoid confusion. ([25f79a9](https://github.com/ElMassimo/vite_ruby/commit/25f79a9848df3e6c2ffbeb9bd4fbc44f73e4c68a))



## [1.2.3](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.2...vite_ruby@1.2.3) (2021-04-15)


### Features

* Add support for .scss, .less, and .styl entrypoints (close [#50](https://github.com/ElMassimo/vite_ruby/issues/50)) ([bb1d295](https://github.com/ElMassimo/vite_ruby/commit/bb1d2953b3a8c5862d26cdfcd5edc5cc918d1c5a))



## [1.2.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.1...vite_ruby@1.2.2) (2021-03-20)


### Bug Fixes

* Avoid prompts when using npx outside a CI ([ed7ccd7](https://github.com/ElMassimo/vite_ruby/commit/ed7ccd7d32c079ab78555ecd36dcb68ad2da331e))
* Simplify installation of build dependencies by using package manager flags ([5c8bb62](https://github.com/ElMassimo/vite_ruby/commit/5c8bb625926f2ab1788a3e3a22aeafd7104984cb))



## [1.2.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.2.0...vite_ruby@1.2.1) (2021-03-19)


### Bug Fixes

* Use the mode option in `clobber` ([add76b2](https://github.com/ElMassimo/vite_ruby/commit/add76b2a63ea64336235536b8b5670bace357b6e))



# [1.2.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.1.2...vite_ruby@1.2.0) (2021-03-19)


### Bug Fixes

* Improve error messages when the Vite executable is missing ([#41](https://github.com/ElMassimo/vite_ruby/issues/41)) ([a79edc6](https://github.com/ElMassimo/vite_ruby/commit/a79edc6cc603c1094ede9e899226e98f734e7bbe))


### Features

* Add `clobber` to the CLI, usable as `--clear` in the `dev` and `build` commands ([331d861](https://github.com/ElMassimo/vite_ruby/commit/331d86163c12eb3303d3975a94ecc205fa59dd41))
* Allow `clobber` to receive a `--mode` option. ([e6e7a6d](https://github.com/ElMassimo/vite_ruby/commit/e6e7a6dd0a2acf205d06877f76deb924c1d5aba7))



## [1.1.2](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.1.1...vite_ruby@1.1.2) (2021-03-19)


### Features

* Automatically retry failed builds after a certain time ([cbb3058](https://github.com/ElMassimo/vite_ruby/commit/cbb305863a49c46e7a0d95c773f56f7d822d01d9))



## [1.1.1](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.1.0...vite_ruby@1.1.1) (2021-03-19)


### Bug Fixes

* handle getaddrinfo errors when checking dev server ([#39](https://github.com/ElMassimo/vite_ruby/issues/39)) ([df57d6b](https://github.com/ElMassimo/vite_ruby/commit/df57d6ba5d8ed20e15bd2de3a57c8ff711671d28))



# [1.1.0](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.0.5...vite_ruby@1.1.0) (2021-03-07)


### Bug Fixes

* Add development mutex in manifest to prevent re-entrant builds ([a6c6976](https://github.com/ElMassimo/vite_ruby/commit/a6c6976ba3821d8d6f26d012de13a440cb91c95b))
* Allow passing --inspect and other options to the build command ([1818ea4](https://github.com/ElMassimo/vite_ruby/commit/1818ea4f1d211923dfe0c04037baca8b2fd3b991))


### Features

* Record status and timestamp of each build to provide better errors ([a35a64a](https://github.com/ElMassimo/vite_ruby/commit/a35a64ad4ca802da7bb6d5f5139985da864293a4))
* Stream build output to provide feedback as the command runs ([2bce338](https://github.com/ElMassimo/vite_ruby/commit/2bce33888513f6961da11ddfa9f9c703182abfa6))



## [1.0.5](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.0.4...vite_ruby@1.0.5) (2021-03-03)


### Bug Fixes

* Fix installation of JS packages, prevent silent failures (closes [#22](https://github.com/ElMassimo/vite_ruby/issues/22)) ([#23](https://github.com/ElMassimo/vite_ruby/issues/23)) ([d972e6f](https://github.com/ElMassimo/vite_ruby/commit/d972e6f3968988460753e7a831c8e9199bbd6891))



## [1.0.4](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.0.3...vite_ruby@1.0.4) (2021-02-25)


### Features

* Create Vite.js integration with Padrino ([#17](https://github.com/ElMassimo/vite_ruby/issues/17)) ([9e9a0a6](https://github.com/ElMassimo/vite_ruby/commit/9e9a0a67abceed0a784d3c2e0554c717d7f5d1d6))



## [1.0.3](https://github.com/ElMassimo/vite_ruby/compare/vite_ruby@1.0.2...vite_ruby@1.0.3) (2021-02-25)


### Bug Fixes

* Infer package manager correctly ([09d3036](https://github.com/ElMassimo/vite_ruby/commit/09d303627d6012ead50acd6f814a32521a76927f))



## Vite Ruby 1.0.2 (2020-02-10)

- Fix auto-compilation when the dev server is not available.

## Vite Ruby 1.0.1 (2020-02-10)

- Fix installation script in Ruby 2.5

## Vite Ruby 1.0.0 (2020-02-09)

- Initial release, extracted core functionality from `vite_rails`.
