# Changelog

## [v4.19.0](https://github.com/drwl/annotaterb/tree/v4.19.0) (2025-08-28)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.18.0...v4.19.0)

**Implemented enhancements:**

- ignore ActiveRecord::AssociatedObject [\#172](https://github.com/drwl/annotaterb/issues/172)

**Closed issues:**

- STI classes blank [\#252](https://github.com/drwl/annotaterb/issues/252)
- Model annotation issue [\#249](https://github.com/drwl/annotaterb/issues/249)

**Merged pull requests:**

- Bump version to v4.19.0 [\#259](https://github.com/drwl/annotaterb/pull/259) ([drwl](https://github.com/drwl))
- Fix STI models not being annotated [\#256](https://github.com/drwl/annotaterb/pull/256) ([drwl](https://github.com/drwl))
- refactor: relocate migration\_version\_for\_model method to ModelWrapper [\#255](https://github.com/drwl/annotaterb/pull/255) ([OdenTakashi](https://github.com/OdenTakashi))
- Fix: Skip abstract models during annotation [\#253](https://github.com/drwl/annotaterb/pull/253) ([taise](https://github.com/taise))
- Fix Ruby 3.3.8 compatibility and improve Zeitwerk support for non-Rails projects [\#250](https://github.com/drwl/annotaterb/pull/250) ([bradley2W1DL](https://github.com/bradley2W1DL))
- Return a model files array even if it’s empty [\#248](https://github.com/drwl/annotaterb/pull/248) ([Flink](https://github.com/Flink))
- Generate changelog for v4.18.0 [\#247](https://github.com/drwl/annotaterb/pull/247) ([drwl](https://github.com/drwl))

## [v4.18.0](https://github.com/drwl/annotaterb/tree/v4.18.0) (2025-08-04)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.17.0...v4.18.0)

**Implemented enhancements:**

- Feature request: support for multi database [\#188](https://github.com/drwl/annotaterb/issues/188)

**Closed issues:**

- Does not run on rollback with multiple databases [\#244](https://github.com/drwl/annotaterb/issues/244)
- classified\_sort and polymorphic associations [\#236](https://github.com/drwl/annotaterb/issues/236)
- --show-migration also annotates the primary DB's schema version for models referencing the secondary DB [\#233](https://github.com/drwl/annotaterb/issues/233)
- Annotations are not added on top of model files when columns'`comment:` contains Japanese characters in migrations [\#200](https://github.com/drwl/annotaterb/issues/200)
- Feature: further customization to achieve more compact annotations [\#150](https://github.com/drwl/annotaterb/issues/150)
- Version 5 change list [\#127](https://github.com/drwl/annotaterb/issues/127)
- Reformat Column Comments [\#117](https://github.com/drwl/annotaterb/issues/117)

**Merged pull requests:**

- Bump version to v4.18.0 [\#246](https://github.com/drwl/annotaterb/pull/246) ([drwl](https://github.com/drwl))
- Run on rollback in app with multiple databases [\#245](https://github.com/drwl/annotaterb/pull/245) ([z1lk](https://github.com/z1lk))
- Speed up AnnotationDecider [\#243](https://github.com/drwl/annotaterb/pull/243) ([DRBragg](https://github.com/DRBragg))
- Add AnnotateRb::Runner.running? method [\#242](https://github.com/drwl/annotaterb/pull/242) ([thewatts](https://github.com/thewatts))
- fix: --show-migration to use per-model database connections [\#241](https://github.com/drwl/annotaterb/pull/241) ([OdenTakashi](https://github.com/OdenTakashi))
- Fix: Support Japanese characters in column names [\#239](https://github.com/drwl/annotaterb/pull/239) ([tonystrawberry](https://github.com/tonystrawberry))
- Fix classified\_sort to group polymorphic association columns together [\#238](https://github.com/drwl/annotaterb/pull/238) ([garriguv](https://github.com/garriguv))
- Generate changelog for v4.17.0 [\#235](https://github.com/drwl/annotaterb/pull/235) ([drwl](https://github.com/drwl))

## [v4.17.0](https://github.com/drwl/annotaterb/tree/v4.17.0) (2025-07-14)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.16.0...v4.17.0)

**Implemented enhancements:**

- Place column comments at the end of the line \(feature suggestion\) [\#164](https://github.com/drwl/annotaterb/issues/164)

**Fixed bugs:**

- Model annotation chokes on an empty file [\#182](https://github.com/drwl/annotaterb/issues/182)

**Closed issues:**

- uninitialized constant Zeitwerk::VERSION [\#216](https://github.com/drwl/annotaterb/issues/216)
- Incorrect annotation of fixture files when different models share the same table name in different databases [\#206](https://github.com/drwl/annotaterb/issues/206)
- Should active record and active support be in the gemspec? [\#197](https://github.com/drwl/annotaterb/issues/197)

**Merged pull requests:**

- Bump version to v4.17.0 [\#234](https://github.com/drwl/annotaterb/pull/234) ([drwl](https://github.com/drwl))
- Fix NoMethodError when processing empty files [\#232](https://github.com/drwl/annotaterb/pull/232) ([tanukiti1987](https://github.com/tanukiti1987))
- Refactor column ignore to use `match?` [\#231](https://github.com/drwl/annotaterb/pull/231) ([tagliala](https://github.com/tagliala))
- Fix standard configuration [\#230](https://github.com/drwl/annotaterb/pull/230) ([tagliala](https://github.com/tagliala))
- Generate changelog for v4.16.0 [\#229](https://github.com/drwl/annotaterb/pull/229) ([drwl](https://github.com/drwl))
- show included columns in indexes [\#211](https://github.com/drwl/annotaterb/pull/211) ([pineman](https://github.com/pineman))
- fix: use model name for file retrieval when not connected to the primary DB. [\#207](https://github.com/drwl/annotaterb/pull/207) ([OdenTakashi](https://github.com/OdenTakashi))
- Place column comments at the end of the line [\#199](https://github.com/drwl/annotaterb/pull/199) ([Adeynack](https://github.com/Adeynack))

## [v4.16.0](https://github.com/drwl/annotaterb/tree/v4.16.0) (2025-06-18)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.15.0...v4.16.0)

**Implemented enhancements:**

- Feature Request: Add Option to Place Annotations Above Nested Classes or Modules. [\#186](https://github.com/drwl/annotaterb/issues/186)

**Closed issues:**

- Misleading pattern examples in documentation for `additional_file_patterns` [\#221](https://github.com/drwl/annotaterb/issues/221)
- Permission denied for table pg\_index [\#209](https://github.com/drwl/annotaterb/issues/209)
- Performance regression relative to pre-fork? [\#205](https://github.com/drwl/annotaterb/issues/205)
- Add back ruby configuration option? [\#203](https://github.com/drwl/annotaterb/issues/203)
- Enable frozen mode when CI environment variable is set [\#171](https://github.com/drwl/annotaterb/issues/171)

**Merged pull requests:**

-  Bump version to v4.16.0 [\#228](https://github.com/drwl/annotaterb/pull/228) ([drwl](https://github.com/drwl))
- chore: add --with-column-comments readme documentation [\#227](https://github.com/drwl/annotaterb/pull/227) ([jonmcelroy-appfolio](https://github.com/jonmcelroy-appfolio))
- Drop Ruby 2.7 support and improve CI [\#226](https://github.com/drwl/annotaterb/pull/226) ([drwl](https://github.com/drwl))
- Pass .annotaterb.yml through ERB [\#225](https://github.com/drwl/annotaterb/pull/225) ([fxn](https://github.com/fxn))
- feat: Add `--nested-position` option for placing annotations above nested classes. [\#223](https://github.com/drwl/annotaterb/pull/223) ([yamat47](https://github.com/yamat47))
- Fix for: Misleading pattern examples in documentation for additional\_file\_patterns [\#222](https://github.com/drwl/annotaterb/pull/222) ([skliarov](https://github.com/skliarov))
- Move activerecord dependency into gemspec [\#220](https://github.com/drwl/annotaterb/pull/220) ([drwl](https://github.com/drwl))
- Generate changelog for v4.15.0 [\#219](https://github.com/drwl/annotaterb/pull/219) ([drwl](https://github.com/drwl))
- chore: add rake task to automatically deploy to rubygems [\#183](https://github.com/drwl/annotaterb/pull/183) ([OdenTakashi](https://github.com/OdenTakashi))

## [v4.15.0](https://github.com/drwl/annotaterb/tree/v4.15.0) (2025-05-30)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.14.1...v4.15.0)

**Closed issues:**

- Feature request: packs-rails support [\#99](https://github.com/drwl/annotaterb/issues/99)
- Annotate models using Zeitwerk namespaces [\#82](https://github.com/drwl/annotaterb/issues/82)

**Merged pull requests:**

- Bump version to v4.15.0 [\#218](https://github.com/drwl/annotaterb/pull/218) ([drwl](https://github.com/drwl))
- Add debug logs for model annotation [\#217](https://github.com/drwl/annotaterb/pull/217) ([jarredhawkins](https://github.com/jarredhawkins))
- Cache retrieved indexes in ModelWrapper [\#215](https://github.com/drwl/annotaterb/pull/215) ([tr4b4nt](https://github.com/tr4b4nt))
- feat: identify unique indexes in simple\_indexes option [\#214](https://github.com/drwl/annotaterb/pull/214) ([amerritt14](https://github.com/amerritt14))
- fix: Handle case when table\_name\_prefix specified as symbol [\#208](https://github.com/drwl/annotaterb/pull/208) ([gururuby](https://github.com/gururuby))
- Support the glob pattern in `root_dir` and `model_dir` [\#198](https://github.com/drwl/annotaterb/pull/198) ([sinsoku](https://github.com/sinsoku))
- Fix `changelog_uri` in gemspec [\#192](https://github.com/drwl/annotaterb/pull/192) ([y-yagi](https://github.com/y-yagi))
- Generate changelog for v4.14.0 [\#191](https://github.com/drwl/annotaterb/pull/191) ([drwl](https://github.com/drwl))
- feat: add `timestamp_columns` config option [\#173](https://github.com/drwl/annotaterb/pull/173) ([pbernays](https://github.com/pbernays))

## [v4.14.1](https://github.com/drwl/annotaterb/tree/v4.14.1) (2025-03-31)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.14.0...v4.14.1)

**Closed issues:**

- Sort by database order [\#194](https://github.com/drwl/annotaterb/issues/194)
- “wrong number of arguments \(given 0, expected 1..2\)” when using enum in a Rails 8 model [\#184](https://github.com/drwl/annotaterb/issues/184)

## [v4.14.0](https://github.com/drwl/annotaterb/tree/v4.14.0) (2025-02-17)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.13.0...v4.14.0)

**Closed issues:**

- How do I annotate models but NOT routes? [\#178](https://github.com/drwl/annotaterb/issues/178)
- Model Annotation Not Updated When Modifying Table Columns Using change\_table. [\#169](https://github.com/drwl/annotaterb/issues/169)
- annotate\_rb:install failing on Rails 8 [\#168](https://github.com/drwl/annotaterb/issues/168)
- Annotations with enums changing between db:create db:migrate and then db:migrate [\#167](https://github.com/drwl/annotaterb/issues/167)
- JSON parse error [\#155](https://github.com/drwl/annotaterb/issues/155)
- Feature: Add Support for dynamic fixtures with ERB [\#149](https://github.com/drwl/annotaterb/issues/149)

**Merged pull requests:**

- Bump version to v4.14.0 [\#190](https://github.com/drwl/annotaterb/pull/190) ([drwl](https://github.com/drwl))
- Add expected file to automatically require [\#185](https://github.com/drwl/annotaterb/pull/185) ([drwl](https://github.com/drwl))
- Fix translation foreign key exclusion bug [\#181](https://github.com/drwl/annotaterb/pull/181) ([galori](https://github.com/galori))
- Lock `concurrent-ruby` gem to fix CI [\#180](https://github.com/drwl/annotaterb/pull/180) ([tagliala](https://github.com/tagliala))
- Chore: alert when multiple conmmands were selected [\#179](https://github.com/drwl/annotaterb/pull/179) ([OdenTakashi](https://github.com/OdenTakashi))
- Updated COLUMN\_PATTERN to handle optional metadata \(e.g., constraints or descriptions\) enclosed in parentheses. [\#170](https://github.com/drwl/annotaterb/pull/170) ([hatsu38](https://github.com/hatsu38))
- Opt-in for MFA requirement [\#166](https://github.com/drwl/annotaterb/pull/166) ([tagliala](https://github.com/tagliala))
- Fix typos [\#165](https://github.com/drwl/annotaterb/pull/165) ([tagliala](https://github.com/tagliala))
- Add support for virtual columns [\#163](https://github.com/drwl/annotaterb/pull/163) ([robbevp](https://github.com/robbevp))
- Generate changelog for v4.13.0 [\#160](https://github.com/drwl/annotaterb/pull/160) ([drwl](https://github.com/drwl))

## [v4.13.0](https://github.com/drwl/annotaterb/tree/v4.13.0) (2024-10-21)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.12.0...v4.13.0)

**Closed issues:**

- Bug: Bigint are reported as integer [\#157](https://github.com/drwl/annotaterb/issues/157)
- Bug \(apparently\): :ignore\_columns does not work \(with any syntax I've tried\) [\#154](https://github.com/drwl/annotaterb/issues/154)

**Merged pull requests:**

- Bump version to v4.13.0 [\#159](https://github.com/drwl/annotaterb/pull/159) ([drwl](https://github.com/drwl))
- Support parsing of dynamic fixture erb yml files [\#158](https://github.com/drwl/annotaterb/pull/158) ([drwl](https://github.com/drwl))
- Fix updating of indexes containing escaped characters [\#156](https://github.com/drwl/annotaterb/pull/156) ([antonivanopoulos](https://github.com/antonivanopoulos))
- Add model with association and foreign key to dummyapp [\#153](https://github.com/drwl/annotaterb/pull/153) ([drwl](https://github.com/drwl))
- Generate changelog for v4.12.0 [\#152](https://github.com/drwl/annotaterb/pull/152) ([drwl](https://github.com/drwl))

## [v4.12.0](https://github.com/drwl/annotaterb/tree/v4.12.0) (2024-09-15)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.11.0...v4.12.0)

**Merged pull requests:**

- Bump version to v4.12.0 [\#151](https://github.com/drwl/annotaterb/pull/151) ([drwl](https://github.com/drwl))
- Support postgres NULLS NOT DISTINCT clause in unique index [\#148](https://github.com/drwl/annotaterb/pull/148) ([ENewmeration](https://github.com/ENewmeration))
- Generate changelog for v4.11.0 [\#147](https://github.com/drwl/annotaterb/pull/147) ([drwl](https://github.com/drwl))

## [v4.11.0](https://github.com/drwl/annotaterb/tree/v4.11.0) (2024-08-16)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.10.2...v4.11.0)

**Closed issues:**

- Include the length of comments in max\_schema\_info\_width only when the with\_column\_comments option is true. [\#144](https://github.com/drwl/annotaterb/issues/144)
- Rakefile seems to be loaded twice [\#130](https://github.com/drwl/annotaterb/issues/130)

**Merged pull requests:**

- Bump version to v4.11.0 [\#146](https://github.com/drwl/annotaterb/pull/146) ([drwl](https://github.com/drwl))
- Include the length of comments in max\_schema\_info\_width only when the with\_comment and with\_column\_comments option is true. [\#145](https://github.com/drwl/annotaterb/pull/145) ([shibaaaa](https://github.com/shibaaaa))
- Add Ruby 3.3 to CI [\#143](https://github.com/drwl/annotaterb/pull/143) ([drwl](https://github.com/drwl))
- Generate changelog for v4.10.2 [\#142](https://github.com/drwl/annotaterb/pull/142) ([drwl](https://github.com/drwl))

## [v4.10.2](https://github.com/drwl/annotaterb/tree/v4.10.2) (2024-07-23)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.10.1...v4.10.2)

**Closed issues:**

- Composite primary keys are unsupported [\#138](https://github.com/drwl/annotaterb/issues/138)

**Merged pull requests:**

- Bump version to v4.10.2 [\#141](https://github.com/drwl/annotaterb/pull/141) ([drwl](https://github.com/drwl))
- Fix double-loading of Rakefile [\#140](https://github.com/drwl/annotaterb/pull/140) ([dmke](https://github.com/dmke))
- Change structure of model annotation builder [\#136](https://github.com/drwl/annotaterb/pull/136) ([drwl](https://github.com/drwl))
- Refactor model annotation components [\#134](https://github.com/drwl/annotaterb/pull/134) ([drwl](https://github.com/drwl))
- Generate changelog for v4.10.1 [\#133](https://github.com/drwl/annotaterb/pull/133) ([drwl](https://github.com/drwl))

## [v4.10.1](https://github.com/drwl/annotaterb/tree/v4.10.1) (2024-07-07)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.10.0...v4.10.1)

**Merged pull requests:**

- Bump version to v4.10.1 [\#132](https://github.com/drwl/annotaterb/pull/132) ([drwl](https://github.com/drwl))
- Correct uses of `respond_to` in AnnotationDecider [\#131](https://github.com/drwl/annotaterb/pull/131) ([andreccosta](https://github.com/andreccosta))
- Generate changelog for v4.10.0 [\#129](https://github.com/drwl/annotaterb/pull/129) ([drwl](https://github.com/drwl))

## [v4.10.0](https://github.com/drwl/annotaterb/tree/v4.10.0) (2024-06-28)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.9.0...v4.10.0)

**Closed issues:**

- Feature Request: add support for arrays when using StoreModel [\#125](https://github.com/drwl/annotaterb/issues/125)
- Error on composite foreign key constraints [\#121](https://github.com/drwl/annotaterb/issues/121)

**Merged pull requests:**

- Bump version to v4.10.0 [\#128](https://github.com/drwl/annotaterb/pull/128) ([drwl](https://github.com/drwl))
- Support composite foreign keys [\#126](https://github.com/drwl/annotaterb/pull/126) ([drwl](https://github.com/drwl))
- Add files to improve other's ability to help the project [\#123](https://github.com/drwl/annotaterb/pull/123) ([drwl](https://github.com/drwl))
- Add database and adapter to issue template [\#122](https://github.com/drwl/annotaterb/pull/122) ([drwl](https://github.com/drwl))
- Generate changelog for v4.9.0 [\#120](https://github.com/drwl/annotaterb/pull/120) ([drwl](https://github.com/drwl))

## [v4.9.0](https://github.com/drwl/annotaterb/tree/v4.9.0) (2024-05-29)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.8.0...v4.9.0)

**Closed issues:**

- Duplicate content in fixtures when annotating models [\#108](https://github.com/drwl/annotaterb/issues/108)
- Cannot exclude annotations from serializer specs [\#103](https://github.com/drwl/annotaterb/issues/103)

**Merged pull requests:**

- Bump version to v4.9.0 [\#119](https://github.com/drwl/annotaterb/pull/119) ([drwl](https://github.com/drwl))
- Add support for `NOT VALID` constraints [\#118](https://github.com/drwl/annotaterb/pull/118) ([gmcabrita](https://github.com/gmcabrita))
- Generate changelog for v4.8.0 [\#116](https://github.com/drwl/annotaterb/pull/116) ([drwl](https://github.com/drwl))

## [v4.8.0](https://github.com/drwl/annotaterb/tree/v4.8.0) (2024-05-14)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.7.1...v4.8.0)

**Closed issues:**

- Nested module models and unexpected annotations [\#106](https://github.com/drwl/annotaterb/issues/106)

**Merged pull requests:**

- Bump version to v4.8.0 [\#115](https://github.com/drwl/annotaterb/pull/115) ([drwl](https://github.com/drwl))
- Generate changelog for v4.7.1 [\#114](https://github.com/drwl/annotaterb/pull/114) ([drwl](https://github.com/drwl))
- Support annotating model fixture files [\#110](https://github.com/drwl/annotaterb/pull/110) ([drwl](https://github.com/drwl))
- Make `exclude_tests` option able to override other exclude options [\#107](https://github.com/drwl/annotaterb/pull/107) ([drwl](https://github.com/drwl))

## [v4.7.1](https://github.com/drwl/annotaterb/tree/v4.7.1) (2024-05-09)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.7.0...v4.7.1)

**Closed issues:**

- Check constraint support [\#104](https://github.com/drwl/annotaterb/issues/104)

**Merged pull requests:**

- Bump version to v4.7.1 [\#113](https://github.com/drwl/annotaterb/pull/113) ([drwl](https://github.com/drwl))
- Change AnnotationDecider to return false early [\#112](https://github.com/drwl/annotaterb/pull/112) ([drwl](https://github.com/drwl))
- Memoize ActiveRecord migrator version calls [\#111](https://github.com/drwl/annotaterb/pull/111) ([drwl](https://github.com/drwl))
- Fix misspelling in migration guide [\#109](https://github.com/drwl/annotaterb/pull/109) ([RobinDaugherty](https://github.com/RobinDaugherty))
- Annotate model check constraints [\#105](https://github.com/drwl/annotaterb/pull/105) ([drwl](https://github.com/drwl))
- Fix CHANGELOG.md [\#102](https://github.com/drwl/annotaterb/pull/102) ([drwl](https://github.com/drwl))
- Generate changelog for v4.7.0 [\#101](https://github.com/drwl/annotaterb/pull/101) ([drwl](https://github.com/drwl))

## [v4.7.0](https://github.com/drwl/annotaterb/tree/v4.7.0) (2024-03-27)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.6.0...v4.7.0)

**Closed issues:**

- Feature request: better custom type representation [\#97](https://github.com/drwl/annotaterb/issues/97)

**Merged pull requests:**

- Bump version to v4.7.0 [\#100](https://github.com/drwl/annotaterb/pull/100) ([drwl](https://github.com/drwl))
- Add configurable classes list with `to_s` representation [\#98](https://github.com/drwl/annotaterb/pull/98) ([viralpraxis](https://github.com/viralpraxis))
- Generate changelog for v4.6.0 [\#96](https://github.com/drwl/annotaterb/pull/96) ([drwl](https://github.com/drwl))

## [v4.6.0](https://github.com/drwl/annotaterb/tree/v4.6.0) (2024-02-27)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.5.0...v4.6.0)

**Closed issues:**

- Add support for `data_migrate` gem [\#89](https://github.com/drwl/annotaterb/issues/89)

**Merged pull requests:**

- Bump version to v4.6.0 [\#95](https://github.com/drwl/annotaterb/pull/95) ([drwl](https://github.com/drwl))
- Add support for parsing RSpec files [\#94](https://github.com/drwl/annotaterb/pull/94) ([drwl](https://github.com/drwl))
- Add support for model name without namespace in resolver [\#93](https://github.com/drwl/annotaterb/pull/93) ([drwl](https://github.com/drwl))
- Fixes for `RelatedFilesListBuilder` [\#92](https://github.com/drwl/annotaterb/pull/92) ([drwl](https://github.com/drwl))
- Refactor `AnnotatedFile` classes [\#91](https://github.com/drwl/annotaterb/pull/91) ([drwl](https://github.com/drwl))
- Add support for data\_migrate gem [\#90](https://github.com/drwl/annotaterb/pull/90) ([cmer](https://github.com/cmer))
- Support non-model files in `CustomParser` [\#88](https://github.com/drwl/annotaterb/pull/88) ([drwl](https://github.com/drwl))
- Fix flakey integration test [\#87](https://github.com/drwl/annotaterb/pull/87) ([drwl](https://github.com/drwl))
- Improve integration tests [\#86](https://github.com/drwl/annotaterb/pull/86) ([drwl](https://github.com/drwl))
- Add Zeitwerk support [\#85](https://github.com/drwl/annotaterb/pull/85) ([drwl](https://github.com/drwl))
- Improve annotate after adding new migration integration test [\#84](https://github.com/drwl/annotaterb/pull/84) ([drwl](https://github.com/drwl))
- Add integration test using force [\#81](https://github.com/drwl/annotaterb/pull/81) ([drwl](https://github.com/drwl))
- Generate changelog for v4.5.0 [\#80](https://github.com/drwl/annotaterb/pull/80) ([drwl](https://github.com/drwl))
- Fix annotations swallowing comments [\#72](https://github.com/drwl/annotaterb/pull/72) ([drwl](https://github.com/drwl))

## [v4.5.0](https://github.com/drwl/annotaterb/tree/v4.5.0) (2024-02-08)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.4.1...v4.5.0)

**Closed issues:**

- Add an automated way to migrate from the old annotate gem [\#73](https://github.com/drwl/annotaterb/issues/73)
- Default array value is double-quoted/escaped [\#57](https://github.com/drwl/annotaterb/issues/57)

**Merged pull requests:**

- Bump version to v4.5.0 [\#79](https://github.com/drwl/annotaterb/pull/79) ([drwl](https://github.com/drwl))
- Update README on the new Rails generator commands [\#78](https://github.com/drwl/annotaterb/pull/78) ([drwl](https://github.com/drwl))
- Bump github/codeql-action from 2 to 3 [\#77](https://github.com/drwl/annotaterb/pull/77) ([dependabot[bot]](https://github.com/apps/dependabot))
- Add command to generate a configuration file [\#76](https://github.com/drwl/annotaterb/pull/76) ([drwl](https://github.com/drwl))
- Bump actions/checkout from 3 to 4 [\#75](https://github.com/drwl/annotaterb/pull/75) ([dependabot[bot]](https://github.com/apps/dependabot))
- CI: Configure dependabot to update GH Actions [\#74](https://github.com/drwl/annotaterb/pull/74) ([olleolleolle](https://github.com/olleolleolle))
- Refactor `FileBuilder` and `MagicCommentParser` [\#71](https://github.com/drwl/annotaterb/pull/71) ([drwl](https://github.com/drwl))
- Test running annotations after a migration [\#70](https://github.com/drwl/annotaterb/pull/70) ([drwl](https://github.com/drwl))
- Add integration test for rake task installer [\#69](https://github.com/drwl/annotaterb/pull/69) ([drwl](https://github.com/drwl))
- Add integration test for annotating routes [\#68](https://github.com/drwl/annotaterb/pull/68) ([drwl](https://github.com/drwl))
- Remove optional args [\#67](https://github.com/drwl/annotaterb/pull/67) ([drwl](https://github.com/drwl))
- Remove optional arg from `AnnotationPatternGenerator` [\#66](https://github.com/drwl/annotaterb/pull/66) ([drwl](https://github.com/drwl))
- Remove `ARGV` use during runtime [\#65](https://github.com/drwl/annotaterb/pull/65) ([drwl](https://github.com/drwl))
- Add integration test for annotating a singular file [\#64](https://github.com/drwl/annotaterb/pull/64) ([drwl](https://github.com/drwl))
- Generate changelog for v4.4.1 [\#63](https://github.com/drwl/annotaterb/pull/63) ([drwl](https://github.com/drwl))
- Add support for factory\_bot's default suffixed pattern [\#59](https://github.com/drwl/annotaterb/pull/59) ([drwl](https://github.com/drwl))

## [v4.4.1](https://github.com/drwl/annotaterb/tree/v4.4.1) (2023-09-11)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.4.0...v4.4.1)

**Merged pull requests:**

- Bump version to v4.4.1 [\#62](https://github.com/drwl/annotaterb/pull/62) ([drwl](https://github.com/drwl))
- Fix annotation for columns with `Date` and `DateTime` default values [\#61](https://github.com/drwl/annotaterb/pull/61) ([drwl](https://github.com/drwl))
- Add integration tests [\#60](https://github.com/drwl/annotaterb/pull/60) ([drwl](https://github.com/drwl))
- Fix the default array value from being escaped [\#58](https://github.com/drwl/annotaterb/pull/58) ([drwl](https://github.com/drwl))
- Update dummyapp Rails version [\#56](https://github.com/drwl/annotaterb/pull/56) ([drwl](https://github.com/drwl))
- Bump puma from 5.6.5 to 6.3.1 in /dummyapp [\#55](https://github.com/drwl/annotaterb/pull/55) ([dependabot[bot]](https://github.com/apps/dependabot))
- Generate changelog for v4.4.0 [\#53](https://github.com/drwl/annotaterb/pull/53) ([drwl](https://github.com/drwl))
- Add CLI specs using `aruba` gem [\#43](https://github.com/drwl/annotaterb/pull/43) ([drwl](https://github.com/drwl))

## [v4.4.0](https://github.com/drwl/annotaterb/tree/v4.4.0) (2023-06-24)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.3.1...v4.4.0)

**Merged pull requests:**

- Bump version to v4.4.0 [\#52](https://github.com/drwl/annotaterb/pull/52) ([drwl](https://github.com/drwl))
- Flatten tests in `annotation_builder_spec.rb` [\#51](https://github.com/drwl/annotaterb/pull/51) ([drwl](https://github.com/drwl))
- Add support for table comments [\#50](https://github.com/drwl/annotaterb/pull/50) ([drwl](https://github.com/drwl))
- Improve some model annotator tests [\#49](https://github.com/drwl/annotaterb/pull/49) ([drwl](https://github.com/drwl))
- Make tests that use `mock_column` more accurate [\#48](https://github.com/drwl/annotaterb/pull/48) ([drwl](https://github.com/drwl))
- Generate changelog for v4.3.1 [\#47](https://github.com/drwl/annotaterb/pull/47) ([drwl](https://github.com/drwl))

## [v4.3.1](https://github.com/drwl/annotaterb/tree/v4.3.1) (2023-06-15)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.3.0...v4.3.1)

**Closed issues:**

- Column defaults change in migration [\#45](https://github.com/drwl/annotaterb/issues/45)

**Merged pull requests:**

- Bump version to v4.3.1 [\#46](https://github.com/drwl/annotaterb/pull/46) ([drwl](https://github.com/drwl))
- Prettify column defaults [\#44](https://github.com/drwl/annotaterb/pull/44) ([drwl](https://github.com/drwl))
- Generate changelog for v4.3.0 [\#42](https://github.com/drwl/annotaterb/pull/42) ([drwl](https://github.com/drwl))

## [v4.3.0](https://github.com/drwl/annotaterb/tree/v4.3.0) (2023-06-10)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.2.0...v4.3.0)

**Merged pull requests:**

- Bump version to v4.3.0 [\#41](https://github.com/drwl/annotaterb/pull/41) ([drwl](https://github.com/drwl))
- Add `ANNOTATERB_SKIP_ON_DB_TASKS` ENV var to skip auto annotations [\#40](https://github.com/drwl/annotaterb/pull/40) ([drwl](https://github.com/drwl))

## [v4.2.0](https://github.com/drwl/annotaterb/tree/v4.2.0) (2023-06-02)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.1.1...v4.2.0)

**Merged pull requests:**

- Specify `standard` gem version [\#39](https://github.com/drwl/annotaterb/pull/39) ([drwl](https://github.com/drwl))
- Generate changelog for 4.2 again [\#38](https://github.com/drwl/annotaterb/pull/38) ([drwl](https://github.com/drwl))
- Bump version to v4.2.0 [\#37](https://github.com/drwl/annotaterb/pull/37) ([drwl](https://github.com/drwl))
- Generate changelog for 4.2 [\#36](https://github.com/drwl/annotaterb/pull/36) ([drwl](https://github.com/drwl))
- Improve tests for `ColumnAnnotation::*` [\#35](https://github.com/drwl/annotaterb/pull/35) ([drwl](https://github.com/drwl))
- Change instances of `Options.from` =\> `Options.new` in tests [\#34](https://github.com/drwl/annotaterb/pull/34) ([drwl](https://github.com/drwl))
- Add `Standard` linter to project [\#33](https://github.com/drwl/annotaterb/pull/33) ([drwl](https://github.com/drwl))
- Support Sorbet `typed` magic comment [\#32](https://github.com/drwl/annotaterb/pull/32) ([drwl](https://github.com/drwl))
- Add `position_in_additional_file_patterns` to Options and Parser [\#31](https://github.com/drwl/annotaterb/pull/31) ([drwl](https://github.com/drwl))
- Remove `Files` gem as a dependency [\#30](https://github.com/drwl/annotaterb/pull/30) ([drwl](https://github.com/drwl))
- Refactor `ModelAnnotator` again [\#28](https://github.com/drwl/annotaterb/pull/28) ([drwl](https://github.com/drwl))
- Add initial change log [\#27](https://github.com/drwl/annotaterb/pull/27) ([drwl](https://github.com/drwl))

## [v4.1.1](https://github.com/drwl/annotaterb/tree/v4.1.1) (2023-05-20)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.1.0...v4.1.1)

**Merged pull requests:**

- Bump version to v4.1.1 [\#26](https://github.com/drwl/annotaterb/pull/26) ([drwl](https://github.com/drwl))
- Tidy the github repo [\#25](https://github.com/drwl/annotaterb/pull/25) ([drwl](https://github.com/drwl))
- Add guide for migrating from Annotate gem [\#24](https://github.com/drwl/annotaterb/pull/24) ([drwl](https://github.com/drwl))
- Update column pattern regex to incorporate special column comments [\#23](https://github.com/drwl/annotaterb/pull/23) ([drwl](https://github.com/drwl))

## [v4.1.0](https://github.com/drwl/annotaterb/tree/v4.1.0) (2023-05-17)

[Full Changelog](https://github.com/drwl/annotaterb/compare/v4.0.0...v4.1.0)

**Merged pull requests:**

- Bump version to 4.1.0 [\#22](https://github.com/drwl/annotaterb/pull/22) ([drwl](https://github.com/drwl))
- Refactor ModelAnnotator; Fix instances of incorrect `exclude_*` keys [\#21](https://github.com/drwl/annotaterb/pull/21) ([drwl](https://github.com/drwl))
- Fix the default behavior for model annotator [\#20](https://github.com/drwl/annotaterb/pull/20) ([drwl](https://github.com/drwl))
- Refactor model annotator [\#19](https://github.com/drwl/annotaterb/pull/19) ([drwl](https://github.com/drwl))
- Removed unused helper methods and `Env` class [\#18](https://github.com/drwl/annotaterb/pull/18) ([drwl](https://github.com/drwl))
- Update dummy app dependencies [\#17](https://github.com/drwl/annotaterb/pull/17) ([drwl](https://github.com/drwl))

## [v4.0.0](https://github.com/drwl/annotaterb/tree/v4.0.0) (2023-05-03)

[Full Changelog](https://github.com/drwl/annotaterb/compare/1da0386bf9e1ca3fbd0d9d3ae69cdc7a8cdc26fa...v4.0.0)

**Merged pull requests:**

- Last project polish for 4.0.0 release [\#14](https://github.com/drwl/annotaterb/pull/14) ([drwl](https://github.com/drwl))
- Add configuration instructions to README [\#13](https://github.com/drwl/annotaterb/pull/13) ([drwl](https://github.com/drwl))
- Prepare gem for beta release [\#12](https://github.com/drwl/annotaterb/pull/12) ([drwl](https://github.com/drwl))
- Make annotaterb usable [\#11](https://github.com/drwl/annotaterb/pull/11) ([drwl](https://github.com/drwl))
- Move old annotate code into AnnotateRb namespace [\#10](https://github.com/drwl/annotaterb/pull/10) ([drwl](https://github.com/drwl))
- Fix CodeQL action [\#9](https://github.com/drwl/annotaterb/pull/9) ([drwl](https://github.com/drwl))
- Regularly run CI [\#8](https://github.com/drwl/annotaterb/pull/8) ([drwl](https://github.com/drwl))
- Get CI consistently green [\#7](https://github.com/drwl/annotaterb/pull/7) ([drwl](https://github.com/drwl))
- More work [\#6](https://github.com/drwl/annotaterb/pull/6) ([drwl](https://github.com/drwl))
- Make CI green [\#5](https://github.com/drwl/annotaterb/pull/5) ([drwl](https://github.com/drwl))
- Make it work for Rails 7 [\#4](https://github.com/drwl/annotaterb/pull/4) ([drwl](https://github.com/drwl))
- Tidy up project [\#3](https://github.com/drwl/annotaterb/pull/3) ([drwl](https://github.com/drwl))
- Set spec run order to random [\#2](https://github.com/drwl/annotaterb/pull/2) ([drwl](https://github.com/drwl))
- Tidy rspec configuration [\#1](https://github.com/drwl/annotaterb/pull/1) ([drwl](https://github.com/drwl))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
