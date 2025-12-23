Changes are below categorized as follows:
- Breaking Changes
- Features
- Fixes
- Performance
- Misc
- Documentation

Each change should fall into categories that would affect whether the release is major (breaking changes), minor (new behavior), or patch (bug fix). See [semver](http://semver.org/) and [pessimistic versioning](http://guides.rubygems.org/patterns/#pessimistic_version_constraint).

As such, _Breaking Changes_ are major. _Features_ would map to either major or minor. _Fixes_, _Performance_, and _Misc_ are either minor or patch, the difference being kind of fuzzy for the purposes of history. Adding _Documentation_ (including tests) would be patch level.

### [v11.0.0) / 2024-08-23](https://github.com/mbleigh/acts-as-taggable-on/compare/v10.0.0...v11.0.0)
- Removed support for Ruby 2.7
- Removed support for Rails 6.1
- Added support for Ruby 3.2 and 3.3
- Added support for Rails 7.2
- Remove legacy code
- Renamed gem folder from acts_as_taggable_on to acts-as-taggable-on
- Removed legacy autoloading and replaced it with zeitwerk

### [v10.0.0) / 2023-10-15](https://github.com/mbleigh/acts-as-taggable-on/compare/v9.0.1...v10.0.0)
* Features
  * [@glampr Add support for prefix and suffix searches alongside previously supported containment (wildcard) searches](https://github.com/mbleigh/acts-as-taggable-on/pull/1082)
  * [@donquxiote Add support for horizontally sharded databases](https://github.com/mbleigh/acts-as-taggable-on/pull/1079)
  * [aovertus Remove restriction around ActiveRecord 7.x versions allowing support until next major is released](https://github.com/mbleigh/acts-as-taggable-on/pull/1110)

### [v9.0.1) / 2022-01-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v9.0.0..v9.0.1)
* Fixes
  * Fix migration that generate default index

### [v9.0.0) / 2022-01-04](https://github.com/mbleigh/acts-as-taggable-on/compare/v8.1.0...v9.0.0)
* Fixes
  * Support activerecord-7.0.0
  * Support postgis adapter
  * Fix migration syntax
* Features
  * [@moliver-hemasystems Add support for a list of taggable IDs in tagging conditions](https://github.com/mbleigh/acts-as-taggable-on/pull/1053)
* Misc
  * Add docker-compose.yml for local development

### [v8.1.0) / 2021-06-19](https://github.com/mbleigh/acts-as-taggable-on/compare/v8.0.0...v8.1.0)
* Fixes
 * [@ngouy Fix rollbackable tenant migrations](https://github.com/mbleigh/acts-as-taggable-on/pull/1038)
 * [@ngouy Fix gem conflict with already existing tenant model](https://github.com/mbleigh/acts-as-taggable-on/pull/1037)

### [v8.0.0) / 2021-06-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v7.0.0...v8.0.0)
* Features
  * [@lunaru Support tenants for taggings](https://github.com/mbleigh/acts-as-taggable-on/pull/1000)
* Fixes
  * [@gr-eg Use none? instead of count.zero?](https://github.com/mbleigh/acts-as-taggable-on/pull/1030)

### [v7.0.0) / 2020-12-31](https://github.com/mbleigh/acts-as-taggable-on/compare/v6.5.0...v7.0.0)
* Features
  * [@kvokka Rails 6.1 support](https://github.com/mbleigh/acts-as-taggable-on/pull/1013)
* Fixes
  * [@nbulaj Add support for Ruby 2.7 and it's kwargs](https://github.com/mbleigh/acts-as-taggable-on/pull/999)
  * [@Andythurlow @endorfin case sensitivity fix for tagged_with](https://github.com/mbleigh/acts-as-taggable-on/pull/965)

### [6.5.0 / 2019-11-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v6.0.0...v6.5.0)

* Features
  * [@mizukami234 @junmoka Make table names configurable](https://github.com/mbleigh/acts-as-taggable-on/pull/910)
  * [@damianlegawiec Rails 6.0.0.beta1 support](https://github.com/mbleigh/acts-as-taggable-on/pull/937)
* Fixes
  * [@tonyta Avoid overriding user-defined columns cache methods](https://github.com/mbleigh/acts-as-taggable-on/pull/911)
  * [@hengwoon tags_count only need to join on the taggable's table if using STI](https://github.com/mbleigh/acts-as-taggable-on/pull/904)
  * [@bduran82 Avoid unnecessary queries when finding or creating tags](https://github.com/mbleigh/acts-as-taggable-on/pull/839)
  * [@iiwo simplify relation options syntax](https://github.com/mbleigh/acts-as-taggable-on/pull/940)
* Misc
  * [@gssbzn Remove legacy code for an empty query and replace it with ` ActiveRecord::none`](https://github.com/mbleigh/acts-as-taggable-on/pull/906)
  * [@iiwo remove unneeded spec case](https://github.com/mbleigh/acts-as-taggable-on/pull/941)
* Documentation
  * [@tonyta Cleanup CHANGELOG.md formatting and references](https://github.com/mbleigh/acts-as-taggable-on/pull/913)

### [6.0.0 / 2018-06-19](https://github.com/mbleigh/acts-as-taggable-on/compare/v5.0.0...v6.0.0)

* Breaking Changes
  * [@Fodoj Drop support for Rails 4.2](https://github.com/mbleigh/acts-as-taggable-on/pull/887)

* Features
  * [@CalvertYang Add support for uuid primary keys](https://github.com/mbleigh/acts-as-taggable-on/pull/898)
  * [@Fodoj Support Rails 5.2](https://github.com/mbleigh/acts-as-taggable-on/pull/887)

* Fixes
  * [@tekniklr matches_attribute was not being used in tag_match_type](https://github.com/mbleigh/acts-as-taggable-on/issues/869)

### [5.0.0 / 2017-05-18](https://github.com/mbleigh/acts-as-taggable-on/compare/v4.0.0...v5.0.0)

* Breaking Changes
  * [@seuros Drop support for old version of ActiveRecord and Ruby and prepare rel](https://github.com/mbleigh/acts-as-taggable-on/pull/828)

* Features
  * [@rbritom Tagged with rewrite](https://github.com/mbleigh/acts-as-taggable-on/pull/829)
  * [@fearenales Due to database collisions, retry finding or creating a tag](https://github.com/mbleigh/acts-as-taggable-on/pull/809)
  * [@brilyuhns Add owner_tags method to taggable](https://github.com/mbleigh/acts-as-taggable-on/pull/771)
  * [@brilyuhns upport array of contexts in owner_tags_on method](https://github.com/mbleigh/acts-as-taggable-on/pull/771)
  * [@brilyuhns Add specs for owner_tags_on and owner_tags methods](https://github.com/mbleigh/acts-as-taggable-on/pull/771)

* Fixes
  * [@rbritom bump ruby versions for travis](https://github.com/mbleigh/acts-as-taggable-on/pull/825)
  * [@mnrk Fixed Rails 5.1 deprecation message, has_many needs String value for](https://github.com/mbleigh/acts-as-taggable-on/pull/813)
  * [@ProGM ProGM Adding a test to demonstrate the bug](https://github.com/mbleigh/acts-as-taggable-on/pull/806)
  * [@ProGM ProGM Ensure that `caching_tag_list_on?` is injected before using it](https://github.com/mbleigh/acts-as-taggable-on/pull/806)
  * [@ProGM ProGM Fix insert query for postgresql. Move schema definition in schema.rb](https://github.com/mbleigh/acts-as-taggable-on/pull/806)
  * [@amatsuda assigned but unused variable - any](https://github.com/mbleigh/acts-as-taggable-on/pull/787)
  * [@gmcnaughton Fix incorrect call of 'self.class' on methods which are already class](https://github.com/mbleigh/acts-as-taggable-on/pull/782)
  * [@gmcnaughton Fixed #712 (incompatibility with ActiveRecord::Sanitization#quoted_id)](https://github.com/mbleigh/acts-as-taggable-on/pull/782)
  * [@arpitchauhan Guard against indexes already existing](https://github.com/mbleigh/acts-as-taggable-on/pull/779)
  * [@arpitchauhan Rename migration to avoid conflicts](https://github.com/mbleigh/acts-as-taggable-on/pull/774)
  * [@lukeasrodgers "Bugfix `TagList#concat` with non-duplicates."](https://github.com/mbleigh/acts-as-taggable-on/pull/729)
  * [@fabn Revert "Added missed indexes."](https://github.com/mbleigh/acts-as-taggable-on/pull/709)

* Documentation
  * [@logicminds Adds a table of contents to the readme and contributing files](https://github.com/mbleigh/acts-as-taggable-on/pull/803)
  * [@ashishg-qburst Fix typo in README](https://github.com/mbleigh/acts-as-taggable-on/pull/800)
  * [@praveenangyan Update README.md](https://github.com/mbleigh/acts-as-taggable-on/pull/798)
  * [@colemerrick update finding tagged objects in readme](https://github.com/mbleigh/acts-as-taggable-on/pull/794)
  * [@jaredbeck Help people upgrade to 4.0.0](https://github.com/mbleigh/acts-as-taggable-on/pull/784)
  * [@vasinov Update README.md](https://github.com/mbleigh/acts-as-taggable-on/pull/776)

### [4.0.0 / 2016-08-08](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.5.0...v4.0.0)

* Breaking Changes
  * [@krzysiek1507 drop support for Ruby < 2](https://github.com/mbleigh/acts-as-taggable-on/pull/758)
  * [@krzysiek1507 drop support for Rails < 4](https://github.com/mbleigh/acts-as-taggable-on/pull/757)

* Features
  * [@jessieay Rails 5](https://github.com/mbleigh/acts-as-taggable-on/pull/763)

* Fixes
  * [@rikettsie #623 collation parameter is ignored if it generates an exception](https://github.com/mbleigh/acts-as-taggable-on/pull/650)
  * [@bwvoss References working parser in deprecation warning](https://github.com/mbleigh/acts-as-taggable-on/pull/659)
  * [@jh125486 Updated tagging_contexts to include dynamic contexts](https://github.com/mbleigh/acts-as-taggable-on/pull/660)
  * [@jh125486 Fixed wildcard test (postgres returning rows with unexpected order)](https://github.com/mbleigh/acts-as-taggable-on/pull/660)
  * [@FlowerWrong Add rails 5.0.0 alpha support, not hack rails <5](https://github.com/mbleigh/acts-as-taggable-on/pull/673)
  * [@ryanfox1985 Added missed indexes.](https://github.com/mbleigh/acts-as-taggable-on/pull/682)
  * [@zapnap scope tags to specific tagging](https://github.com/mbleigh/acts-as-taggable-on/pull/697)
  * [@amatsuda method redefined](https://github.com/mbleigh/acts-as-taggable-on/pull/715)
  * [@klacointe Rails 5: Tagger is optional in Tagging relation](https://github.com/mbleigh/acts-as-taggable-on/pull/720)
  * [@mark-jacobs Update clean! method to use case insensitive uniq! when strict_case_match false](https://github.com/mbleigh/acts-as-taggable-on/commit/90c86994b70a399b8b1cbc0ae88835e14d6aadfc)
  * [@lukeasrodgers BugFix flackey time test](https://github.com/mbleigh/acts-as-taggable-on/pull/727)
  * [@pcupueran Add rspec tests for context scopes for tagging_spec](https://github.com/mbleigh/acts-as-taggable-on/pull/740)
  * [@emerson-h Remove existing selects from relation](https://github.com/mbleigh/acts-as-taggable-on/pull/743)
  * [@keerthisiv fix issue with custom delimiter](https://github.com/mbleigh/acts-as-taggable-on/pull/748)
  * [@priyank-gupta specify tag table name for mysql collation query](https://github.com/mbleigh/acts-as-taggable-on/pull/760)
  * [@seuros Remove warning messages](https://github.com/mbleigh/acts-as-taggable-on/commit/cda08c764b07a18b8582b948d1c5b3910a376965)
  * [@rbritom Fix migration, #references already adds index](https://github.com/mbleigh/acts-as-taggable-on/commit/95f743010954b6b738a6e8c17315112c878f7a81)
  * [@rbritom Fix deprecation warning](https://github.com/mbleigh/acts-as-taggable-on/commit/62e4a6fa74ae3faed615683cd3ad5b5cdacf5c96)
  * [@rbritom fix scope array arguments](https://github.com/mbleigh/acts-as-taggable-on/commit/a415a8d6367b2e91bd7e363589135f953929b8cc)
  * [@seuros Remove more deprecations](https://github.com/mbleigh/acts-as-taggable-on/commit/05794170f64f8bf250b34d2d594e368721009278)
  * [@lukeasrodgers Bugfix `TagList#concat` with non-duplicates.](https://github.com/mbleigh/acts-as-taggable-on/commit/2c6214f0ddf8c6440ab81eec04d1fbf9d97c8826)
  * [@seuros clean! should return self.](https://github.com/mbleigh/acts-as-taggable-on/commit/c739422f56f8ff37e3f321235e74997422a1c980)
  * [@rbritom re-enable appraisals](https://github.com/mbleigh/acts-as-taggable-on/commit/0ca1f1c5b059699c683a28b522e86a3d5cd7639e)
  * [@rbritom remove index conditionally on up method.](https://github.com/mbleigh/acts-as-taggable-on/commit/9cc580e7f88164634eb10c8826e5b30ea0e00544)
  * [@rbritom add index on down method . ](https://github.com/mbleigh/acts-as-taggable-on/pull/767)
  * [@rbritom remove index conditionally on up method](https://github.com/mbleigh/acts-as-taggable-on/commit/9cc580e7f88164634eb10c8826e5b30ea0e00544)

* Documentation
  * [@logicminds Adds table of contents using doctoc utility](https://github.com/mbleigh/acts-as-taggable-on/pull/803)
  * [@jamesprior Changing ActsAsTaggable to ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on/pull/637)
  * [@markgandolfo Update README.md](https://github.com/mbleigh/acts-as-taggable-on/pull/645))
  * [@snowblink Update release date for 3.5.0](https://github.com/mbleigh/acts-as-taggable-on/pull/647)
  * [@AlexVPopov Update README.md](https://github.com/mbleigh/acts-as-taggable-on/pull/671)
  * [@schnmudgal README.md, Improve documentation for Tag Ownership](https://github.com/mbleigh/acts-as-taggable-on/pull/706)

### [3.5.0 / 2015-03-03](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.4...v3.5.0)

* Fixes
  * [@rikettsie Fixed collation for MySql via rake rule or config parameter](https://github.com/mbleigh/acts-as-taggable-on/pull/634)

* Misc
  * [@pcupueran Add rspec test for tagging_spec completeness]()

### [3.4.4 / 2015-02-11](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.3...v3.4.4)

* Fixes
  * [@d4rky-pl Add context constraint to find_related_* methods](https://github.com/mbleigh/acts-as-taggable-on/pull/629)

### [3.4.3 / 2014-09-26](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.2...v3.4.3)

* Fixes
  * [@warp clears column cache on reset_column_information resolves](https://github.com/mbleigh/acts-as-taggable-on/issues/621)

### [3.4.2 / 2014-09-26](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.1...v3.4.2)

* Fixes
  * [@stiff fixed tagged_with :any in postgresql](https://github.com/mbleigh/acts-as-taggable-on/pull/570)
  * [@jerefrer fixed encoding in mysql](https://github.com/mbleigh/acts-as-taggable-on/pull/588)
  * [@markedmondson Ensure taggings context aliases are maintained when joining multiple taggables](https://github.com/mbleigh/acts-as-taggable-on/pull/589)

### [3.4.1 / 2014-09-01](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.0...v3.4.1)

* Fixes
  * [@konukhov fix owned ordered taggable bug](https://github.com/mbleigh/acts-as-taggable-on/pull/585)

### [3.4.0 / 2014-08-29](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.3.0...v3.4.0)

* Features
  * [@ProGM Support for custom parsers for tags](https://github.com/mbleigh/acts-as-taggable-on/pull/579)
  * [@lolaodelola #577 Popular feature](https://github.com/mbleigh/acts-as-taggable-on/pull/577)

* Fixes
  * [@twalpole Update for rails edge (4.2)](https://github.com/mbleigh/acts-as-taggable-on/pull/583)

* Performance
  * [@ashanbrown #584 Use pluck instead of select](https://github.com/mbleigh/acts-as-taggable-on/pull/584)

### [3.3.0 / 2014-07-08](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.6...v3.3.0)

* Features
  * [@felipeclopes #488 Support for `start_at` and `end_at` restrictions when selecting tags](https://github.com/mbleigh/acts-as-taggable-on/pull/488)

* Fixes
  * [@tonytonyjan #560 Fix for `ActsAsTaggableOn.remove_unused_tags` doesn't work](https://github.com/mbleigh/acts-as-taggable-on/pull/560)
  * [@TheLarkInn #555 Fix for `tag_cloud` helper to generate correct css tags](https://github.com/mbleigh/acts-as-taggable-on/pull/555)

* Performance
  * [@pcai #556 Add back taggables index in the taggins table](https://github.com/mbleigh/acts-as-taggable-on/pull/556)

### [3.2.6 / 2014-05-28](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.5...v3.2.6)

* Fixes
  * [@seuros #548 Fix dirty marking when tags are not ordered](https://github.com/mbleigh/acts-as-taggable-on/issues/548)

* Misc
  * [@seuros Remove actionpack dependency](https://github.com/mbleigh/acts-as-taggable-on/commit/5d20e0486c892fbe21af42fdcd79d0b6ebe87ed4)
  * [@seuros #547 Add tests for update_attributes](https://github.com/mbleigh/acts-as-taggable-on/issues/547)

### [3.2.5 / 2014-05-25](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.4...v3.2.5)

* Fixes
  * [@seuros #546 Fix autoload bug. Now require engine file instead of autoloading it](https://github.com/mbleigh/acts-as-taggable-on/issues/546)

### [3.2.4 / 2014-05-24](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.3...v3.2.4)

* Fixes
  * [@seuros #544 Fix incorrect query generation related to `GROUP BY` SQL statement](https://github.com/mbleigh/acts-as-taggable-on/issues/544)

* Misc
  * [@seuros #545 Remove `ammeter` development dependency](https://github.com/mbleigh/acts-as-taggable-on/pull/545)
  * [@seuros #545 Deprecate `TagList.from` in favor of `TagListParser.parse`](https://github.com/mbleigh/acts-as-taggable-on/pull/545)
  * [@seuros #543 Introduce lazy loading](https://github.com/mbleigh/acts-as-taggable-on/pull/543)
  * [@seuros #541 Deprecate ActsAsTaggableOn::Utils](https://github.com/mbleigh/acts-as-taggable-on/pull/541)

### [3.2.3 / 2014-05-16](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.2...v3.2.3)

* Fixes
  * [@seuros #540 Fix for tags removal (it was affecting all records with the same tag)](https://github.com/mbleigh/acts-as-taggable-on/pull/540)
  * [@akicho8 #535 Fix for `options` Hash passed to methods from being deleted by those methods](https://github.com/mbleigh/acts-as-taggable-on/pull/535)

### [3.2.2 / 2014-05-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.1...v3.2.2)

* Breaking Changes
  * [@seuros #526 Taggable models are not extended with ActsAsTaggableOn::Utils anymore](https://github.com/mbleigh/acts-as-taggable-on/pull/526)

* Fixes
  * [@seuros #536 Add explicit conversion of tags to strings (when assigning tags)](https://github.com/mbleigh/acts-as-taggable-on/pull/536)

* Misc
  * [@seuros #526 Delete outdated benchmark script](https://github.com/mbleigh/acts-as-taggable-on/pull/526)
  * [@seuros #525 Fix tests so that they pass with MySQL](https://github.com/mbleigh/acts-as-taggable-on/pull/525)

### [3.2.1 / 2014-05-06](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.0...v3.2.1)

* Misc
  * [@seuros #523 Run tests loading only ActiveRecord (without the full Rails stack)](https://github.com/mbleigh/acts-as-taggable-on/pull/523)
  * [@seuros #523 Remove activesupport dependency](https://github.com/mbleigh/acts-as-taggable-on/pull/523)
  * [@seuros #523 Introduce database_cleaner in specs](https://github.com/mbleigh/acts-as-taggable-on/pull/523)
  * [@seuros #520 Tag_list cleanup](https://github.com/mbleigh/acts-as-taggable-on/pull/520)

### [3.2.0 / 2014-05-01](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.1.1...v3.2.0)

* Breaking Changes
  * ActsAsTaggableOn::Tag is not extend with ActsAsTaggableOn::Utils anymore

* Features
  * [@ches #413 Hook to support STI subclasses of Tag in save_tags](https://github.com/mbleigh/acts-as-taggable-on/pull/413)

* Fixes
  * [@jdelStrother #515 Rename Compatibility methods to reduce chance of conflicts](https://github.com/mbleigh/acts-as-taggable-on/pull/515)
  * [@seuros #512 fix for << method](https://github.com/mbleigh/acts-as-taggable-on/pull/512)
  * [@sonots #510 fix IN subquery error for mysql](https://github.com/mbleigh/acts-as-taggable-on/pull/510)
  * [@jonseaberg #499 fix for race condition when multiple processes try to add the same tag](https://github.com/mbleigh/acts-as-taggable-on/pull/499)
  * [@leklund #496 Fix for distinct and postgresql json columns errors](https://github.com/mbleigh/acts-as-taggable-on/pull/496)
  * [@thatbettina & @plexus #394 Multiple quoted tags](https://github.com/mbleigh/acts-as-taggable-on/pull/394)

* Performance

* Misc
  * [@seuros #511 Rspec 3](https://github.com/mbleigh/acts-as-taggable-on/pull/511)

### [3.1.0 / 2014-03-31](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.1...v3.1.0)

* Fixes
  * [@mikehale #487 Match_all respects context](https://github.com/mbleigh/acts-as-taggable-on/pull/487)

* Performance
  * [@dgilperez #390 Add taggings counter cache](https://github.com/mbleigh/acts-as-taggable-on/pull/390)

* Misc
  * [@jonseaberg Add missing indexes to schema used in specs #474](https://github.com/mbleigh/acts-as-taggable-on/pull/474)
  * [@seuros Specify Ruby >= 1.9.3 required in gemspec](https://github.com/mbleigh/acts-as-taggable-on/pull/502)
  * [@kiasaki Add missing quotes to code example](https://github.com/mbleigh/acts-as-taggable-on/pull/501)

### [3.1.0.rc1 / 2014-02-26](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.1...v3.1.0.rc1)

* Features
  * [@Burkazoid #467 Add :order_by_matching_tag_count option](https://github.com/mbleigh/acts-as-taggable-on/pull/469)

* Fixes
  * [@rafael #406 Dirty attributes not correctly derived](https://github.com/mbleigh/acts-as-taggable-on/pull/406)
  * [@BenZhang #440 Did not respect strict_case_match](https://github.com/mbleigh/acts-as-taggable-on/pull/440)
  * [@znz #456 Fix breaking encoding of tag](https://github.com/mbleigh/acts-as-taggable-on/pull/456)
  * [@rgould #417 Let '.count' work when tagged_with is accompanied by a group clause](https://github.com/mbleigh/acts-as-taggable-on/pull/417)
  * [@developer88 #461 Move 'Distinct' out of select string and use .uniq instead](https://github.com/mbleigh/acts-as-taggable-on/pull/461)
  * [@gerard-leijdekkers #473 Fixed down migration index name](https://github.com/mbleigh/acts-as-taggable-on/pull/473)
  * [@leo-souza #498 Use database's lower function for case-insensitive match](https://github.com/mbleigh/acts-as-taggable-on/pull/498)

* Misc
  * [@billychan #463 Thread safe support](https://github.com/mbleigh/acts-as-taggable-on/pull/463)
  * [@billychan #386 Add parse:true instructions to README](https://github.com/mbleigh/acts-as-taggable-on/pull/386)
  * [@seuros #449 Improve README/UPGRADING/post install docs](https://github.com/mbleigh/acts-as-taggable-on/pull/449)
  * [@seuros #452 Remove I18n deprecation warning in specs](https://github.com/mbleigh/acts-as-taggable-on/pull/452)
  * [@seuros #453 Test against Ruby 2.1 on Travis CI](https://github.com/mbleigh/acts-as-taggable-on/pull/453)
  * [@takashi #454 Clarify example in docs](https://github.com/mbleigh/acts-as-taggable-on/pull/454)

### [3.0.1 / 2014-01-08](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.0...v3.0.1)

* Fixes
  * [@rafael #406 Dirty attributes not correctly derived](https://github.com/mbleigh/acts-as-taggable-on/pull/406)
  * [@BenZhang #440 Did not respect strict_case_match](https://github.com/mbleigh/acts-as-taggable-on/pull/440)
  * [@znz #456 Fix breaking encoding of tag](https://github.com/mbleigh/acts-as-taggable-on/pull/456)

* Misc
  * [@billychan #386 Add parse:true instructions to README](https://github.com/mbleigh/acts-as-taggable-on/pull/386)
  * [@seuros #449 Improve README/UPGRADING/post install docs](https://github.com/mbleigh/acts-as-taggable-on/pull/449)
  * [@seuros #452 Remove I18n deprecation warning in specs](https://github.com/mbleigh/acts-as-taggable-on/pull/452)
  * [@seuros #453 Test against Ruby 2.1 on Travis CI](https://github.com/mbleigh/acts-as-taggable-on/pull/453)
  * [@takashi #454 Clarify example in docs](https://github.com/mbleigh/acts-as-taggable-on/pull/454)

### [3.0.0 / 2014-01-01](https://github.com/mbleigh/acts-as-taggable-on/compare/v2.4.1...v3.0.0)

* Breaking Changes
  * No longer supports Ruby 1.8.

* Features
  * Supports Rails 4.1.

* Misc (TODO: expand)
  * [@zquestz #359](https://github.com/mbleigh/acts-as-taggable-on/pull/359)
  * [@rsl #367](https://github.com/mbleigh/acts-as-taggable-on/pull/367)
  * [@ktdreyer #383](https://github.com/mbleigh/acts-as-taggable-on/pull/383)
  * [@cwoodcox #346](https://github.com/mbleigh/acts-as-taggable-on/pull/346)
  * [@mrb #421](https://github.com/mbleigh/acts-as-taggable-on/pull/421)
  * [@bf4 #430](https://github.com/mbleigh/acts-as-taggable-on/pull/430)
  * [@sanemat #368](https://github.com/mbleigh/acts-as-taggable-on/pull/368)
  * [@bf4 #343](https://github.com/mbleigh/acts-as-taggable-on/pull/343)
  * [@marclennox #429](https://github.com/mbleigh/acts-as-taggable-on/pull/429)
  * [@shekibobo #403](https://github.com/mbleigh/acts-as-taggable-on/pull/403)
  * [@ches @ktdreyer #410](https://github.com/mbleigh/acts-as-taggable-on/pull/410)
  * [@makaroni4 #371](https://github.com/mbleigh/acts-as-taggable-on/pull/371)
  * [kenzai @davidstosik @awt #431](https://github.com/mbleigh/acts-as-taggable-on/pull/431)
  * [@bf4 @joelcogen @shekibobo @aaronchi #438](https://github.com/mbleigh/acts-as-taggable-on/pull/438)
  * [@seuros #442](https://github.com/mbleigh/acts-as-taggable-on/pull/442)
  * [@bf4 #445](https://github.com/mbleigh/acts-as-taggable-on/pull/445)
  * [@eagletmt #446](https://github.com/mbleigh/acts-as-taggable-on/pull/446)

### 3.0.0.rc2 [changes](https://github.com/mbleigh/acts-as-taggable-on/compare/fork-v3.0.0.rc1...fork-v3.0.0.rc2)

### 3.0.0.rc1 [changes](https://github.com/mbleigh/acts-as-taggable-on/compare/v2.4.1...fork-v3.0.0.rc1)

### [2.4.1 / 2013-05-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v2.4.0...v2.4.1)

* Features

* Fixes

* Misc
