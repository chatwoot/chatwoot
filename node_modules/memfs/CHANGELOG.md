## [3.2.2](https://github.com/streamich/memfs/compare/v3.2.1...v3.2.2) (2021-04-05)


### Bug Fixes

* **deps:** update dependency fs-monkey to v1.0.2 ([07f05db](https://github.com/streamich/memfs/commit/07f05db8b0aed43360abaf172d4297f3873d44fe))
* **deps:** update dependency fs-monkey to v1.0.3 ([84346ed](https://github.com/streamich/memfs/commit/84346ed7d0556b2b79f57b9b10889e54afcaebd1))

## [3.2.1](https://github.com/streamich/memfs/compare/v3.2.0...v3.2.1) (2021-03-31)


### Bug Fixes

* add `The Unlicense` license SDPX in package.json ([#594](https://github.com/streamich/memfs/issues/594)) ([0e7b04b](https://github.com/streamich/memfs/commit/0e7b04b0d5172846340e95619edaa18579ed5d06))

# [3.2.0](https://github.com/streamich/memfs/compare/v3.1.3...v3.2.0) (2020-05-19)


### Bug Fixes

* 'fromJSON()' did not consider cwd when creating directories ([3d6ee3b](https://github.com/streamich/memfs/commit/3d6ee3b2c0eef0345ba2bd400e9836f2d685321f))


### Features

* support nested objects in 'fromJSON()' ([f8c329c](https://github.com/streamich/memfs/commit/f8c329c8e57c85cc4a394a74802af1f37dcedefd))

## [3.1.3](https://github.com/streamich/memfs/compare/v3.1.2...v3.1.3) (2020-05-14)


### Bug Fixes

* **deps:** update dependency fs-monkey to v1.0.1 ([10fc705](https://github.com/streamich/memfs/commit/10fc705c46d57a4354afb9372a98dcdfed9d551d))

## [3.1.2](https://github.com/streamich/memfs/compare/v3.1.1...v3.1.2) (2020-03-12)


### Bug Fixes

* should throw `EEXIST` instead of `EISDIR` on `mkdirSync('/')` ([f89eede](https://github.com/streamich/memfs/commit/f89eede9530c3f5bd8d8a523be1927d396cda662))

## [3.1.1](https://github.com/streamich/memfs/compare/v3.1.0...v3.1.1) (2020-02-17)


### Bug Fixes

* **deps:** update dependency fs-monkey to v1 ([ccd1be0](https://github.com/streamich/memfs/commit/ccd1be08c5b13dd620ed814def1a84b81614cab2))

# [3.1.0](https://github.com/streamich/memfs/compare/v3.0.6...v3.1.0) (2020-02-17)


### Features

* replace `fast-extend` with native `Object.assign` ([934f1f3](https://github.com/streamich/memfs/commit/934f1f31948e5b4afc9ea101f9c5ad20017df217))
* specify `engines` field with `node` constraint of `>= 8.3.0` ([7d3b132](https://github.com/streamich/memfs/commit/7d3b132c35639c10a5750e8e17b839b619f2ab41))

## [3.0.6](https://github.com/streamich/memfs/compare/v3.0.5...v3.0.6) (2020-02-16)


### Bug Fixes

* export `DirectoryJSON` from `index` ([c447a6c](https://github.com/streamich/memfs/commit/c447a6c8f8ee66b8a55d4cb2a2a2279ab5cf03d1))

## [3.0.5](https://github.com/streamich/memfs/compare/v3.0.4...v3.0.5) (2020-02-15)


### Bug Fixes

* remove space from error message ([42f870a](https://github.com/streamich/memfs/commit/42f870a31d902f37ccdad7915df8e7806cd3ce29))
* use `IStore` interface instead of `Storage` ([ff82480](https://github.com/streamich/memfs/commit/ff824809b84c98e0ee26b81e601e983bfb6c2e97))
* use `PathLike` type from node ([98a4014](https://github.com/streamich/memfs/commit/98a40143dbc0422541458e1f3243b3c4656e1e98))

## [3.0.4](https://github.com/streamich/memfs/compare/v3.0.3...v3.0.4) (2020-01-15)


### Bug Fixes

* 🐛 handle opening directories with O_DIRECTORY ([acdfac8](https://github.com/streamich/memfs/commit/acdfac872b657776d32f1bfd346726c422a199f0)), closes [#494](https://github.com/streamich/memfs/issues/494)

## [3.0.3](https://github.com/streamich/memfs/compare/v3.0.2...v3.0.3) (2019-12-25)


### Bug Fixes

* **rmdir:** proper async functionality ([cc75c56](https://github.com/streamich/memfs/commit/cc75c566b8d485720457315d267c0d8cab6283cf))
* **rmdir:** support recursive option ([1e943ae](https://github.com/streamich/memfs/commit/1e943ae5911b3490f6c78d92a16ee0920480265c))
* **watch:** suppress event-emitter warnings ([1ab2dcb](https://github.com/streamich/memfs/commit/1ab2dcb4706b7fe02868d94e335673b72d1ce0d7))

## [3.0.2](https://github.com/streamich/memfs/compare/v3.0.1...v3.0.2) (2019-12-25)


### Bug Fixes

* **watch:** trigger change event for creation/deletion of children in a folder ([b1b7884](https://github.com/streamich/memfs/commit/b1b7884d4b9af734773c178ab4377e55a5bb2cc6))

## [3.0.1](https://github.com/streamich/memfs/compare/v3.0.0...v3.0.1) (2019-11-26)


### Performance Improvements

* ⚡️ bump fast-extend ([606775b](https://github.com/streamich/memfs/commit/606775bb6f20bc16a53b911d2a095bf8a6385e1a))

# [3.0.0](https://github.com/streamich/memfs/compare/v2.17.1...v3.0.0) (2019-11-26)


### Bug Fixes

* 🐛 adjust definition of `TCallback` to accept `null` for `error` parameter ([aedcbda](https://github.com/streamich/memfs/commit/aedcbda69178406f098abffd731e6ff87e39bf1e))
* 🐛 adjust return of `Link#walk` to return `Link | null` ([1b76cb1](https://github.com/streamich/memfs/commit/1b76cb18d0eb2494c69a2ac58304437eb3a80aef))
* 🐛 adjust type of `children` in `Link` to be possibly undefined ([b4945c2](https://github.com/streamich/memfs/commit/b4945c2fe9ffb49949bf133d157602ef7c9799d6))
* 🐛 allow `_modeToNumber` to be called w/ `undefined` ([07c0b7a](https://github.com/streamich/memfs/commit/07c0b7a4e99d7cf7b4d6fa73611d13f49e973ce0))
* 🐛 allow `_modeToNumber` to return `undefined` ([3e3c992](https://github.com/streamich/memfs/commit/3e3c992c135df489b066c4ac5a5dc022a5ce515c))
* 🐛 allow `assertEncoding` to be called w/ `undefined` ([e37ab9a](https://github.com/streamich/memfs/commit/e37ab9ad940215d3eb62c533e43c590e81e76f73))
* 🐛 allow `Dirent~build` to accept `undefined` for the `encoding` parameter ([8ca3550](https://github.com/streamich/memfs/commit/8ca355033bc6845e3f89222e4239e6d42bff8cbf))
* 🐛 allow `flagsToNumber` to be called w/ `undefined` ([dbfc754](https://github.com/streamich/memfs/commit/dbfc7546d32dffec7b154ed4db8a0c839d68fbda))
* 🐛 allow `mkdtempBase` to be called w/ `undefined` for `encoding` ([f28c395](https://github.com/streamich/memfs/commit/f28c39524fd1c219cb649fee71fcb9077cc1c65a))
* 🐛 allow `modeToNumber` to be called w/ `undefined` ([336821d](https://github.com/streamich/memfs/commit/336821dea78da61739177de57fe10d4e5fcc71ff))
* 🐛 allow `realpathBase` to be called w/ `undefined` for `encoding` ([e855f1c](https://github.com/streamich/memfs/commit/e855f1c8a82bdbd77790c3734d89e54ce01fd3ff))
* 🐛 create `tryGetChild` util function ([b5093a1](https://github.com/streamich/memfs/commit/b5093a12d221e39bc796d5c06819106980845414))
* 🐛 create `tryGetChildNode` util function ([62b5a52](https://github.com/streamich/memfs/commit/62b5a52e93af91c7d3aefcaeb9955f100e2ee841))
* 🐛 define the type elements in the `Volume.releasedFds` array ([9e21f3a](https://github.com/streamich/memfs/commit/9e21f3a4d66b408611aba55e3856f92a3a86eec8))
* 🐛 don't assign `null` to `._link` property in `FSWatcher` ([71569c0](https://github.com/streamich/memfs/commit/71569c0cfece432fa90a2b86439c375a55aec507))
* 🐛 don't assign `null` to `._steps` property in `FSWatcher` ([0e94b9c](https://github.com/streamich/memfs/commit/0e94b9c83604fb040b9bb09a3fb3b4e5b6a234ed))
* 🐛 don't assign `null` to `.buf` property in `Node` ([00be0c2](https://github.com/streamich/memfs/commit/00be0c25766943e1aec0c5cfdfa97562a391d4a4))
* 🐛 don't assign `null` to `.link` property in `File` ([5d01713](https://github.com/streamich/memfs/commit/5d017135190fa1a5001fe348e003cbd7a87a504a))
* 🐛 don't assign `null` to `.node` property in `File` ([d06201e](https://github.com/streamich/memfs/commit/d06201e4def96703aa72af2c3eb3526ec26d1daf))
* 🐛 don't assign `null` to `.node` property in `Link` ([4d7f439](https://github.com/streamich/memfs/commit/4d7f439b476e8f2f92a755af288f108e3cdf9263))
* 🐛 don't assign `null` to `.parent` property in `Link` ([b3e60b6](https://github.com/streamich/memfs/commit/b3e60b6475b478f4b65a5a80ac014cf24024f9be))
* 🐛 don't assign `null` to `.symlink` property in `Node` ([9bfb6f5](https://github.com/streamich/memfs/commit/9bfb6f593f5c89426d834b5efe57bb33667f43f7))
* 🐛 don't assign `null` to `StatWatcher.prev` property ([fd1a253](https://github.com/streamich/memfs/commit/fd1a253029631cad6bbb1467ac56bab379f3b921))
* 🐛 don't assign `null` to `StatWatcher.vol` property ([1540522](https://github.com/streamich/memfs/commit/15405222841ee846210f1ae17351beef7c8dcc57))
* 🐛 don't set `#vol` or `#parent` of `link` to `null` ([b396f04](https://github.com/streamich/memfs/commit/b396f041f93709379feb3883321ccba21da8a569))
* 🐛 enable `strictNullChecks` ([3896de7](https://github.com/streamich/memfs/commit/3896de79a59fa5a8237e922304f5636e614e2d32))
* 🐛 make `StatWatcher.timeoutRef` property optional ([d09cd03](https://github.com/streamich/memfs/commit/d09cd035ceac44d3ebcb6ef12be7c4b5f1ccbca4))
* 🐛 refactor `#access` to be compatible w/ `strictNullChecks` ([82ed81b](https://github.com/streamich/memfs/commit/82ed81b32a0709296ef36dfed26032628bddcf5c))
* 🐛 refactor `#copyFileSync` to be compatible w/ `strictNullChecks` ([40f8337](https://github.com/streamich/memfs/commit/40f8337a21abe9ecc48576ad012c585f73df2e35))
* 🐛 refactor `#createLink` to be compatible w/ `strictNullChecks` ([7d8559d](https://github.com/streamich/memfs/commit/7d8559d022de1c0ba14d6081be585d549b69529b))
* 🐛 refactor `#ftruncate` to be compatible w/ `strictNullChecks` ([f2ea3f1](https://github.com/streamich/memfs/commit/f2ea3f1c7aa094243cc916c5f8fe716efc6c9b11))
* 🐛 refactor `#mkdir` to be compatible w/ `strictNullChecks` ([d5d7883](https://github.com/streamich/memfs/commit/d5d78839be0ed1c39bdee0c2b20627d94107f4ed))
* 🐛 refactor `#mkdirp` to be compatible w/ `strictNullChecks` ([6cf0bce](https://github.com/streamich/memfs/commit/6cf0bceb5a71743a5dd4ff15d37a8af77f6d9b5c))
* 🐛 refactor `#mkdtempBase` to be compatible w/ `strictNullChecks` ([d935b3b](https://github.com/streamich/memfs/commit/d935b3b3240c2328207ce01885bd4fcc8b5310db))
* 🐛 refactor `#mkdtempSync` to be compatible w/ `strictNullChecks` ([7e22617](https://github.com/streamich/memfs/commit/7e22617c55ac935edf5dc0dc093e3e8c393c7d2d))
* 🐛 refactor `#newFdNumber` to be compatible w/ `strictNullChecks` ([0bc4a15](https://github.com/streamich/memfs/commit/0bc4a1569af6ea5a98f4ee51a84ca770f302fc21))
* 🐛 refactor `#newInoNumber` to be compatible w/ `strictNullChecks` ([e9ba56c](https://github.com/streamich/memfs/commit/e9ba56c0a1a1cc9fbd443297dddf58559c782789))
* 🐛 refactor `#openFile` to be compatible w/ `strictNullChecks` ([1c4a4ba](https://github.com/streamich/memfs/commit/1c4a4ba78e99d3250b1e6f25952408e21b9cacfc))
* 🐛 refactor `#openLink` to be compatible w/ `strictNullChecks` ([216a85f](https://github.com/streamich/memfs/commit/216a85f4d279a9d1a300c745b365a79fa2da450e))
* 🐛 refactor `#read` to be compatible w/ `strictNullChecks` ([87b587f](https://github.com/streamich/memfs/commit/87b587fa6738d3ecfeca8f2ee41704665602131b))
* 🐛 refactor `#readdirBase` to be compatible w/ `strictNullChecks` ([ab248b4](https://github.com/streamich/memfs/commit/ab248b4071fab8e51c5d2b9c3f8e5828c86798cb))
* 🐛 refactor `#readFileBase` to be compatible w/ `strictNullChecks` ([27a4dad](https://github.com/streamich/memfs/commit/27a4dada340fa91f36449f2b2477accee79c12d1))
* 🐛 refactor `#readlinkBase` to be compatible w/ `strictNullChecks` ([b2e0f76](https://github.com/streamich/memfs/commit/b2e0f76415f2248bde783bed216f9adca994465a))
* 🐛 refactor `#resolveSymlinks` to be compatible w/ `strictNullChecks` ([6dc4913](https://github.com/streamich/memfs/commit/6dc49130d248510fa31c1480f04c7be412a71158))
* 🐛 refactor `#statBase` to be compatible w/ `strictNullChecks` ([ba0c20a](https://github.com/streamich/memfs/commit/ba0c20a098ac4f5e7be85b3503418074c681c3b0))
* 🐛 refactor `#symlink` to be compatible w/ `strictNullChecks` ([4148ad3](https://github.com/streamich/memfs/commit/4148ad399a01a8532986e359e726872d0e207885))
* 🐛 refactor `#truncate` to be compatible w/ `strictNullChecks` ([fadbd77](https://github.com/streamich/memfs/commit/fadbd771ca113758772dc50b999fb74d79db2e15))
* 🐛 refactor `#watch` to be compatible w/ `strictNullChecks` ([415a186](https://github.com/streamich/memfs/commit/415a186553bbf575d3447622a1a309b0665e0e14))
* 🐛 refactor `#watchFile` to be compatible w/ `strictNullChecks` ([2c02287](https://github.com/streamich/memfs/commit/2c02287f2cbdf16197ad1d67f7a9ca022bebf6af))
* 🐛 refactor `#write` to be compatible w/ `strictNullChecks` ([2ba6e0f](https://github.com/streamich/memfs/commit/2ba6e0f8883dabeb1f31684f4f6743cbd3eb3d39))
* 🐛 refactor `#writeFile` to be compatible w/ `strictNullChecks` ([ac78c50](https://github.com/streamich/memfs/commit/ac78c50d3108d3e706ad7c510af9f1125f9cd265))
* 🐛 refactor `#writeFileBase` to be compatible w/ `strictNullChecks` ([e931778](https://github.com/streamich/memfs/commit/e931778b9340f39560a45e47a1052826476f4941))
* 🐛 refactor `#writeSync` to be compatible w/ `strictNullChecks` ([7b67eea](https://github.com/streamich/memfs/commit/7b67eea4448a9b4e102f92ddf36d13ce03ea33b6))
* 🐛 refactor `copyFile` tests to be compatible w/ `strictNullChecks` ([e318af2](https://github.com/streamich/memfs/commit/e318af2e810c482f721299e924721981fc9b9979))
* 🐛 refactor `errors` to be compatible w/ `strictNullChecks` ([b25c035](https://github.com/streamich/memfs/commit/b25c03560eabfff1b55a6e360453cc6ba568b811))
* 🐛 refactor `exists` tests to be compatible w/ `strictNullChecks` ([81a564f](https://github.com/streamich/memfs/commit/81a564f17202a4db4564fd2171c785731285c64c))
* 🐛 refactor `renameSync` tests to use `tryGetChildNode` ([8cd782a](https://github.com/streamich/memfs/commit/8cd782ab1407e2888678b27831c4ec0f2f6f22ef))
* 🐛 refactor `volume` tests to be compatible w/ `strictNullChecks` ([f02fbac](https://github.com/streamich/memfs/commit/f02fbacaab0cec7d08f27ab5b58a7e3f39adba63))
* 🐛 refactor `volume` tests to use `tryGetChild` ([5a6624f](https://github.com/streamich/memfs/commit/5a6624f992626e8c790b8569557d1d9ae01f52ad))
* 🐛 refactor `volume` tests to use `tryGetChildNode` ([34acaac](https://github.com/streamich/memfs/commit/34acaacdc8567027a794c9896c86cd7b6a2b5c11))
* 🐛 refactor `writeFileSync` tests to be compatible w/ `strictNullChecks` ([4b7f164](https://github.com/streamich/memfs/commit/4b7f1643cc312f12fb2dcc7aa3b1b3fc08ff007f))
* 🐛 remove unused `getArgAndCb` function ([f8bb0f8](https://github.com/streamich/memfs/commit/f8bb0f852c560d55ee9af400da9a786e8a94b1ea))
* 🐛 replace `throwError` fn w/ inline `throw createError()` calls ([c9a0fd6](https://github.com/streamich/memfs/commit/c9a0fd6adcfd9fb17a7aa3ccd3e418b83c198771))


### Features

* 🎸 enable TypeScript strict null checks ([1998b24](https://github.com/streamich/memfs/commit/1998b24e65d68ae95183382ed6ed400acf57c535))


### BREAKING CHANGES

* TypeScript strict null checks are now enabled which may
break some TypeScript users.

## [2.17.1](https://github.com/streamich/memfs/compare/v2.17.0...v2.17.1) (2019-11-26)

### Bug Fixes

- set-up semantic-release packages ([0554c7e](https://github.com/streamich/memfs/commit/0554c7e9ae472e4a3f7afe47d5aa990abd7f05bf))

## [2.15.5](https://github.com/streamich/memfs/compare/v2.15.4...v2.15.5) (2019-07-16)

### Bug Fixes

- check for process ([8b9b00c](https://github.com/streamich/memfs/commit/8b9b00c))
- check for process ([#396](https://github.com/streamich/memfs/issues/396)) ([2314dad](https://github.com/streamich/memfs/commit/2314dad))

## [2.15.4](https://github.com/streamich/memfs/compare/v2.15.3...v2.15.4) (2019-06-01)

### Bug Fixes

- 🐛 accept `null` as value in `fromJSON` functions ([9e1af7d](https://github.com/streamich/memfs/commit/9e1af7d))
- 🐛 annotate return type of `toJSON` functions ([6609840](https://github.com/streamich/memfs/commit/6609840))

## [2.15.3](https://github.com/streamich/memfs/compare/v2.15.2...v2.15.3) (2019-06-01)

### Bug Fixes

- 🐛 mocks process.emitWarning for browser compatibility ([e3456b2](https://github.com/streamich/memfs/commit/e3456b2)), closes [#374](https://github.com/streamich/memfs/issues/374)

## [2.15.2](https://github.com/streamich/memfs/compare/v2.15.1...v2.15.2) (2019-02-16)

### Bug Fixes

- 🐛 BigInt type handling ([c640f25](https://github.com/streamich/memfs/commit/c640f25))

## [2.15.1](https://github.com/streamich/memfs/compare/v2.15.0...v2.15.1) (2019-02-09)

### Bug Fixes

- 🐛 show directory path when throwing EISDIR in mkdir ([9dc7007](https://github.com/streamich/memfs/commit/9dc7007))
- 🐛 throw when creating root directory ([f77fa8b](https://github.com/streamich/memfs/commit/f77fa8b)), closes [#325](https://github.com/streamich/memfs/issues/325)

# [2.15.0](https://github.com/streamich/memfs/compare/v2.14.2...v2.15.0) (2019-01-27)

### Features

- **volume:** add env variable to suppress fs.promise api warnings ([e6b6d0a](https://github.com/streamich/memfs/commit/e6b6d0a))

## [2.14.2](https://github.com/streamich/memfs/compare/v2.14.1...v2.14.2) (2018-12-11)

### Bug Fixes

- fds to start from 0x7fffffff instead of 0xffffffff ([#277](https://github.com/streamich/memfs/issues/277)) ([31e44ba](https://github.com/streamich/memfs/commit/31e44ba))

## [2.14.1](https://github.com/streamich/memfs/compare/v2.14.0...v2.14.1) (2018-11-29)

### Bug Fixes

- don't copy legacy files into dist ([ab8ffbb](https://github.com/streamich/memfs/commit/ab8ffbb)), closes [#263](https://github.com/streamich/memfs/issues/263)

# [2.14.0](https://github.com/streamich/memfs/compare/v2.13.1...v2.14.0) (2018-11-12)

### Features

- add bigint option support ([00a017e](https://github.com/streamich/memfs/commit/00a017e))

## [2.13.1](https://github.com/streamich/memfs/compare/v2.13.0...v2.13.1) (2018-11-11)

### Bug Fixes

- 🐛 don't install semantic-release, incompat with old Node ([cd2b69c](https://github.com/streamich/memfs/commit/cd2b69c))
