# Changelog

## [v3.2.0](https://github.com/faker-ruby/faker/tree/v3.2.0) (2023-04-14)

Happy Spring with a new Faker release! 🌼

This version changes `Faker::Internet.email`, `Faker::Internet.domain_name`, `Faker::Internet.safe_email`, and `Faker::Internet.free_email` default behavior.

These generators email are now RFC 2606 compliant. They generate safe values by default using the Reserved Top Level DNS Names: `example` and `test`. To maintain backwards compatibility and give users the option to use non-safe domains at their own risk, custom domains are allowed.

`Faker::Internet.safe_email`, and `Faker::Internet.free_email` have been deprecated. Users have until October 2023 to make the necessary changes.

[More details and updated docs can be found here](https://github.com/faker-ruby/faker/blob/main/doc/default/internet.md#about-faker-ruby-transition-to-be-rfc-2606-compliant).

Other changes included in this version:

## Features
* Generate safe `email` and `domain_name` by default (RFC 2606) by @stefannibrasil in https://github.com/faker-ruby/faker/pull/2733
* Add avatar movie by @lexisvar in https://github.com/faker-ruby/faker/pull/2699
* add chess sport by @lexisvar in https://github.com/faker-ruby/faker/pull/2701
* Remove FillMurray service by @ferblape in https://github.com/faker-ruby/faker/pull/2702
* Add Allergens to Food by @AaronRustad in https://github.com/faker-ruby/faker/pull/2706
* Update sport docs by @clementf in https://github.com/faker-ruby/faker/pull/2716
* Add country code +44 to en-gb locale by @jremes-foss in https://github.com/faker-ruby/faker/pull/2731
* Add names to DnD generator by @dollerbill in https://github.com/faker-ruby/faker/pull/2735
* add digits to password by @wyattroyc in https://github.com/faker-ruby/faker/pull/2705
* performance: remove unnecessary i18n locale reload by @codez in https://github.com/faker-ruby/faker/pull/2723
* Add Faker::Company.department generator by @acuppy in https://github.com/faker-ruby/faker/pull/2737
* Mitch Hedberg quotes by @MosDeef in https://github.com/faker-ruby/faker/pull/2721

## Bug fixes
* Fix explanation what Marketing.buzzwords does by @danieldiekmeier in https://github.com/faker-ruby/faker/pull/2700
* fix: Typo in Faker::Travel::Airport docs by @evanlouden in https://github.com/faker-ruby/faker/pull/2712
* Fix full changelog link for 3.1.1 by @rnestler in https://github.com/faker-ruby/faker/pull/2714
* Stop publishing to RubyGem by @VladVadlja in https://github.com/faker-ruby/faker/pull/2711
* Add default_country_code in locale by @ashwin-elangovan in https://github.com/faker-ruby/faker/pull/2732
* Fix formatting in readme.md by @leon-vogt in https://github.com/faker-ruby/faker/pull/2722

## Update local dependencies
* Fix rubocop updates by @stefannibrasil in https://github.com/faker-ruby/faker/pull/2708
* Update rubocop-minitest requirement from = 0.29.0 to = 0.30.0 by @dependabot in https://github.com/faker-ruby/faker/pull/2743
* Update minitest requirement from = 5.17.0 to = 5.18.0 by @dependabot in https://github.com/faker-ruby/faker/pull/2727
* Update rubocop requirement from = 1.48.1 to = 1.50.1 by @dependabot in https://github.com/faker-ruby/faker/pull/2747
* Add Faker::Company.department generator by @acuppy in https://github.com/faker-ruby/faker/pull/2737
* Update Pull Request template and guides by @stefannibrasil in https://github.com/faker-ruby/faker/pull/2749

## New Contributors
* @lexisvar made their first contribution in https://github.com/faker-ruby/faker/pull/2699
* @danieldiekmeier made their first contribution in https://github.com/faker-ruby/faker/pull/2700
* @AaronRustad made their first contribution in https://github.com/faker-ruby/faker/pull/2706
* @evanlouden made their first contribution in https://github.com/faker-ruby/faker/pull/2712
* @rnestler made their first contribution in https://github.com/faker-ruby/faker/pull/2714
* @VladVadlja made their first contribution in https://github.com/faker-ruby/faker/pull/2711
* @clementf made their first contribution in https://github.com/faker-ruby/faker/pull/2716
* @leon-vogt made their first contribution in https://github.com/faker-ruby/faker/pull/2722
* @ashwin-elangovan made their first contribution in https://github.com/faker-ruby/faker/pull/2732
* @wyattroyc made their first contribution in https://github.com/faker-ruby/faker/pull/2705
* @codez made their first contribution in https://github.com/faker-ruby/faker/pull/2723
* @acuppy made their first contribution in https://github.com/faker-ruby/faker/pull/2737
* @MosDeef made their first contribution in https://github.com/faker-ruby/faker/pull/2721

**Full Changelog**: https://github.com/faker-ruby/faker/compare/v3.1.1...v3.2.0

------------------------------------------------------------------------------

## [v3.1.1](https://github.com/faker-ruby/faker/tree/v3.1.1) (2023-02-03)

Happy Valentine's Day with a new Faker release! 🎉

This version:

- adds and deprecates generators
- fixes bugs
- updates development dependencies

### Features
* Add exclude_words keyword to Lorem Ipsum to prevent words from being produced by @philipfong in #2665
* Deprecate FillMurray service by @ferblape in #2657
* Airports by @ZionMiller in https://github.com/faker-ruby/faker/pull/2682

### Bug fixes
* Fix simple typo in es.yml by @hslzr in https://github.com/faker-ruby/faker/pull/2675
* Test the Vehicle VIN validator with known good and bad values, fixes … by @alextaujenis in https://github.com/faker-ruby/faker/pull/2640
* Fix you're/your typo and inaccuracy in Star Wars quote by @dwilsonactual in https://github.com/faker-ruby/faker/pull/2693
* Revert "Typo in Ukrainian locale, fixes #2620" by @thdaraujo in https://github.com/faker-ruby/faker/pull/2690

### Update local dependencies
* Adds Ruby 3.2 to the CI matrix. Updates checkout action version. by @petergoldstein in https://github.com/faker-ruby/faker/pull/2673
* Update rubocop-minitest requirement from = 0.25.0 to = 0.25.1 by @dependabot in https://github.com/faker-ruby/faker/pull/2674
* Update minitest requirement from = 5.16.3 to = 5.17.0 by @dependabot in https://github.com/faker-ruby/faker/pull/2677
* Update pry requirement from = 0.14.1 to = 0.14.2 by @dependabot in https://github.com/faker-ruby/faker/pull/2680
* Update simplecov requirement from = 0.21.2 to = 0.22.0 by @dependabot in https://github.com/faker-ruby/faker/pull/2672
* Update rubocop requirement from = 1.44.0 to = 1.44.1 by @dependabot in https://github.com/faker-ruby/faker/pull/2691

### New Contributors
* @hslzr made their first contribution in https://github.com/faker-ruby/faker/pull/2675
* @ferblape made their first contribution in https://github.com/faker-ruby/faker/pull/2657
* @petergoldstein made their first contribution in https://github.com/faker-ruby/faker/pull/2673
* @dwilsonactual made their first contribution in https://github.com/faker-ruby/faker/pull/2693

**Full Changelog**: https://github.com/faker-ruby/faker/compare/v3.1.0...v3.1.1

------------------------------------------------------------------------------

## [v3.1.0](https://github.com/faker-ruby/faker/tree/v3.1.0) (2022-12-23)

Happy Holidays with a new Faker release! 🎉

This version:

- adds and removes generators
- fixes bugs
- updates dependencies

### Features
* Simple Japanesemedia::CowboyBebop module by @Ivan-P23994 in https://github.com/faker-ruby/faker/pull/2617
* added travel folder and airports by @ZionMiller in https://github.com/faker-ruby/faker/pull/2601
* Spongebob TV show collections by @kleinjm in https://github.com/faker-ruby/faker/pull/2619
* Add pre-push hook example by @akanshak984 in https://github.com/faker-ruby/faker/pull/2606

### Bug fixes
* fix: ensure generated passwords have correct characters when mix_case & special_characters enabled by @tiff-o in https://github.com/faker-ruby/faker/pull/2533
* Fix: ensure sport generator produces single sport unless a number of sports is requested by @si-lens in https://github.com/faker-ruby/faker/pull/2616
* Remove typo in ISSUE_TEMPLATE to check Faker version by @loqimean in https://github.com/faker-ruby/faker/pull/2621
* Typo in Ukrainian locale, fixes #2620 by @Newman101 in https://github.com/faker-ruby/faker/pull/2622
* Remove english characters in ja locale file, fixes faker-ruby#2637 by @alextaujenis in https://github.com/faker-ruby/faker/pull/2638
* Fix country code length for non EN locale by @vbrazo in https://github.com/faker-ruby/faker/pull/2669

### What's Changed
* Removed LoremPixel Files by @uzorjchibuzor in https://github.com/faker-ruby/faker/pull/2664
* Document IBAN digits validity generator by @stefannibrasil in https://github.com/faker-ruby/faker/pull/2625
* Create random vehicle vin numbers with the correct check-digit by @alextaujenis in https://github.com/faker-ruby/faker/pull/2633
* Fix formatting in internet/http.md documentation by @Newman101 in https://github.com/faker-ruby/faker/pull/2647
* Remove deprecated ru paul documentation by @italopires in https://github.com/faker-ruby/faker/pull/2651
* Add Ruby as specified language in code block by @luciagirasoles in https://github.com/faker-ruby/faker/pull/2654
* Fix some typos by @jdufresne in https://github.com/faker-ruby/faker/pull/2662
* Remove unnecessary executable bit from several files by @jdufresne in https://github.com/faker-ruby/faker/pull/2645
* Remove broken readme links by @vbrazo in https://github.com/faker-ruby/faker/pull/2668
* Update minecraft.rb by @lepinejf in https://github.com/faker-ruby/faker/pull/2635
* Update README and CONTRIBUTING guides by @stefannibrasil in https://github.com/faker-ruby/faker/pull/2630
* Update dependabot ignore list by @stefannibrasil in https://github.com/faker-ruby/faker/pull/2629

### Update local dependencies
* Update simplecov requirement from = 0.21.0 to = 0.21.2 by @dependabot in https://github.com/faker-ruby/faker/pull/2636
* Update timecop requirement from = 0.9.5 to = 0.9.6 by @dependabot in https://github.com/faker-ruby/faker/pull/2642
* Update rubocop-minitest requirement from = 0.23.2 to = 0.25.0 by @dependabot in https://github.com/faker-ruby/faker/pull/2653
* Update test-unit requirement from = 3.5.6 to = 3.5.7 by @dependabot in https://github.com/faker-ruby/faker/pull/2659
* Update rubocop requirement from = 1.41.0 to = 1.41.1 by @dependabot in https://github.com/faker-ruby/faker/pull/2667

### New Contributors
* @si-lens made their first contribution in https://github.com/faker-ruby/faker/pull/2616
* @Ivan-P23994 made their first contribution in https://github.com/faker-ruby/faker/pull/2617
* @ZionMiller made their first contribution in https://github.com/faker-ruby/faker/pull/2601
* @loqimean made their first contribution in https://github.com/faker-ruby/faker/pull/2621
* @kleinjm made their first contribution in https://github.com/faker-ruby/faker/pull/2619
* @akanshak984 made their first contribution in https://github.com/faker-ruby/faker/pull/2606
* @lepinejf made their first contribution in https://github.com/faker-ruby/faker/pull/2635
* @italopires made their first contribution in https://github.com/faker-ruby/faker/pull/2651
* @luciagirasoles made their first contribution in https://github.com/faker-ruby/faker/pull/2654

**Full Changelog**: https://github.com/faker-ruby/faker/compare/v3.0.0...v3.1.0

------------------------------------------------------------------------------

## [v3.0.0](https://github.com/faker-ruby/faker/tree/v3.0.0) (2022-11-01)

### Breaking Changes
- [PR #2576](https://github.com/faker-ruby/faker/pull/2576) Drop support for positional arguments in favor of keyword arguments. Support for positional arguments was deprecated on v2 [@mauromorales](https://github.com/mauromorales)

### Bug/Fixes
- [PR #2562](https://github.com/faker-ruby/faker/pull/2562) Fix Faker::Vehicle.vin [@rmm5t](https://github.com/rmm5t)
- [PR #2567](https://github.com/faker-ruby/faker/pull/2567) Fix typo abreviation -> abbreviation [@alextaujenis](https://github.com/alextaujenis)
- [PR #2594](https://github.com/faker-ruby/faker/pull/2594) Fix some typos [@jdufresne](https://github.com/jdufresne)
- [PR #2596](https://github.com/faker-ruby/faker/pull/2596) Removes NBSP from locales files [@hbontempo-br](https://github.com/hbontempo-br)

### Features
- [PR #2561](https://github.com/faker-ruby/faker/pull/2561) Add country code for `en-CA` phone numbers [@wjessop](https://github.com/wjessop)
- [PR #2566](https://github.com/faker-ruby/faker/pull/2566) Add color luminosity options [@fbuys](https://github.com/fbuys)
- [PR #2570](https://github.com/faker-ruby/faker/pull/2570) Add French Translation of Ancient [@Beygs](https://github.com/Beygs)
- [PR #2582](https://github.com/faker-ruby/faker/pull/2582) Add `clojure` as a language option to `Faker::Source` generator [@professorjrod](https://github.com/professorjrod)
- [PR #2585](https://github.com/faker-ruby/faker/pull/2585) Add movie Hackers  [@ericdain](https://github.com/ericdain)
- [PR #2589](https://github.com/faker-ruby/faker/pull/2589) Add Game Escape From Tarkov [@professorjrod](https://github.com/professorjrod)
- [PR #2592](https://github.com/faker-ruby/faker/pull/2592) Add quotes to "no"-key  [@Frubrecht](https://github.com/Frubrecht)

### What's Changed
- [PR #2549](https://github.com/faker-ruby/faker/pull/2549) Set true to `rubygems_mfa_required` gemspec metadata [@koic](https://github.com/koic)
- [PR #2557](https://github.com/faker-ruby/faker/pull/2557) Use rubocop-rake to lint Rake tasks [@dmarcoux](https://github.com/dmarcoux)
- [PR #2551](https://github.com/faker-ruby/faker/pull/2551) Security: set explicit and strict token-permissions on GitHub workflows [@sashashura](https://github.com/sashashura)
- [PR #2558](https://github.com/faker-ruby/faker/pull/2558) Remove unneeded require]() lib/faker.rb [@dmarcoux](https://github.com/dmarcoux)
- [PR #2568](https://github.com/faker-ruby/faker/pull/2568) Remove outdated comment from development dependencies [@stefannibrasil](https://github.com/stefannibrasil)
- [PR #2569](https://github.com/faker-ruby/faker/pull/2569) Improve Phone Number Locale documentation [@calvinballing](https://github.com/calvinballing)
- [PR #2579](https://github.com/faker-ruby/faker/pull/2579) Add note about Random behavior on MiniTest [@stefannibrasil](https://github.com/stefannibrasil)
- [PR #2580](https://github.com/faker-ruby/faker/pull/2580) Remove mentions to `master` and use `main` [@stefannibrasil](https://github.com/stefannibrasil)
- [PR #2586](https://github.com/faker-ruby/faker/pull/2586) Change McCree to Cassidy on Overwatch generator [@ericdain](https://github.com/ericdain)
- [PR #2584](https://github.com/faker-ruby/faker/pull/2584) Automate workflow to publish to RubyGems. [@bijoysijo](https://github.com/bijoysijo)
- [PR #2598](https://github.com/faker-ruby/faker/pull/2598) Remove tags from publish.yml [@vbrazo](https://github.com/vbrazo)
- [PR #2604](https://github.com/faker-ruby/faker/pull/2604) Update fi-FI state listing from year 1721 to 2022 [@Newman101](https://github.com/Newman101)
- [PR #2602](https://github.com/faker-ruby/faker/pull/2602) Fix publish action for release types [@thdaraujo](https://github.com/thdaraujo)
- [PR #2591](https://github.com/faker-ruby/faker/pull/2591) Fixes iban checksum calculation [@srcoley](https://github.com/srcoley)
- [PR #2599](https://github.com/faker-ruby/faker/pull/2599) Fix documentation for tarkov game [@kaushikhande](https://github.com/kaushikhande)
- [PR #2600](https://github.com/faker-ruby/faker/pull/2600) Add sports documentation and update sports [@matt17r](https://github.com/matt17r)
- [PR #2590](https://github.com/faker-ruby/faker/pull/2590) Deprecate LoremPixel [@uzorjchibuzor](https://github.com/uzorjchibuzor)

### Update local dependencies
- Update rubocop minitest to `0.23.0`
- Update simplecov to `0.21.0`
- Update test-unit to `3.5.5`
- Update rubocop to `1.37.1`

**Full Changelog**: https://github.com/faker-ruby/faker/compare/v2.23.0...v3.0.0

------------------------------------------------------------------------------

## [v2.23.0](https://github.com/faker-ruby/faker/tree/v2.23.0) (2022-09-01)

### Bug/Fixes
- [PR #2517](https://github.com/faker-ruby/faker/pull/) Fix Japanese plural [@akmhmgc](https://github.com/akmhmgc) 
- [PR #2308](https://github.com/faker-ruby/faker/pull/) Internet::Password - Improve mix_case and special_characters support [@meuble](https://github.com/meuble) 
- [PR #2520](https://github.com/faker-ruby/faker/pull/) Add thread safety [@kiskoza](https://github.com/kiskoza) 
- [PR #2543](https://github.com/faker-ruby/faker/pull/) Fix computer test [@trinaldi](https://github.com/trinaldi) 
- [PR #2552](https://github.com/faker-ruby/faker/pull/) Fix `fma_brotherhood` usage example [@y0n0zawa](https://github.com/y0n0zawa) 

### Features
- [PR #2367](https://github.com/faker-ruby/faker/pull/) Add generator for vulnerability identifiers [@NobodysNightmare](https://github.com/NobodysNightmare) 
- [PR #2397](https://github.com/faker-ruby/faker/pull/) Add sports to `Faker::Sport` [@matt17r](https://github.com/matt17r) 
- [PR #2511](https://github.com/faker-ruby/faker/pull/) Add Danish id number [@jokklan](https://github.com/jokklan) 
- [PR #2518](https://github.com/faker-ruby/faker/pull/) Add the ability to generate a mime type of a specific media type [@ric2b](https://github.com/ric2b) 
- [PR #2455](https://github.com/faker-ruby/faker/pull/) Add IDNumber.french_insee_number [@Spone](https://github.com/Spone) 
- [PR #2491](https://github.com/faker-ruby/faker/pull/) fix italy VAT and add italy condominium fiscal code generator [@FiloSpaTeam](https://github.com/FiloSpaTeam) 
- [PR #2460](https://github.com/faker-ruby/faker/pull/) Add ChileRut.full_formatted_rut [@KarlHeitmann](https://github.com/KarlHeitmann) 
- [PR #2540](https://github.com/faker-ruby/faker/pull/) Add vehicle version generator [@trinaldi](https://github.com/trinaldi) 

### What's Changed
- [PR #2530](https://github.com/faker-ruby/faker/pull/) Fix flaky user agent test [@thdaraujo](https://github.com/thdaraujo) 
- [PR #2531](https://github.com/faker-ruby/faker/pull/) Update GitHub Issues and Pull Request Templates [ci-skip] [@stefannibrasil](https://github.com/stefannibrasil) 
- [PR #2535](https://github.com/faker-ruby/faker/pull/) Fix warning instance variable uninitialized [@akmhmgc](https://github.com/akmhmgc) 
- [PR #2536](https://github.com/faker-ruby/faker/pull/) Updated versions and added more operating systems [@abrahamparayil](https://github.com/abrahamparayil) 
- [PR #2538](https://github.com/faker-ruby/faker/pull/) Drop support for EOL Ruby versions (`2.5` and `2.6`) [@nickmendezFlatiron](https://github.com/nickmendezFlatiron) 

### Update local dependencies
- Update minitest to `5.16.3`
- Update rubocop to `1.35.1`

------------------------------------------------------------------------------

## [v2.22.0](https://github.com/faker-ruby/faker/tree/v2.22.0) (2022-07-28)

## Bug/Fixes

- [PR #2500](https://github.com/faker-ruby/faker/pull/2500) Fix: Duplicate array before concatenating [@mattr](https://github.com/mattr)
- [PR #2488](https://github.com/faker-ruby/faker/pull/2488) Fixed random selection issue [@sudeeptarlekar](https://github.com/sudeeptarlekar)
- [PR #2475](https://github.com/faker-ruby/faker/pull/2475) Update regex used for Faker::Vehicle#vin [@erayalkis](https://github.com/erayalkis)

## Chores

- [PR #2513](https://github.com/faker-ruby/faker/pull/2513) Remove broken docs [@vbrazo](https://github.com/vbrazo)
- [PR #2502](https://github.com/faker-ruby/faker/pull/2502) Update actions/checkout version in GitHub actions [@jdufresne](https://github.com/jdufresne)
- [PR #2501](https://github.com/faker-ruby/faker/pull/2501) Make ReadMe more consise [@jenniferdewan](https://github.com/jenniferdewan)
- [PR #2489](https://github.com/faker-ruby/faker/pull/2489) Change a filename to follow naming conventions [@yasuhiron777](https://github.com/yasuhiron777)

## Feature Request

- [PR #2477](https://github.com/faker-ruby/faker/pull/2477) feat: add bot_user_agent method for generate web crawle's user agents [@a-chacon](https://github.com/a-chacon)
- [PR #2465](https://github.com/faker-ruby/faker/pull/2465) Add a new sports section for mountaineers [@LeviLong01](https://github.com/LeviLong01)

## Update locales

- [PR #2509](https://github.com/faker-ruby/faker/pull/2509) Add all Dota 2 heroes [@JCFarrow](https://github.com/JCFarrow)
- [PR #2507](https://github.com/faker-ruby/faker/pull/2507) Update dog.yml [@Kedaruma-Bond](https://github.com/Kedaruma-Bond)
- [PR #2503](https://github.com/faker-ruby/faker/pull/2503) Update pl.yml [@marek-witkowski](https://github.com/marek-witkowski)
- [PR #2499](https://github.com/faker-ruby/faker/pull/2499) Fix: Use pattern to define Australian cell phone formats [@mattr](https://github.com/mattr)
- [PR #2497](https://github.com/faker-ruby/faker/pull/2497) Fix typos in Australia [@mattr](https://github.com/mattr)
- [PR #2490](https://github.com/faker-ruby/faker/pull/2490) Added Japanese adjective translations [@yasuhiron777](https://github.com/yasuhiron777)

------------------------------------------------------------------------------

## [v2.21.0](https://github.com/faker-ruby/faker/tree/v2.21.0) (2022-05-12)

## Bug/Fixes

- [PR #2443](https://github.com/faker-ruby/faker/pull/2443) Fixed error for random in markdown [@sudeeptarlekar](https://github.com/sudeeptarlekar)

## Feature Request

- [PR #2252](https://github.com/faker-ruby/faker/pull/2252) Add Faker::Movies::Tron [@craineum](https://github.com/craineum)

## Update locales
- [PR #2485](https://github.com/faker-ruby/faker/pull/2485) Add japanese translations for emotion [@kenboo0426](https://github.com/kenboo0426)
- [PR #2479](https://github.com/faker-ruby/faker/pull/2479) Add japanese translations for naruto [@johnmanjiro13](https://github.com/johnmanjiro13)
- [PR #2478](https://github.com/faker-ruby/faker/pull/2478) Add Japanese translation for relationships [@shouichi](https://github.com/shouichi)
- [PR #2469](https://github.com/faker-ruby/faker/pull/2467) Fix blank row in game.yml [@KingYoSun](https://github.com/KingYoSun)
- [PR #2467](https://github.com/faker-ruby/faker/pull/2467) French traduction of adjectives [@Beygs](https://github.com/Beygs)

## Update local dependencies

- Update rubocop to `1.26.0`
- Update timecop to `0.95.0`

------------------------------------------------------------------------------

## [v2.20.0](https://github.com/faker-ruby/faker/tree/v2.20.0) (2022-03-05)

## Documentation

- [PR #2421](https://github.com/faker-ruby/faker/pull/2421) Add general documentation for Faker::Camera [@aleksandrilyin](https://github.com/aleksandrilyin)


## Feature Request

- [PR #2457](https://github.com/faker-ruby/faker/pull/2457) add Command & Conquer games [@Awilum](https://github.com/Awilum)
- [PR #2456](https://github.com/faker-ruby/faker/pull/2456) fix heading for faker hobby doc [@Awilum](https://github.com/Awilum)
- [PR #2411](https://github.com/faker-ruby/faker/pull/2411) Add mock data for Auth0 OAuth [@Norio4](https://github.com/Norio4)
- [PR #2396](https://github.com/faker-ruby/faker/pull/2396) Add Brooklyn Nine Nine into tv shows category [@fralps](https://github.com/fralps)
- [PR #2395](https://github.com/faker-ruby/faker/pull/2395) Add The Kingkiller Chronicle [@fblupi](https://github.com/fblupi)
- [PR #2392](https://github.com/faker-ruby/faker/pull/2392) Update LV locale - cell phone numbers should be 8 symbols [@tmikoss](https://github.com/tmikoss)
- [PR #2383](https://github.com/faker-ruby/faker/pull/2383) Add Faker::JapaneseMedia::KamenRider#transformation_device [@boardfish](https://github.com/boardfish)
- [PR #2382](https://github.com/faker-ruby/faker/pull/2382) Add collectible devices [@boardfish](https://github.com/boardfish)
- [PR #2378](https://github.com/faker-ruby/faker/pull/2378) Re-add the Faker::Internet.base64 method [@ashishra0](https://github.com/ashishra0)
- [PR #2374](https://github.com/faker-ruby/faker/pull/2374) Add Faker::JapaneseMedia::KamenRider [@boardfish](https://github.com/boardfish)
- [PR #1656](https://github.com/faker-ruby/faker/pull/1656) Add bible entries [@enowbi](https://github.com/enowbi)

## Update locales

- [PR #2462](https://github.com/faker-ruby/faker/pull/2462) Add Sora and Hollow Bastion to SuperSmashBros yml files [@gazayas](https://github.com/gazayas)
- [PR #2458](https://github.com/faker-ruby/faker/pull/2458) Fix typo on Tom Jobim's name [@andrerferrer](https://github.com/andrerferrer)
- [PR #2452](https://github.com/faker-ruby/faker/pull/2452) updated Timor-Leste in en/addresses.yml [@masukomi](https://github.com/masukomi)
- [PR #2450](https://github.com/faker-ruby/faker/pull/2450) dividing male and female Arabic names [@Alfulayt](https://github.com/Alfulayt)
- [PR #2381](https://github.com/faker-ruby/faker/pull/2381) Remove duplicates and clean up Faker::JapaneseMedia::KamenRider [@boardfish](https://github.com/boardfish)
- [PR #2405](https://github.com/faker-ruby/faker/pull/2405) Add countries in Japanese [@lawriecate](https://github.com/lawriecate)
- [PR #2403](https://github.com/faker-ruby/faker/pull/2403) add Faker::Animal in pt-BR [@thiago-henrique-leite](https://github.com/thiago-henrique-leite)
- [PR #2377](https://github.com/faker-ruby/faker/pull/2377) Fix non striped coffe blender [@ngouy](https://github.com/ngouy)

## Update local dependencies

- Update rubocop to `1.25.0`
- Update rake to `13.0.6`
- Update test-unit to `3.5.3`
- Update yard to `0.9.27`

------------------------------------------------------------------------------

## [v2.19.0](https://github.com/faker-ruby/faker/tree/v2.19.0) (2021-08-22)

## Bug/Fixes

- [PR #2356](https://github.com/faker-ruby/faker/pull/2356) fix broken link for placeholdit [@lilisako](https://github.com/lilisako)
- [PR #2351](https://github.com/faker-ruby/faker/pull/2351) Fix spanish organisation number [@laulujan](https://github.com/laulujan)

## Feature Request

- [PR #2371](https://github.com/faker-ruby/faker/pull/2371) Add supernatural TV show [@vin1cius](https://github.com/vin1cius)
- [PR #2369](https://github.com/faker-ruby/faker/pull/2369) Added more Science examples - science branches, modifiers and tools [@itay-grudev](https://github.com/itay-grudev)
- [PR #2361](https://github.com/faker-ruby/faker/pull/2361) Add ethnic category to the food generator [@wolwire](https://github.com/wolwire)
- [PR #2359](https://github.com/faker-ruby/faker/pull/2359) add stock_market to finance Faker::Finance [@lilisako](https://github.com/lilisako)
- [PR #2341](https://github.com/faker-ruby/faker/pull/2341) add Hobby to default [@rohanphillips](https://github.com/rohanphillips)
- [PR #2324](https://github.com/faker-ruby/faker/pull/2324) Add Faker::Emotion.word [@jayqui](https://github.com/jayqui)
- [PR #2320](https://github.com/faker-ruby/faker/pull/2320) Add Faker::TvShows::TheOffice [@sandylcruz](https://github.com/sandylcruz)
- [PR #2245](https://github.com/faker-ruby/faker/pull/2245) Add Faker::Australia class [@astley92](https://github.com/astley92)
- [PR #1731](https://github.com/faker-ruby/faker/pull/1731) add brand, vendor support to commerce [@ashishra0](https://github.com/ashishra0)

## Update locales

- [PR #2343](https://github.com/faker-ruby/faker/pull/2343) Minor typo fixes to Community quotes [@sunny](https://github.com/sunny)
- [PR #2340](https://github.com/faker-ruby/faker/pull/2340) Add JapaneseMedia StudioGhibli for locals/ja.yml [@ryogift](https://github.com/ryogift)
- [PR #2339](https://github.com/faker-ruby/faker/pull/2339) Various locale specific and other fixes for faker [@psibi](https://github.com/psibi)
- [PR #2338](https://github.com/faker-ruby/faker/pull/2338) Add Kazuya to Faker::Games::SuperSmashBros [@boardfish](https://github.com/boardfish)
- [PR #2333](https://github.com/faker-ruby/faker/pull/2333) add FR translation for animals [@cprodhomme](https://github.com/cprodhomme)
- [PR #2329](https://github.com/faker-ruby/faker/pull/2329) Fix Faker::Color.color_name for Japanese [@yujideveloper](https://github.com/yujideveloper)
- [PR #2327](https://github.com/faker-ruby/faker/pull/2327) Remove trailing spaces from translations [@michebble](https://github.com/michebble)
- [PR #2326](https://github.com/faker-ruby/faker/pull/2326) Faker::Address.postcode (locale=ja) should contains hyphen [@gongo](https://github.com/gongo)

## Update local dependencies

- Update rubocop requirement from = 1.18.3 to = 1.18.4 (#2362)
- Update rake requirement from = 13.0.3 to = 13.0.6 (#2357)
- Update rubocop requirement from = 1.18.1 to = 1.18.3 (#2353)
- Update rubocop requirement from = 1.17.0 to = 1.18.1 (#2346)
- Update rubocop requirement from = 1.16.0 to = 1.17.0 (#2337)
- Update test-unit requirement from = 3.4.2 to = 3.4.4 (#2334)
- Update rubocop requirement from = 1.15.0 to = 1.16.0 (#2332)
- Update test-unit requirement from = 3.4.1 to = 3.4.2 (#2331)
- Update rubocop requirement from = 1.14.0 to = 1.15.0 (#2325)

------------------------------------------------------------------------------

## [v2.18.0](https://github.com/faker-ruby/faker/tree/v2.18.0) (2021-05-15)

## Bug/Fixes

- [PR #2300](https://github.com/faker-ruby/faker/pull/2300) Fix space.company by adding missing quote [@koic](https://github.com/koic)
- [PR #2044](https://github.com/faker-ruby/faker/pull/2044) Workaround for cc-test-reporter with SimpleCov 0.18 [@koic](https://github.com/koic)

## Chores

- [PR #2316](https://github.com/faker-ruby/faker/pull/2316) Fix typo in test method [@yujideveloper](https://github.com/yujideveloper)

## Documentation

- [PR #2290](https://github.com/faker-ruby/faker/pull/2290) Fix typo [@d-holbach](https://github.com/d-holbach)
- [PR #2282](https://github.com/faker-ruby/faker/pull/2282) fixed small typo [@koic](https://github.com/koic)

## Feature Request

- [PR #2301](https://github.com/faker-ruby/faker/pull/2301) Add Faker::IDNumber.croatian_id method [@lovro-bikic](https://github.com/lovro-bikic)
- [PR #2299](https://github.com/faker-ruby/faker/pull/2299) Add birds [@brotherjack](https://github.com/brotherjack)
- [PR #2295](https://github.com/faker-ruby/faker/pull/2295) Add more methods to the Witcher class [@marcelobarreto](https://github.com/marcelobarreto)
- [PR #2289](https://github.com/faker-ruby/faker/pull/2289) Increase french entropy [@meuble](https://github.com/meuble)
- [PR #2287](https://github.com/faker-ruby/faker/pull/2287) Add Crypto.sha512 [@crondaemon](https://github.com/crondaemon)
- [PR #2190](https://github.com/faker-ruby/faker/pull/2190) Add Faker::Tea [@snood1205](https://github.com/snood1205)
- [PR #2175](https://github.com/faker-ruby/faker/pull/2175) Add two generators to Faker::Science [@RubyHuntsman](https://github.com/RubyHuntsman)
- [PR #1910](https://github.com/faker-ruby/faker/pull/1910) Add Faker::Music#mambo_no_5, a Generator for Random First Names that Appear in Lou Bega's Mambo No. 5 [@NickyEXE](https://github.com/NickyEXE)

## Update locales

- [PR #2321](https://github.com/faker-ruby/faker/pull/2321) Canadian area code 226 included in array of US area codes [@jgarber623](https://github.com/jgarber623)
- [PR #2317](https://github.com/faker-ruby/faker/pull/2317) Fix ci for es-AR [@yujideveloper](https://github.com/yujideveloper)
- [PR #2315](https://github.com/faker-ruby/faker/pull/2315) Split JA translation file into one file per class [@yujideveloper](https://github.com/yujideveloper)
- [PR #2313](https://github.com/faker-ruby/faker/pull/2313) Add Japanese translation for Faker::Subscription [@yujideveloper](https://github.com/yujideveloper)
- [PR #2311](https://github.com/faker-ruby/faker/pull/2311) add yoda quotes to russian locale [@aka-nez](https://github.com/aka-nez)
- [PR #2297](https://github.com/faker-ruby/faker/pull/2297) add Japanese actual zipcodes in locals/ja.yml [@POPPIN-FUMI](https://github.com/POPPIN-FUMI)
- [PR #2291](https://github.com/faker-ruby/faker/pull/2291) Add Commerce for Japanese [@ima1zumi](https://github.com/ima1zumi)
- [PR #2285](https://github.com/faker-ruby/faker/pull/2285) Fix update Brazilian phone country code [@ricardopacheco](https://github.com/ricardopacheco)
- [PR #2154](https://github.com/faker-ruby/faker/pull/2154) Cleanup books. Add Fantasy::Tolkien to README. [@mathisto](https://github.com/mathisto)

## Update local dependencies

- Update rubocop requirement from = 1.13.0 to = 1.14.0 (#2314)
- Upgrade to GitHub-native Dependabot (#2310)
- Update rubocop requirement from = 1.12.1 to = 1.13.0 (#2305)
- Update test-unit requirement from = 3.4.0 to = 3.4.1 (#2303)
- Update pry requirement from = 0.14.0 to = 0.14.1 (#2298)
- Update rubocop requirement from = 1.12.0 to = 1.12.1 (#2294)
- Update rubocop requirement from = 1.11.0 to = 1.12.0 (#2288)

## [v2.17.0](https://github.com/faker-ruby/faker/tree/v2.17.0) (2021-03-10)

## Chores

- [PR #2272](https://github.com/faker-ruby/faker/pull/2272) Bump RuboCop to 1.10.0 [@koic](https://github.com/koic)
- [PR #2270](https://github.com/faker-ruby/faker/pull/2270) Generate different values when generating a hash [@DaniTheLion](https://github.com/DaniTheLion)
- [PR #2236](https://github.com/faker-ruby/faker/pull/2236) Move Digest classes to OpenSSL [@dbussink](https://github.com/dbussink)

## Documentation

- [PR #2277](https://github.com/faker-ruby/faker/pull/2277) add Hip Hop To Path [@Josiassejod1](https://github.com/Josiassejod1)
- [PR #2276](https://github.com/faker-ruby/faker/pull/2276) Fix syntax highlighting and missing version [@ghiculescu](https://github.com/ghiculescu)
- [PR #2255](https://github.com/faker-ruby/faker/pull/2255) Correct capitalization of RuboCop in text [@jdufresne](https://github.com/jdufresne)
- [PR #2204](https://github.com/faker-ruby/faker/pull/2204) update documentation to include Float type [@BigBigDoudou](https://github.com/BigBigDoudou)

## Feature Request

- [PR #2256](https://github.com/faker-ruby/faker/pull/2256) Add Faker::Educator.primary_school [@jdufresne](https://github.com/jdufresne)
- [PR #2248](https://github.com/faker-ruby/faker/pull/2248) Add Bank.iban_country_code [@mastermatt](https://github.com/mastermatt)
- [PR #2166](https://github.com/faker-ruby/faker/pull/2166) add binary number faker [@gabrielbaldao](https://github.com/gabrielbaldao)

## Update locales

- [PR #2275](https://github.com/faker-ruby/faker/pull/2275) Add Japanese for Faker::Games::Orverwatch [@may-solty](https://github.com/may-solty)
- [PR #2268](https://github.com/faker-ruby/faker/pull/2268) Add Japanese for Faker::Games::SuperMario [@k-maekawa](https://github.com/k-maekawa)
- [PR #2258](https://github.com/faker-ruby/faker/pull/2258) Add es-AR locale [@fcolacilli](https://github.com/fcolacilli)
- [PR #2215](https://github.com/faker-ruby/faker/pull/2215) Unify model names to not contain manufacturer name [@berkos](https://github.com/berkos)

------------------------------------------------------------------------------

## [v2.16.0](https://github.com/faker-ruby/faker/tree/v2.16.0) (2021-02-09)

## Chores

- [PR #2262](https://github.com/faker-ruby/faker/pull/2262) Workaround build error for ruby-head [@koic](https://github.com/koic)
- [PR #2257](https://github.com/faker-ruby/faker/pull/2257) Trim trailing white space throughout the project [@koic](https://github.com/koic)
- [PR #2229](https://github.com/faker-ruby/faker/pull/2229) Use Random.new instead of `Random::DEFAULT` [@connorshea](https://github.com/connorshea)
- [PR #2226](https://github.com/faker-ruby/faker/pull/2226) Add Ruby 3.0 to CI matrix [@connorshea](https://github.com/connorshea)

## Documentation

- [PR #2247](https://github.com/faker-ruby/faker/pull/2247) 2243 yard doc [@sudeeptarlekar](https://github.com/sudeeptarlekar)
- [PR #2240](https://github.com/faker-ruby/faker/pull/2240) Updated `rock_band.md` to include example for using song generator [@jsca-kwok](https://github.com/jsca-kwok)
- [PR #2205](https://github.com/faker-ruby/faker/pull/2205) `Faker::Mountain` doc [@bipashant](https://github.com/bipashant)

## Feature Request

- [PR #2221](https://github.com/faker-ruby/faker/pull/2221) Added rock band song generator [@jsca-kwok](https://github.com/jsca-kwok)
- [PR #2208](https://github.com/faker-ruby/faker/pull/2208) Feat/add blockchain Tezos keys [@akettal](https://github.com/akettal) [@Pierre-Michard](https://github.com/Pierre-Michard)
- [PR #2197](https://github.com/faker-ruby/faker/pull/2197) Add `Faker::Games::Touhou` [@dysnomian](https://github.com/dysnomian)

## Update locales

- [PR #2238](https://github.com/faker-ruby/faker/pull/2238) added some data in `fr.yml` and `football.yml` [@MathGL92](https://github.com/MathGL92)
- [PR #2222](https://github.com/faker-ruby/faker/pull/2222) Add Japanese for `Faker::Book` [@zoshigayan](https://github.com/zoshigayan)
- [PR #2217](https://github.com/faker-ruby/faker/pull/2217) Add Sephiroth and Northern Cave to `Faker::Games::SuperSmashBros` [@boardfish](https://github.com/boardfish)
- [PR #2201](https://github.com/faker-ruby/faker/pull/2201) Typo in Lebowski Quote [@rgraff](https://github.com/rgraff)
- [PR #2197](https://github.com/faker-ruby/faker/pull/2197) Add `Faker::Games::Touhou` [@dysnomian](https://github.com/dysnomian)

------------------------------------------------------------------------------

## [v2.15.1](https://github.com/faker-ruby/faker/tree/v2.15.1) (2020-11-24)

- Rollback PR #2169 and bump 2.15.1 [#2203](https://github.com/faker-ruby/faker/pull/2203) @vbrazo

------------------------------------------------------------------------------

## [v2.15.0](https://github.com/faker-ruby/faker/tree/v2.15.0) (2020-11-24)

## Bug/Fixes

- RuboCop 1.0 fixes [#2182](https://github.com/faker-ruby/faker/pull/2182) @amatsuda
- Get rid of broken I18n locales configuration for the tests [#2168](https://github.com/faker-ruby/faker/pull/2168) @amatsuda
- Fixes a bug when generating a password with min_length eq 1 [#2138](https://github.com/faker-ruby/faker/pull/2138) @adrian-rivera @Zeragamba
- Improve Faker::Company.spanish_organisation_number [#2106](https://github.com/faker-ruby/faker/pull/2106)

## Chores

- Reformat demographic yaml [#2189](https://github.com/faker-ruby/faker/pull/2189) @fiteclub
- An attempt to load only necessary locales on the fly [#2169](https://github.com/faker-ruby/faker/pull/2169) @amatsuda
- Faker::Config can be a Module rather than a Class [#2167](https://github.com/faker-ruby/faker/pull/2167) @amatsuda
- Cleanup games [#2155](https://github.com/faker-ruby/faker/pull/2155) @mathisto
- Deprecate `celebrity` methods in favor of `actor` [#2133](https://github.com/faker-ruby/faker/pull/2133) @vraravam

## Documentation

- Fix class name in volleyball.md [#2198](https://github.com/faker-ruby/faker/pull/2198) @connorshea
- Fix typo in doc/games/heroes.md [#2145](https://github.com/faker-ruby/faker/pull/2145) @Crysicia
- fix typo [#2141](https://github.com/faker-ruby/faker/pull/2141) @Zeragamba
- Updated versions in doc for methods. [#2123](https://github.com/faker-ruby/faker/pull/2123) @sudeeptarlekar

## Feature Request

- Add `Faker::Mountain` [#2196](https://github.com/faker-ruby/faker/pull/2196) @bipashant
- Add Faker::Volleyball [#2178](https://github.com/faker-ruby/faker/pull/2178) @RubyHuntsman
- Add artifact generator to Faker::Game::Heroes [#2177](https://github.com/faker-ruby/faker/pull/2177) @droznyk
- Add generator to Faker::Games:ElderScrolls [#2171](https://github.com/faker-ruby/faker/pull/2171) @RubyHuntsman
- Augment opera [#2170](https://github.com/faker-ruby/faker/pull/2170) @Gaitorius
- Add generator to Faker::Games::ElderScrolls [#2164](https://github.com/faker-ruby/faker/pull/2164) @RubyHuntsman
- Add more generators to Faker::Minecraft [#2162](https://github.com/faker-ruby/faker/pull/2162) @RubyHuntsman
- I added more programming languages to the source [#2161](https://github.com/faker-ruby/faker/pull/2161) @JoaoHenriqueVale
- Add Faker:Camera [#2159](https://github.com/faker-ruby/faker/pull/2159) @RubyHuntsman
- Add how to train your dragon [#2158](https://github.com/faker-ruby/faker/pull/2158) @archbloom
- Add Faker::Fantasy::Tolkien [#2152](https://github.com/faker-ruby/faker/pull/2152) @mathisto
- Feature: Add north dakota driving licence [#2149](https://github.com/faker-ruby/faker/pull/2149) @martinjaimem
- Add Final Space to TvShows category [#2147](https://github.com/faker-ruby/faker/pull/2147)
- Add finance/stock generators [#2146](https://github.com/faker-ruby/faker/pull/2146) @johnpitchko
- Add Clash Of Clans to the Game category [#2143](https://github.com/faker-ruby/faker/pull/2143) @jamesmai0512
- Add Conan to the JapaneseMedia category [#2142](https://github.com/faker-ruby/faker/pull/2142) @jamesmai0512
- Add Naruto to the JapaneseMedia category [#2139](https://github.com/faker-ruby/faker/pull/2139) @jamesmai0512
- Add Doraemon to the JapaneseMedia category [#2137](https://github.com/faker-ruby/faker/pull/2137) @jamesmai0512
- Add space force and coast guard to military [#2136](https://github.com/faker-ruby/faker/pull/2136) @mathisto
- Add Super Mario [#2135](https://github.com/faker-ruby/faker/pull/2135) @fblupi
- Add The Room (2003) to Movies [#2134](https://github.com/faker-ruby/faker/pull/2134) @fiteclub
- Faker adjectives [#2130](https://github.com/faker-ruby/faker/pull/2130) @loicboset
- Add Studio Ghibli to the JapaneseMedia category [#2124](https://github.com/faker-ruby/faker/pull/2124) @Kadaaran
- Created New Method Faker::Quote.fortune_cookie [#2112](https://github.com/faker-ruby/faker/pull/2112) @catonmat
- Allow disabling the usage of open compounds in sentences [#2109](https://github.com/faker-ruby/faker/pull/2109) @tjozwik
- Add faker for hiphop artist [#1923](https://github.com/faker-ruby/faker/pull/1923) @Josiassejod1
- Add races and class names to WorldOfWarcraft [#1787](https://github.com/faker-ruby/faker/pull/1787) @mathisto
- Add planets and races to DragonBall [#1786](https://github.com/faker-ruby/faker/pull/1786) @mathisto
- Add planets, cities, and quotes to Dune [#1784](https://github.com/faker-ruby/faker/pull/1784) @mathisto

## Update locales

- add japanese gender first name [#2191](https://github.com/faker-ruby/faker/pull/2191) @issei126
- Add full_address to Ukrainian locale [#2176](https://github.com/faker-ruby/faker/pull/2176) @Ptico
- Fixed some spelling issues in company.yml [#2173](https://github.com/faker-ruby/faker/pull/2173) @coreymaher
- Update Faker::Games::SuperSmashBros [#2164](https://github.com/faker-ruby/faker/pull/2164) @boardfish
- Add more quotes to Faker::Games::Witcher [#2163](https://github.com/faker-ruby/faker/pull/2163) @RubyHuntsman
- Add Jack Handey's Deep Thoughts to quotes [#2150](https://github.com/faker-ruby/faker/pull/2150) @fiteclub
- add brazil license plate from mercosul rules [#2144](https://github.com/faker-ruby/faker/pull/2144) @gabrielbaldao
- Add additional quotes to Studio Ghibli [#2132](https://github.com/faker-ruby/faker/pull/2132) @lambda2
- Change 'Nyota Uhuru' to 'Nyota Uhura' [#2121](https://github.com/faker-ruby/faker/pull/2121) @TrevorA-TrevorA
- Add spanish license plates [#2103](https://github.com/faker-ruby/faker/pull/2103)

## Update local dependencies

- Update RuboCop requirement from = 1.0.0 to = 1.1.0 [#2185](https://github.com/faker-ruby/faker/pull/2185)
- Update RuboCop requirement from = 0.93.1 to = 1.0.0 [#2172](https://github.com/faker-ruby/faker/pull/2172)
- Update RuboCop requirement from = 0.93.0 to = 0.93.1 [#2156](https://github.com/faker-ruby/faker/pull/2156)
- Update RuboCop requirement from = 0.92.0 to = 0.93.0 [#2151](https://github.com/faker-ruby/faker/pull/2151)
- Update RuboCop requirement from = 0.91.1 to = 0.92.0 [#2129](https://github.com/faker-ruby/faker/pull/2129)
- Update RuboCop requirement from = 0.91.0 to = 0.91.1 [#2126](https://github.com/faker-ruby/faker/pull/2126)
- Update RuboCop requirement from = 0.90.0 to = 0.91.0 [#2122](https://github.com/faker-ruby/faker/pull/2122)
- Update test-unit requirement from = 3.3.6 to = 3.3.7 [#2195](https://github.com/faker-ruby/faker/pull/2195)
- Update timecop requirement from = 0.9.1 to = 0.9.2 [#2160](https://github.com/faker-ruby/faker/pull/2160)

------------------------------------------------------------------------------

## [v2.14.0](https://github.com/faker-ruby/faker/tree/v2.14.0) (2020-09-15)

## Bug/Fixes

- [PR #2119](https://github.com/faker-ruby/faker/pull/2119) Fixed failing spec for phone number

## Chores

- [PR #2088](https://github.com/faker-ruby/faker/pull/2088) Remove the space in the word "turtle" in the Creature::Animals faker
- [PR #2081](https://github.com/faker-ruby/faker/pull/2081) Remove redundant condition branch for Ruby 2.4
- [PR #2077](https://github.com/faker-ruby/faker/pull/2077) Rename tests according to the `test*.rb` pattern so that they run

## Documentation

- [PR #2095](https://github.com/faker-ruby/faker/pull/2095) Fix a typo for `Games::DnD.species`
- [PR #2094](https://github.com/faker-ruby/faker/pull/2094) Correct method name from race to species in DnD doc
- [PR #2079](https://github.com/faker-ruby/faker/pull/2079) Add `Music::PearlJam` to Readme
- [PR #2058](https://github.com/faker-ruby/faker/pull/2058) Add YARD doc for `Faker::Code`

## Feature Request

- [PR #2117](https://github.com/faker-ruby/faker/pull/2117) Add Truffleruby head to CI
- [PR #2104](https://github.com/faker-ruby/faker/pull/2104) 2097 Added barcodes
- [PR #2090](https://github.com/faker-ruby/faker/pull/2090) 1693 USA driving license
- [PR #2098](https://github.com/faker-ruby/faker/pull/2098) Update DnD generator
- [PR #2096](https://github.com/faker-ruby/faker/pull/2096) 2091 faker drones
- [PR #2092](https://github.com/faker-ruby/faker/pull/2092) Add a street fighter generator
- [PR #2082](https://github.com/faker-ruby/faker/pull/2082) Enable `Lint/UnifiedInteger` cop

## Update locales

- [PR #2100](https://github.com/faker-ruby/faker/pull/2100) Remove Gaylord
- [PR #2087](https://github.com/faker-ruby/faker/pull/2087) Fix/remove country code from phone numbers
- [PR #2086](https://github.com/faker-ruby/faker/pull/2086) removing country code from phone numbers to `fr-CH`
- [PR #2084](https://github.com/faker-ruby/faker/pull/2084) removed extra + sign from country codes
- [PR #2078](https://github.com/faker-ruby/faker/pull/2078) Removed 07624 from UK mobile numbers
- [PR #2073](https://github.com/faker-ruby/faker/pull/2073) Add missing azimuth field for fr locale
- [PR #2072](https://github.com/faker-ruby/faker/pull/2072) Remove time formats from file

Update local dependencies

- Update RuboCop requirement from = 0.87.1 to = 0.88.0 (#2080)
- Update RuboCop requirement from = 0.87.0 to = 0.87.1 (#2075)
- Update RuboCop requirement from = 0.86.0 to = 0.87.0 (#2074)
- Bumps i18n from 1.8.4 to 1.8.5 (#2089)
- Bumps i18n from 1.8.3 to 1.8.4 (#2083)

------------------------------------------------------------------------------

## [v2.13.0](https://github.com/faker-ruby/faker/tree/v2.13.0) (2020-06-24)

This version:
- adds YARD docs for several interface methods
- fixes bugs
- adds improvements to the code base
- updates dependencies

## Bug/Fixes

- [PR #2050](https://github.com/faker-ruby/faker/pull/2050) Fix random error in music tests [@martinjaimem](https://github.com/martinjaimem)
- [PR #2037](https://github.com/faker-ruby/faker/pull/2037) Bug Fix: BIC Collision (Issue 1907) [@Newman101](https://github.com/Newman101)
- [PR #2026](https://github.com/faker-ruby/faker/pull/2026) Sanitize email when name has special characters [@Zeragamba](https://github.com/Zeragamba)
- [PR #1785](https://github.com/faker-ruby/faker/pull/1785) Adds a fix for when :en is not one of the available locales [@jaimerodas](https://github.com/jaimerodas)

## Chores

- [PR #2041](https://github.com/faker-ruby/faker/pull/2041) Reduce Lines in char.rb [@Newman101](https://github.com/Newman101)
- [PR #2039](https://github.com/faker-ruby/faker/pull/2039) restore Kylo Ren quotes [@Zeragamba](https://github.com/Zeragamba)
- [PR #2038](https://github.com/faker-ruby/faker/pull/2038) Drop EOL Rubies from CI tests [@Zeragamba](https://github.com/Zeragamba)
- [PR #2033](https://github.com/faker-ruby/faker/pull/2033) Use `Faker::Base::ULetters` constant instead [@vbrazo](https://github.com/vbrazo)
- [PR #2028](https://github.com/faker-ruby/faker/pull/2028) Reorganize some tests [@connorshea](https://github.com/connorshea)
- [PR #1853](https://github.com/faker-ruby/faker/pull/1853) Exclude string.rb from consideration by YARD. [@connorshea](https://github.com/connorshea)

## Deprecation

- [PR #2031](https://github.com/faker-ruby/faker/pull/2031) Deprecate `HeroesOfTheStorm.class` [@koic](https://github.com/koic)

## Documentation

- [PR #2065](https://github.com/faker-ruby/faker/pull/2065) Add missing documentation to `Faker::Computer` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2064](https://github.com/faker-ruby/faker/pull/2064) Add minecraft generators [@Ri1a](https://github.com/Ri1a)
- [PR #2061](https://github.com/faker-ruby/faker/pull/2061) Update docs for `Faker::Date` with separate examples [@danielTiringer](https://github.com/danielTiringer)
- [PR #2057](https://github.com/faker-ruby/faker/pull/2057) Add missing quotes to `Faker::Internet` [@Zeragamba](https://github.com/Zeragamba)
- [PR #2055](https://github.com/faker-ruby/faker/pull/2055) Add YARD docs to `Faker::NHS` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2054](https://github.com/faker-ruby/faker/pull/2054) Add YARD docs to `Faker::Chile_Rut` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2053](https://github.com/faker-ruby/faker/pull/2053) Add YARD docs to `Faker::Lorem_Flickr` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2052](https://github.com/faker-ruby/faker/pull/2052) Add YARD docs to `Faker::Lorem_Pixel` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2051](https://github.com/faker-ruby/faker/pull/2051) Add YARD docs to `Faker::Omniauth` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2036](https://github.com/faker-ruby/faker/pull/2036) Add YARD docs to `Faker::Markdown` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2035](https://github.com/faker-ruby/faker/pull/2035) Add YARD docs to `Faker::ID_Number` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2030](https://github.com/faker-ruby/faker/pull/2030) Add general documentation for `Faker::Blood` [@jbergenson](https://github.com/jbergenson)
- [PR #2029](https://github.com/faker-ruby/faker/pull/2029) Allow passing a string to specific `Faker::Date` methods. [@connorshea](https://github.com/connorshea)

## Feature Request

- [PR #2040](https://github.com/faker-ruby/faker/pull/2040) Split lint and test Github actions [@Zeragamba](https://github.com/Zeragamba)
- [PR #2032](https://github.com/faker-ruby/faker/pull/2032) Add `gender-neutral` first names to `Faker::Name` [@cmunozgar](https://github.com/cmunozgar)
- [PR #1965](https://github.com/faker-ruby/faker/pull/1965) Add new `full_address_as_hash` method which return the required address [@AmrAdelKhalil](https://github.com/AmrAdelKhalil)
- [PR #1952](https://github.com/faker-ruby/faker/pull/1952) Add `Faker::Movie.title` [@gizipp](https://github.com/gizipp)
- [PR #1932](https://github.com/faker-ruby/faker/pull/1932) Added AHTF Wisdom [@brotherjack](https://github.com/brotherjack)
- [PR #1912](https://github.com/faker-ruby/faker/pull/1912) Add `Faker::Music::Rush` [@willianveiga](https://github.com/willianveiga)
- [PR #1865](https://github.com/faker-ruby/faker/pull/1865) Add Big Bang Theory [@pathaknv](https://github.com/pathaknv)
- [PR #1858](https://github.com/faker-ruby/faker/pull/1858) Add `Faker::TvShows::Futurama` [@JoeNyland](https://github.com/JoeNyland)
- [PR #1821](https://github.com/faker-ruby/faker/pull/1821) Add HTTP status codes generator [@willianveiga](https://github.com/willianveiga)
- [PR #1804](https://github.com/faker-ruby/faker/pull/1804) Add `Faker::TvShows::Simpsons.episode_title` [@martinbjeldbak](https://github.com/martinbjeldbak)
- [PR #1670](https://github.com/faker-ruby/faker/pull/1670) Adds `Faker::Music::Prince` [@jessecalton](https://github.com/jessecalton)

## Update locales

- [PR #1792](https://github.com/faker-ruby/faker/pull/1792) Add more prefixes and suffixes to Name [@mathisto](https://github.com/mathisto)

## Update local dependencies

- Update RuboCop requirement from = 0.81.0 to = 0.85.1
- Update RuboCop requirement from = 0.85.1 to = 0.86.0 (#2066)
- Update test-unit requirement from = 3.3.5 to = 3.3.6 (#2046)
- Bump i18n from 1.8.2 to 1.8.3 (#2034)

------------------------------------------------------------------------------

## [v2.12.0](https://github.com/faker-ruby/faker/tree/v2.12.0) (2020-05-31)

This version:
- adds several YARD docs
- fixes some locale issues
- fixes a few bugs in Faker generators
- improves code quality
- adds a few generators for Movies, Music and TV Shows
- updates local dependencies

## Bug/Fixes

- [PR #2019](https://github.com/faker-ruby/faker/pull/2019) Update 'prepare' regexp to allow hyphen [@jbergenson](https://github.com/jbergenson)
- [PR #2012](https://github.com/faker-ruby/faker/pull/2012) Add else condition to prevent false positive [@jbergenson](https://github.com/jbergenson)
- [PR #1985](https://github.com/faker-ruby/faker/pull/1985) Fix an error for `Faker::Computer.os` [@koic](https://github.com/koic)
- [PR #1971](https://github.com/faker-ruby/faker/pull/1971) Fixing the CI failure by fixing the infinite loop in Commerce [@amatsuda](https://github.com/amatsuda)

## Chores

- [PR #1988](https://github.com/faker-ruby/faker/pull/1988) Removing meaningless begin and end [@amatsuda](https://github.com/amatsuda)
- [PR #1979](https://github.com/faker-ruby/faker/pull/1979) Reuse the `lvar` instead of calling `File.dirname(__FILE__)` again and again [@amatsuda](https://github.com/amatsuda)

## Documentation

- [PR #2022](https://github.com/faker-ruby/faker/pull/2022) Add YARD docs to `Faker::Invoice` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2021](https://github.com/faker-ruby/faker/pull/2021) Add YARD docs to `Faker::Hipster` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2020](https://github.com/faker-ruby/faker/pull/2020) Add YARD docs to `Faker::Measurement` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2017](https://github.com/faker-ruby/faker/pull/2017) Fix docs for `Faker::Games::Control.altered_world_event` [@Zeragamba](https://github.com/Zeragamba)
- [PR #2016](https://github.com/faker-ruby/faker/pull/2016) Fix yard documentation issues [@danielTiringer](https://github.com/danielTiringer)
- [PR #2015](https://github.com/faker-ruby/faker/pull/2015) Add YARD docs to `Faker::Quotes` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2011](https://github.com/faker-ruby/faker/pull/2011) Update `star_wars.yml` [@garrettmichaelgeorge](https://github.com/garrettmichaelgeorge)
- [PR #2010](https://github.com/faker-ruby/faker/pull/2010) Add missing links in README.md [@Naokimi](https://github.com/Naokimi)
- [PR #2009](https://github.com/faker-ruby/faker/pull/2009) Add YARD docs to `Faker::Placeholdit` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2008](https://github.com/faker-ruby/faker/pull/2008) Add YARD docs to `Faker::Verb` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2007](https://github.com/faker-ruby/faker/pull/2007) Add YARD docs to `Faker::Phone_Number` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2004](https://github.com/faker-ruby/faker/pull/2004) Add YARD docs to `Faker::String` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2001](https://github.com/faker-ruby/faker/pull/2001) Add YARD docs to `Faker::South_Africa` [@danielTiringer](https://github.com/danielTiringer)
- [PR #2000](https://github.com/faker-ruby/faker/pull/2000) Add YARD docs to `Faker::JSON` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1999](https://github.com/faker-ruby/faker/pull/1999) Add YARD docs to `Faker::Types` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1998](https://github.com/faker-ruby/faker/pull/1998) Add YARD docs to `Faker::Finance` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1997](https://github.com/faker-ruby/faker/pull/1997) Add YARD docs to `Faker::Driving_Licence` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1996](https://github.com/faker-ruby/faker/pull/1996) Add YARD docs to `Crypto Coin` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1995](https://github.com/faker-ruby/faker/pull/1995) Add YARD docs to `Faker::Commerce` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1993](https://github.com/faker-ruby/faker/pull/1993) Add YARD docs to `Faker::Vehicle` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1990](https://github.com/faker-ruby/faker/pull/1990) Add YARD docs to `Faker::File` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1989](https://github.com/faker-ruby/faker/pull/1989) Add YARD docs to `Faker::Bank` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1984](https://github.com/faker-ruby/faker/pull/1984) Minor documentation fix for `Faker::University` [@Zeragamba](https://github.com/Zeragamba)
- [PR #1983](https://github.com/faker-ruby/faker/pull/1983) Add YARD docs to `Faker::Twitter` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1982](https://github.com/faker-ruby/faker/pull/1982) Add YARD docs to `Faker::Cosmere` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1981](https://github.com/faker-ruby/faker/pull/1981) Add YARD docs to `Faker::Stripe` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1980](https://github.com/faker-ruby/faker/pull/1980) Add YARD docs to `Faker::Construction` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1976](https://github.com/faker-ruby/faker/pull/1976) Add YARD docs to `Faker::Name` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1975](https://github.com/faker-ruby/faker/pull/1975) Add YARD docs to `Faker::Compass` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1959](https://github.com/faker-ruby/faker/pull/1959) Add YARD docs to `Faker::University` [@danielTiringer](https://github.com/danielTiringer)
- [PR #1956](https://github.com/faker-ruby/faker/pull/1956) Add YARD docs to `Faker::SlackEmoji` [@rutger-t](https://github.com/rutger-t)
- [PR #1943](https://github.com/faker-ruby/faker/pull/1943) Update documentation for unique.exclude [@mtancoigne](https://github.com/mtancoigne)
- [PR #1925](https://github.com/faker-ruby/faker/pull/1925) AdD `Faker::Game::WarhammerFantasy` [@sotek222](https://github.com/sotek222)

## Feature Request

- [PR #2025](https://github.com/faker-ruby/faker/pull/2025) Add `Faker::TvShows::Suits` [@ash-elangovan](https://github.com/ash-elangovan)
- [PR #2024](https://github.com/faker-ruby/faker/pull/2024) Added Phish Albums and Musicians [@zfine416](https://github.com/zfine416)
- [PR #2013](https://github.com/faker-ruby/faker/pull/2013) Add `Faker::Games::Control` [@Zeragamba](https://github.com/Zeragamba)
- [PR #1994](https://github.com/faker-ruby/faker/pull/1994) Enable Ruby testing github workflow [@Zeragamba](https://github.com/Zeragamba)
- [PR #1966](https://github.com/faker-ruby/faker/pull/1966) Add `Faker::Games:DnD` [@Naokimi](https://github.com/Naokimi)
- [PR #1962](https://github.com/faker-ruby/faker/pull/1962) Adding Pearl Jam to the Music module [@briri](https://github.com/briri)
- [PR #1960](https://github.com/faker-ruby/faker/pull/1960) Added `Faker::Blood` [@suraj32](https://github.com/suraj32)
- [PR #1931](https://github.com/faker-ruby/faker/pull/1931) Add `Faker::Movies::Departed` Class [@jaebradley](https://github.com/jaebradley)
- [PR #1696](https://github.com/faker-ruby/faker/pull/1696) Add Bibles class with King James subclass [@jbergenson](https://github.com/jbergenson)
- [PR #1485](https://github.com/faker-ruby/faker/pull/1485) Plays and musicals [@armandofox](https://github.com/armandofox)

## Update locales

- [PR #2014](https://github.com/faker-ruby/faker/pull/2014) Make locale self-contained [@psibi](https://github.com/psibi)
- [PR #1986](https://github.com/faker-ruby/faker/pull/1986) Added quotations to Shirahoshi [@iavivai](https://github.com/iavivai)
- [PR #1973](https://github.com/faker-ruby/faker/pull/1973) Fix mis-quotations [@kayhide](https://github.com/kayhide)
- [PR #1967](https://github.com/faker-ruby/faker/pull/1967) ko locale updates [@jae57](https://github.com/jae57)
- [PR #1964](https://github.com/faker-ruby/faker/pull/1964) en-AU locale updates [@mattman](https://github.com/mattman)
- [PR #1948](https://github.com/faker-ruby/faker/pull/1948) Add `Faker::Computer` [@cmcramer](https://github.com/cmcramer)

## Update local dependencies

- Update minitest requirement from = 5.14.0 to = 5.14.1 (#1987)
- Update RuboCop requirement from = 0.80.1 to = 0.81.0 (#1955)
- Update pry requirement from = 0.13.0 to = 0.13.1 (#1963)
- Update yard requirement from = 0.9.24 to = 0.9.25 (#1970)

------------------------------------------------------------------------------

## [v2.11.0](https://github.com/faker-ruby/faker/tree/v2.11.0) (2020-03-24)

## Bug/Fixes

- [PR #1938](https://github.com/faker-ruby/faker/pull/1938) Fix omniauth consistency [@DouglasLutz](https://github.com/DouglasLutz)

## Documentation

- [PR #1949](https://github.com/faker-ruby/faker/pull/1949) Add YARD doc for Faker::Cannabis [@mashuDuek](https://github.com/mashuDuek)
- [PR #1944](https://github.com/faker-ruby/faker/pull/1944) Add YARD docs for Faker::FunnyName [@curriecode](https://github.com/curriecode)
- [PR #1935](https://github.com/faker-ruby/faker/pull/1935) Add YARD docs for the unique method [@connorshea](https://github.com/connorshea)

## Feature Request

- [PR #1946](https://github.com/faker-ruby/faker/pull/1946) Add Faker::Rajnikanth [@wolwire](https://github.com/wolwire)
- [PR #1940](https://github.com/faker-ruby/faker/pull/1940) Add Faker::Quotes::Chiquito [@jantequera](https://github.com/jantequera)
- [PR #1883](https://github.com/faker-ruby/faker/pull/1883) add Internet#base64 [@cyrilchampier](https://github.com/cyrilchampier)

## Update locales

- [PR #1945](https://github.com/faker-ruby/faker/pull/1945) Remove female first name 'Miss' [@ags](https://github.com/ags)
- [PR #1929](https://github.com/faker-ruby/faker/pull/1929) Fixed mobile prefixes for en-GB locale [@SamHart91](https://github.com/SamHart91)

## Update local dependencies

- Update pry requirement from = 0.12.2 to = 0.13.0 (#1951)
- Update RuboCop requirement from = 0.80.0 to = 0.80.1 (#1941)
- Update RuboCop requirement from = 0.79.0 to = 0.80.0 (#1937)

------------------------------------------------------------------------------

## [v2.10.2](https://github.com/faker-ruby/faker/tree/v2.10.2) (2020-02-15)

This version:
- adds a few YARD docs
- fixes locales
- updates local dependencies

## Chores

- [PR #1924](https://github.com/faker-ruby/faker/pull/1924) Use ruby's `File::Separator` rather than '/' as a default for direct [@swiknaba](https://github.com/swiknaba)

## Documentation

- [PR #1913](https://github.com/faker-ruby/faker/pull/1913) Add YARD docs for Faker::DcComics [@ash-elangovan](https://github.com/ash-elangovan)

## Update locales

- [PR #1934](https://github.com/faker-ruby/faker/pull/1934) Add street_address for en-nz locale [@psibi](https://github.com/psibi)
- [PR #1933](https://github.com/faker-ruby/faker/pull/1933) Make id locale consistent. [@psibi](https://github.com/psibi)
- [PR #1930](https://github.com/faker-ruby/faker/pull/1930) Remove spaces before apostrophes [@jrmhaig](https://github.com/jrmhaig)
- [PR #1927](https://github.com/faker-ruby/faker/pull/1927) zh-TW locale fix: Avoid double de-reference for name_with_middle [@psibi](https://github.com/psibi)
- [PR #1922](https://github.com/faker-ruby/faker/pull/1922) zh-CN locale fix: Directly refer to the expected values [@psibi](https://github.com/psibi)
- [PR #1921](https://github.com/faker-ruby/faker/pull/1921) uk locale fix: Make empty fields consistent [@psibi](https://github.com/psibi)
- [PR #1920](https://github.com/faker-ruby/faker/pull/1920) pt locale fix: Make city fields consistent with other [@psibi](https://github.com/psibi)
- [PR #1918](https://github.com/faker-ruby/faker/pull/1918) Make Japanese Lorem sentences look more natural [@rastamhadi](https://github.com/rastamhadi)
- [PR #1915](https://github.com/faker-ruby/faker/pull/1915) Add yard docs for Faker::Company [@kos31de](https://github.com/kos31de)
- [PR #1914](https://github.com/faker-ruby/faker/pull/1914) Data source fix for ha locale [@psibi](https://github.com/psibi)
- [PR #1911](https://github.com/faker-ruby/faker/pull/1911) Removed duplicate value [@ash-elangovan](https://github.com/ash-elangovan)
- [PR #1908](https://github.com/faker-ruby/faker/pull/1908) Add more colors [@tomcol](https://github.com/tomcol)
- [PR #1903](https://github.com/faker-ruby/faker/pull/1903) fr locale: pokemon's root key should be games [@connorshea](https://github.com/connorshea)
- [PR #1902](https://github.com/faker-ruby/faker/pull/1902) Remove empty string in phone_number formats [@psibi](https://github.com/psibi)
- [PR #1901](https://github.com/faker-ruby/faker/pull/1901) fr-CA locale fix: pokemon's root key should be games [@psibi](https://github.com/psibi)
- [PR #1900](https://github.com/faker-ruby/faker/pull/1900) Use postcode for en-ZA [@psibi](https://github.com/psibi)
- [PR #1899](https://github.com/faker-ruby/faker/pull/1899) Locale root name should be en-NEP [@psibi](https://github.com/psibi)
- [PR #1812](https://github.com/faker-ruby/faker/pull/1812) Add vat number rule for es-MX [@arandilopez](https://github.com/arandilopez)

## Update local dependencies

- Update test-unit requirement from = 3.3.4 to = 3.3.5 (#1896)

------------------------------------------------------------------------------

## [v2.10.1](https://github.com/faker-ruby/faker/tree/v2.10.1) (2020-01-13)

This version:
- fixes locales
- updates local dependencies
- fixes warnings

## Bug/Fixes

- [PR #1868](https://github.com/faker-ruby/faker/pull/1868) Fix a deprecation warning in unique_generator.rb related to the kwarg [@connorshea](https://github.com/connorshea)

## Update Locales

- [PR #1800](https://github.com/faker-ruby/faker/pull/1800) Update diners_club and jcb test cards since they were updated in String [@santib](https://github.com/santib)
- [PR #1879](https://github.com/faker-ruby/faker/pull/1879) Field changes in da-DK locale [@psibi](https://github.com/psibi)
- [PR #1878](https://github.com/faker-ruby/faker/pull/1878) Fix name related files in ca locale [@psibi](https://github.com/psibi)
- [PR #1877](https://github.com/faker-ruby/faker/pull/1877) Fix the path names for bg.yml [@psibi](https://github.com/psibi)

## Update local dependencies

- Allow all versions of i18n from 1.6 up to 2 (#1894) [@orien](https://github.com/orien)
- Update minitest requirement from = 5.13.0 to = 5.14.0 (#1904)
- Bump i18n from 1.8.1 to 1.8.2 (#1905)
- Bump i18n from 1.8.0 to 1.8.1 (#1895)
- Update i18n requirement from >= 1.6, < 1.8 to >= 1.6, < 1.9 (#1893)
- Update yard requirement from = 0.9.23 to = 0.9.24 (#1892)
- Update RuboCop requirement from = 0.78.0 to = 0.79.0 (#1890)
- Update yard requirement from = 0.9.22 to = 0.9.23 (#1889)
- Update yard requirement from = 0.9.20 to = 0.9.22 (#1882)

------------------------------------------------------------------------------

## [v2.10.0](https://github.com/faker-ruby/faker/tree/v2.10.0) (2019-12-28)

This version:
- adds `Faker::Address.mail_box`
- adds YARD docs
- fix Ruby 2.7 warnings
- adds other minor changes

## Bug/Fixes

- [PR #1876](https://github.com/faker-ruby/faker/pull/1876) Fix Ruby 2.7 deprecation warnings for the translate method. [@connorshea](https://github.com/connorshea)
- [PR #1867](https://github.com/faker-ruby/faker/pull/1867) Fix tests failing on Ruby 2.7 [@connorshea](https://github.com/connorshea)

## Chores

- [PR #1866](https://github.com/faker-ruby/faker/pull/1866) Upgrade the Gemfile.lock to Bundler 2. [@connorshea](https://github.com/connorshea)

## Documentation

- [PR #1873](https://github.com/faker-ruby/faker/pull/1873) Add YARD docs for `Faker::Music{,::Opera}` [@jas14](https://github.com/jas14)
- [PR #1862](https://github.com/faker-ruby/faker/pull/1862) Update phone number documentation [@aVigorousDev](https://github.com/aVigorousDev)

## Feature Request

- [PR #1875](https://github.com/faker-ruby/faker/pull/1875) Add Ruby 2.7 to the CI test matrix. [@connorshea](https://github.com/connorshea)
- [PR #1568](https://github.com/faker-ruby/faker/pull/1568) Add `Faker::Address.mail_box` and some NZ locale updates [@mermop](https://github.com/mermop)

## Refactoring

- [PR #1874](https://github.com/faker-ruby/faker/pull/1874) Extract constants in `Faker::Music` [@jas14](https://github.com/jas14)

## Update local dependencies

Update RuboCop requirement from = 0.77.0 to = 0.78.0 (#1869)

------------------------------------------------------------------------------

## [v2.9.0](https://github.com/faker-ruby/faker/tree/v2.9.0) (2019-12-16)

This version:
- adds `Faker::Gender.short_binary_type`
- adds a few YARD docs
- fix Faker::Educator issues
- update locales

## Bug/Fixes

- [PR #1860](https://github.com/faker-ruby/faker/pull/1860) Fix Educator methods returning bad data. [@connorshea](https://github.com/connorshea)

## Documentation

- [PR #1859](https://github.com/faker-ruby/faker/pull/1859) YYYY-MM-DD in CHANGELOG [@jas14](https://github.com/jas14)
- [PR #1797](https://github.com/faker-ruby/faker/pull/1797) add YARD doc for Faker::Job [@ashishra0](https://github.com/ashishra0)
- [PR #1790](https://github.com/faker-ruby/faker/pull/1790) add Faker::Beer YARD docs [@ashishra0](https://github.com/ashishra0)

## Feature Request

- [PR #1863](https://github.com/faker-ruby/faker/pull/1863) Add Faker::Gender.short_binary_type [@bruno-b-martins](https://github.com/bruno-b-martins)

## Update locales

- [PR #1864](https://github.com/faker-ruby/faker/pull/1864) adding `male` & `female` first names for persian [@alphamarket](https://github.com/alphamarket)

------------------------------------------------------------------------------

## [v2.8.1](https://github.com/faker-ruby/faker/tree/v2.8.1) (2019-12-06)

## Bug/Fixes

- [PR #1846](https://github.com/faker-ruby/faker/pull/1846) Fix internet custom domain with suffix [@ngouy](https://github.com/ngouy)

## Documentation

- [PR #1852](https://github.com/faker-ruby/faker/pull/1852) Add YARD docs for Faker::Business. [@connorshea](https://github.com/connorshea)
- [PR #1851](https://github.com/faker-ruby/faker/pull/1851) Add YARD docs for Faker::Crypto. [@connorshea](https://github.com/connorshea)
- [PR #1850](https://github.com/faker-ruby/faker/pull/1850) Add YARD docs for Faker::Kpop. [@connorshea](https://github.com/connorshea)
- [PR #1849](https://github.com/faker-ruby/faker/pull/1849) Add YARD docs for Faker::BossaNova. [@connorshea](https://github.com/connorshea)
- [PR #1848](https://github.com/faker-ruby/faker/pull/1848) Add YARD Docs for Faker::Demographic. [@connorshea](https://github.com/connorshea)
- [PR #1844](https://github.com/faker-ruby/faker/pull/1844) Fix yard doc in contribution [@vikas95prasad](https://github.com/vikas95prasad)
- [PR #1802](https://github.com/faker-ruby/faker/pull/1802) Add YARD doc for Faker::Food [@sap1enza](https://github.com/sap1enza)
- [PR #1766](https://github.com/faker-ruby/faker/pull/1766) Add YARD docs for Faker::Address [@connorshea](https://github.com/connorshea)

## Refactoring

- [PR #1847](https://github.com/faker-ruby/faker/pull/1847) Makes minor refactors on Internet.domain_name method [@tiagofsilva](https://github.com/tiagofsilva)
- [PR #1772](https://github.com/faker-ruby/faker/pull/1848) Refactor Faker::Educator and add docs [@connorshea](https://github.com/connorshea)

## Update local dependencies

- Update RuboCop requirement from = 0.76.0 to = 0.77.0 (#1843)

------------------------------------------------------------------------------

## [v2.8.0](https://github.com/faker-ruby/faker/tree/v2.8.0) (2019-12-01)

## Bug/Fixes

- [PR #1563](https://github.com/faker-ruby/faker/pull/1563)
Fix generating routing number [@psienko](https://github.com/psienko)

## Chores

- [PR #1835](https://github.com/faker-ruby/faker/pull/1835)
Remove duplicate method description [@pacso](https://github.com/pacso)

## Documentation

- [PR #1837](https://github.com/faker-ruby/faker/pull/1837)
docs: Internet #email, #domain do not control TLD [@olleolleolle](https://github.com/olleolleolle)
- [PR #1833](https://github.com/faker-ruby/faker/pull/1833) Explain safe_email method [@swrobel](https://github.com/swrobel)
- [PR #1810](https://github.com/faker-ruby/faker/pull/1810) Add yard docs for Faker::Coffee methods [@LuanGB](https://github.com/LuanGB)
- [PR #1803](https://github.com/faker-ruby/faker/pull/1803)
add YARD doc for Faker::Coin [@sap1enza](https://github.com/sap1enza) [@connorshea](https://github.com/connorshea)
- [PR #1799](https://github.com/faker-ruby/faker/pull/1799) Remove 'See below examples' for consistency [@DevUsmanGhani](https://github.com/DevUsmanGhani)
- [PR #1793](https://github.com/faker-ruby/faker/pull/1793) add Faker::Relationship YARD docs [@DevUsmanGhani](https://github.com/DevUsmanGhani)

## Feature Request

- [PR #1808](https://github.com/faker-ruby/faker/pull/1808) Adds domain option for Internet email and domain_name methods [@tiagofsilva](https://github.com/tiagofsilva)

## Update locales

- [PR #1841](https://github.com/faker-ruby/faker/pull/1841)
Fix strange result from `Lorem.word` in ja locale [@yujideveloper](https://github.com/yujideveloper)
- [PR #1839](https://github.com/faker-ruby/faker/pull/1839)
added new heroes, new maps and almost all of the quotes [@TCsTheMechanic](https://github.com/TCsTheMechanic)

## Update local dependencies

- [PR #1831](https://github.com/faker-ruby/faker/pull/1831) Update rake requirement from = 13.0.0 to = 13.0.1 [@DevUsmanGhani](https://github.com/DevUsmanGhani)

------------------------------------------------------------------------------

## [v2.7.0](https://github.com/faker-ruby/faker/tree/v2.7.0) (2019-11-01)

This version:
- adds `Faker::IDNumber.chilean_id`
- updates some translations/locales
- updates local dependencies
- adds SemVer badge

## Documentation

- [PR #1814](https://github.com/faker-ruby/faker/pull/1814) Add Discord link [@vbrazo](https://github.com/vbrazo)
- [PR #1289](https://github.com/faker-ruby/faker/pull/1289) Add SemVer compatibility badge to README [@greysteil](https://github.com/greysteil)

## Feature Request

- [PR #1819](https://github.com/faker-ruby/faker/pull/1819) Adding chilean_id in Faker::IDNumber [@cristofer](https://github.com/cristofer)

## Update locales

- [PR #1824](https://github.com/faker-ruby/faker/pull/1824) Added Canadian Country Code [@clinch](https://github.com/clinch)
- [PR #1817](https://github.com/faker-ruby/faker/pull/1817) Add Japanese animal names [@shouichi](https://github.com/shouichi)
- [PR #1816](https://github.com/faker-ruby/faker/pull/1816) Add Japanese bank names [@shouichi](https://github.com/shouichi)
- [PR #1813](https://github.com/faker-ruby/faker/pull/1813) Translate Canadian provinces for fr-CA [@Bhacaz](https://github.com/Bhacaz)
- [PR #1806](https://github.com/faker-ruby/faker/pull/1806) Add Terry Bogard to Super Smash Bros. options [@clinch](https://github.com/clinch)

## Update local dependencies

- Update RuboCop requirement from = 0.75.0 to = 0.75.1 (#1811)
- Update RuboCop requirement from = 0.75.1 to = 0.76.0 (#1822)
- Update minitest requirement from = 5.12.2 to = 5.13.0 (#1823)

------------------------------------------------------------------------------

## [v2.6.0](https://github.com/faker-ruby/faker/tree/v2.6.0) (2019-10-10)

This version:
- adds `Faker::Date.in_date_period`
- adds `Faker::WorldCup` YARD docs
- updates local dependencies

## Documentation

- [PR #1789](https://github.com/faker-ruby/faker/pull/1789) Faker::WorldCup YARD docs [@ashishra0](https://github.com/ashishra0)

## Feature Request

- [PR #1755](https://github.com/faker-ruby/faker/pull/1755) Add Faker::Date.in_date_period [@AmrAdelKhalil](https://github.com/AmrAdelKhalil)

## Update local dependencies

The following development dependencies were updated:
- Update rake requirement from = 12.3.3 to = 13.0.0 (#1776)
- Update minitest requirement from = 5.12.0 to = 5.12.2 (#1775)
- Update test-unit requirement from = 3.3.3 to = 3.3.4 (#1774)

------------------------------------------------------------------------------

## [v2.5.0](https://github.com/faker-ruby/faker/tree/v2.5.0) (2019-09-30)

This version introduces:
- locales for Thai language - the mother language in Thailand
- YARD documentation for faker interfaces
- locales updates or fixes

## Feature Request

- [PR #1773](https://github.com/faker-ruby/faker/pull/1773) Two new locales added: th and en-th [@kodram](https://github.com/kodram)

## Documentation

- [PR #1771](https://github.com/faker-ruby/faker/pull/1771) Fix some RuboCop comments that were showing up in YARD docs. [@connorshea](https://github.com/connorshea)
- [PR #1767](https://github.com/faker-ruby/faker/pull/1767) Fix two incorrect flexible method calls. [@connorshea](https://github.com/connorshea)
- [PR #1761](https://github.com/faker-ruby/faker/pull/1761) Add YARD docs for the Basketball and Football fakers. [@connorshea](https://github.com/connorshea)
- [PR #1768](https://github.com/faker-ruby/faker/pull/1768) Add YARD docs for Faker::Restaurant. [@connorshea](https://github.com/connorshea)
- [PR #1759](https://github.com/faker-ruby/faker/pull/1759) Add YARD docs for all remaining TV Shows [@connorshea](https://github.com/connorshea)
- [PR #1758](https://github.com/faker-ruby/faker/pull/1758) Add YARD docs for Doctor Who and fix a method name. [@connorshea](https://github.com/connorshea)
- [PR #1756](https://github.com/faker-ruby/faker/pull/1756) Add more miscellaneous YARD docs [@connorshea](https://github.com/connorshea)
- [PR #1753](https://github.com/faker-ruby/faker/pull/1753) Add YARD docs for Date, Time, and Number [@connorshea](https://github.com/connorshea)

## Update locales

- [PR #1764](https://github.com/faker-ruby/faker/pull/1764) Remove "mint green" from color [@ro-savage](https://github.com/ro-savage)
- [PR #1751](https://github.com/faker-ruby/faker/pull/1751) fix from Color.name to Color.color_name [@4geru](https://github.com/4geru)

## Update local dependencies

The following development dependencies were updated:
- Update minitest requirement from = 5.11.3 to = 5.12.0 (#1763)

------------------------------------------------------------------------------

## [v2.4.0](https://github.com/faker-ruby/faker/tree/v2.4.0) (2019-09-19)

## Documentation

- [PR #1750](https://github.com/faker-ruby/faker/pull/1750) add only japanese word spec [@4geru](https://github.com/4geru)
- [PR #1740](https://github.com/faker-ruby/faker/pull/1740) Add more YARD docs [@connorshea](https://github.com/connorshea)
- [PR #1747](https://github.com/faker-ruby/faker/pull/1747) Fix PR links [@geniou](https://github.com/geniou)

## Feature Request

- [PR #1742](https://github.com/faker-ruby/faker/pull/1742) Add Faker::Blockchain::Aeternity [@2pd](https://github.com/2pd)

## Update locales

- [PR #1743](https://github.com/faker-ruby/faker/pull/1743) Fix another ambiguity in element_symbol field [@psibi](https://github.com/psibi)
- [PR #1748](https://github.com/faker-ruby/faker/pull/1748) fix typo from bread to breed [@4geru](https://github.com/4geru)
- [PR #1752](https://github.com/faker-ruby/faker/pull/1752) fix creature i18n path in japanese [@4geru](https://github.com/4geru)

## Update local dependencies

The following development dependencies were updated:
- Update simplecov requirement from = 0.17.0 to = 0.17.1 (#1749)

------------------------------------------------------------------------------

## [v2.3.0](https://github.com/faker-ruby/faker/tree/v2.3.0) (2019-09-12)

## Documentation

- [PR #1741](https://github.com/faker-ruby/faker/pull/1741) Fix the .gitignore for YARD. [@connorshea](https://github.com/connorshea)
- [PR #1553](https://github.com/faker-ruby/faker/pull/1553) Yard powered docs [@Zeragamba](https://github.com/Zeragamba) [@connorshea](https://github.com/connorshea)
- [PR #1727](https://github.com/faker-ruby/faker/pull/1727) Remove Football documentation from wrong category [@lucasqueiroz](https://github.com/lucasqueiroz)

## Feature Request

- [PR #1738](https://github.com/faker-ruby/faker/pull/1738) Add mock data for Apple OAuth [@dzunk](https://github.com/dzunk)

## Update locales

- [PR #1723](https://github.com/faker-ruby/faker/pull/1723) Add pokemon name in Johto area [@mathieujobin](https://github.com/mathieujobin)
- [PR #1732](https://github.com/faker-ruby/faker/pull/1732) Quebec province postal codes starts by [GHJ], adding missing two [@Ryutooooo](https://github.com/Ryutooooo)

------------------------------------------------------------------------------

## [v2.2.2](https://github.com/faker-ruby/faker/tree/v2.2.2) (2019-09-05)

## Bug/Fixes

- [PR #1717](https://github.com/faker-ruby/faker/pull/1717) Fix ambiguity in element_symbol field [@psibi](https://github.com/psibi)

## Chores

- [PR #1724](https://github.com/faker-ruby/faker/pull/1724) Include RuboCop-faker autocorrect in deprecation [@koic](https://github.com/koic)

## Documentation

- [PR #1726](https://github.com/faker-ruby/faker/pull/1726) Include 2.x breaking return value change in changelog [@zorab47](https://github.com/zorab47)
- [PR #1722](https://github.com/faker-ruby/faker/pull/1722) Fix examples in the Dota docs [@bzf](https://github.com/bzf)

## Update local dependencies

The following development dependencies were updated:
- rake requirement from = 12.3.1 to = 12.3.3 (#1719)
- RuboCop requirement from = 0.59.1 to = 0.74.0 (#1721)
- simplecov requirement from = 0.16.1 to = 0.17.0 (#1718)

------------------------------------------------------------------------------

## [v2.2.1](https://github.com/faker-ruby/faker/tree/v2.2.1) (2019-08-30)

## Bug/Fixes

- [PR #1712](https://github.com/faker-ruby/faker/pull/1712) Fix number(digits: 1) always returns 0 [@ianlet](https://github.com/ianlet)

`Faker::Number.number(digits: 1)` was always returning `0`.

Fixing number with one digit caused the test_insignificant_zero to fail. As it seemed that the behavior tested by test_insignificant_zero was already covered by test_number and test_decimal, we removed it to prevent duplication.

## [v2.2.0](https://github.com/faker-ruby/faker/tree/v2.2.0) (2019-08-25)

## Deprecate

- [PR #1698](https://github.com/faker-ruby/faker/pull/1698) Add warn for positional arguments when using Faker 2.0 [@koic](https://github.com/koic)

Add deprecation warning for positional arguments to notify users that are coming from Faker version < 2.0. Its main goal is to make upgrades easier.

## Documentation

- [PR #1688](https://github.com/faker-ruby/faker/pull/1688) Update README install instructions [@EduardoGHdez](https://github.com/EduardoGHdez)
- [PR #1689](https://github.com/faker-ruby/faker/pull/1689) Update README.md [@Zeragamba](https://github.com/Zeragamba)
- [PR #1690](https://github.com/faker-ruby/faker/pull/1690) Update issue url in PULL_REQUEST_TEMPLATE [@bugtender](https://github.com/bugtender)
- [PR #1703](https://github.com/faker-ruby/faker/pull/1703) Return HTTPS URLs from Lorem Flickr [@connorshea](https://github.com/connorshea)

## Feature Request
- [PR #1686](https://github.com/faker-ruby/faker/pull/1686) Update test-unit gem to 3.3.3 [@connorshea](https://github.com/connorshea)

## Bug/Fixes
- [PR #1702](https://github.com/faker-ruby/faker/pull/1702) Fix an argument for test_faker_stripe.rb [@koic](https://github.com/koic)
- [PR #1694](https://github.com/faker-ruby/faker/pull/1694) Ensure mix_case returns at least one lower and one upper case letter [@bpleslie](https://github.com/bpleslie)

------------------------------------------------------------------------------

## [v2.1.2](https://github.com/faker-ruby/faker/tree/v2.1.2) (2019-08-10)

## Enhancements

- [PR #1495](https://github.com/faker-ruby/faker/pull/1495) Add Brazilian documents generation and documentation [@lucasqueiroz](https://github.com/lucasqueiroz)

## Issues

We had to use `bundled with 1.7.3` to avoid some issues.

## [v2.1.1](https://github.com/faker-ruby/faker/tree/2.1.1) (2019-08-10)

## Bug/Fixes

- [PR #1685](https://github.com/stympy/faker/pull/1685) Upgrade i18n [@EduardoGHdez](https://github.com/EduardoGHdez)

`bundler-audit` has identified that i18 has fix a security vulnerability, that has been fixed in the 0.8 version.

- [PR #1683](https://github.com/stympy/faker/pull/1683) Rollback Faker::Time changes [@vbrazo](https://github.com/vbrazo)

Rollback Faker::Time changes because we should expect the date format from activesupport's en.yml.

## Documentation

- [PR #1677](https://github.com/faker-ruby/faker/pull/1677) Fix docs for Internet#password generator [@ur5us](https://github.com/ur5us)

------------------------------------------------------------------------------

## [v2.1.0](https://github.com/faker-ruby/faker/tree/v2.1.0) (2019-07-31)

## Bug/Fixes
- [PR #1675](https://github.com/faker-ruby/faker/pull/1675) Fix off-by-one error when formatting month names [@jutonz](https://github.com/jutonz)

This change required a quick release because it's a breaking issue. Every place where I18n.l() was used began to display the wrong date, causing test suite to fail.

------------------------------------------------------------------------------

## [v2.0](https://github.com/faker-ruby/faker/tree/v2.0) (2019-07-31)

## Important Note:

Version 2 has several `breaking changes`. We replaced positional arguments with keyword arguments and the list below contains all the changed methods:
- `Faker::Books::Dune.quote(character = nil)` becomes `Faker::Books::Dune.quote(character: nil)`
- `Faker::Books::Dune.saying(source = nil)` becomes `Faker::Books::Dune.saying(source: nil)`
- `Faker::Books::Lovecraft.fhtagn(number_of = nil)` becomes `Faker::Books::Lovecraft.fhtagn(number: nil)`
- `Faker::Books::Lovecraft.paragraph(sentence_count = nil, random_sentences_to_add = nil)` becomes `Faker::Books::Lovecraft.paragraph(sentence_count: nil, random_sentences_to_add: nil)`
- `Faker::Books::Lovecraft.paragraph_by_chars(chars = nil)` becomes `Faker::Books::Lovecraft.paragraph_by_chars(characters: nil)`
- `Faker::Books::Lovecraft.paragraphs(paragraph_count = nil)` becomes `Faker::Books::Lovecraft.paragraphs(number: nil)`
- `Faker::Books::Lovecraft.sentence(word_count = nil, random_words_to_add = nil)` becomes `Faker::Books::Lovecraft.sentence(word_count: nil, random_words_to_add: nil)`
- `Faker::Books::Lovecraft.sentences(sentence_count = nil)` becomes `Faker::Books::Lovecraft.sentences(number: nil)`
- `Faker::Books::Lovecraft.words(num = nil, spaces_allowed = nil)` becomes `Faker::Books::Lovecraft.words(number: nil, spaces_allowed: nil)`
- `Faker::Address.city(options = nil)` becomes `Faker::Address.city(options: nil)`
- `Faker::Address.postcode(state_abbreviation = nil)` becomes `Faker::Address.postcode(state_abbreviation: nil)`
- `Faker::Address.street_address(include_secondary = nil)` becomes `Faker::Address.street_address(include_secondary: nil)`
- `Faker::Address.zip(state_abbreviation = nil)` becomes `Faker::Address.zip(state_abbreviation: nil)`
- `Faker::Address.zip_code(state_abbreviation = nil)` becomes `Faker::Address.zip_code(state_abbreviation: nil)`
- `Faker::Alphanumeric.alpha(char_count = nil)` becomes `Faker::Alphanumeric.alpha(number: nil)`
- `Faker::Alphanumeric.alphanumeric(char_count = nil)` becomes `Faker::Alphanumeric.alphanumeric(number: nil)`
- `Faker::Avatar.image(slug = nil, size = nil, format = nil, set = nil, bgset = nil)` becomes `Faker::Avatar.image(slug: nil, size: nil, format: nil, set: nil, bgset: nil)`
- `Faker::Bank.account_number(digits = nil)` becomes `Faker::Bank.account_number(digits: nil)`
- `Faker::Bank.iban(country_code = nil)` becomes `Faker::Bank.iban(country_code: nil)`
- `Faker::ChileRut.full_rut(min_rut = nil, fixed = nil)` becomes `Faker::ChileRut.full_rut(min_rut: nil, fixed: nil)`
- `Faker::ChileRut.rut(min_rut = nil, fixed = nil)` becomes `Faker::ChileRut.rut(min_rut: nil, fixed: nil)`
- `Faker::Code.ean(base = nil)` becomes `Faker::Code.ean(base: nil)`
- `Faker::Code.isbn(base = nil)` becomes `Faker::Code.isbn(base: nil)`
- `Faker::Code.nric(min_age = nil, max_age = nil)` becomes `Faker::Code.nric(min_age: nil, max_age: nil)`
- `Faker::Commerce.department(max = nil, fixed_amount = nil)` becomes `Faker::Commerce.department(max: nil, fixed_amount: nil)`
- `Faker::Commerce.price(range = nil, as_string = nil)` becomes `Faker::Commerce.price(range: nil, as_string: nil)`
- `Faker::Commerce.promotion_code(digits = nil)` becomes `Faker::Commerce.promotion_code(digits: nil)`
- `Faker::Company.polish_register_of_national_economy(length = nil)` becomes `Faker::Company.polish_register_of_national_economy(length: nil)`
- `Faker::CryptoCoin.acronym(coin = nil)` becomes `Faker::CryptoCoin.acronym(coin: nil)`
- `Faker::CryptoCoin.coin_name(coin = nil)` becomes `Faker::CryptoCoin.coin_name(coin: nil)`
- `Faker::CryptoCoin.url_logo(coin = nil)` becomes `Faker::CryptoCoin.url_logo(coin: nil)`
- `Faker::Date.backward(days = nil)` becomes `Faker::Date.backward(days: nil)`
- `Faker::Date.between(from, to)` becomes `Faker::Date.between(from:, to:)`
- `Faker::Date.between_except(from, to, excepted)` becomes `Faker::Date.between_except(from:, to:, excepted:)`
- `Faker::Date.birthday(min_age = nil, max_age = nil)` becomes `Faker::Date.birthday(min_age: nil, max_age: nil)`
- `Faker::Date.forward(days = nil)` becomes `Faker::Date.forward(days: nil)`
- `Faker::Demographic.height(unit = nil)` becomes `Faker::Demographic.height(unit: nil)`
- `Faker::File.dir(segment_count = nil, root = nil, directory_separator = nil)` becomes `Faker::File.dir(segment_count: nil, root: nil, directory_separator: nil)`
- `Faker::File.file_name(dir = nil, name = nil, ext = nil, directory_separator = nil)` becomes `Faker::File.file_name(dir: nil, name: nil, ext: nil, directory_separator: nil)`
- `Faker::Fillmurray.image(grayscale = nil, width = nil, height = nil)` becomes `Faker::Fillmurray.image(grayscale: nil, width: nil, height: nil)`
- `Faker::Finance.vat_number(country = nil)` becomes `Faker::Finance.vat_number(country: nil)`
- `Faker::Hipster.paragraph(sentence_count = nil, supplemental = nil, random_sentences_to_add = nil)` becomes `Faker::Hipster.paragraph(sentence_count: nil, supplemental: nil, random_sentences_to_add: nil)`
- `Faker::Hipster.paragraph_by_chars(chars = nil, supplemental = nil)` becomes `Faker::Hipster.paragraph_by_chars(characters: nil, supplemental: nil)`
- `Faker::Hipster.paragraphs(paragraph_count = nil, supplemental = nil)` becomes `Faker::Hipster.paragraphs(number: nil, supplemental: nil)`
- `Faker::Hipster.sentence(word_count = nil, supplemental = nil, random_words_to_add = nil)` becomes `Faker::Hipster.sentence(word_count: nil, supplemental: nil, random_words_to_add: nil)`
- `Faker::Hipster.sentences(sentence_count = nil, supplemental = nil)` becomes `Faker::Hipster.sentences(number: nil, supplemental: nil)`
- `Faker::Hipster.words(num = nil, supplemental = nil, spaces_allowed = nil)` becomes `Faker::Hipster.words(number: nil, supplemental: nil, spaces_allowed: nil)`
- `Faker::Internet.domain_name(subdomain = nil)` becomes `Faker::Internet.domain_name(subdomain: nil)`
- `Faker::Internet.email(name = nil, *separators)` becomes `Faker::Internet.email(name: nil, separators: nil)`
- `Faker::Internet.fix_umlauts(string = nil)` becomes `Faker::Internet.fix_umlauts(string: nil)`
- `Faker::Internet.free_email(name = nil)` becomes `Faker::Internet.free_email(name: nil)`
- `Faker::Internet.mac_address(prefix = nil)` becomes `Faker::Internet.mac_address(prefix: nil)`
- `Faker::Internet.password(min_length = nil, max_length = nil, mix_case = nil, special_chars = nil)` becomes `Faker::Internet.password(min_length: nil, max_length: nil, mix_case: nil, special_characters: nil)`
- `Faker::Internet.safe_email(name = nil)` becomes `Faker::Internet.safe_email(name: nil)`
- `Faker::Internet.slug(words = nil, glue = nil)` becomes `Faker::Internet.slug(words: nil, glue: nil)`
- `Faker::Internet.url(host = nil, path = nil, scheme = nil)` becomes `Faker::Internet.url(host: nil, path: nil, scheme: nil)`
- `Faker::Internet.user_agent(vendor = nil)` becomes `Faker::Internet.user_agent(vendor: nil)`
- `Faker::Internet.user_name(specifier = nil, separators = nil)` becomes `Faker::Internet.user_name(specifier: nil, separators: nil)`
- `Faker::Internet.username(specifier = nil, separators = nil)` becomes `Faker::Internet.username(specifier: nil, separators: nil)`
- `Faker::Invoice.amount_between(from = nil, to = nil)` becomes `Faker::Invoice.amount_between(from: nil, to: nil)`
- `Faker::Invoice.creditor_reference(ref = nil)` becomes `Faker::Invoice.creditor_reference(ref: nil)`
- `Faker::Invoice.reference(ref = nil)` becomes `Faker::Invoice.reference(ref: nil)`
- `Faker::Json.add_depth_to_json(json = nil, width = nil, options = nil)` becomes `Faker::Json.add_depth_to_json(json: nil, width: nil, options: nil)`
- `Faker::Json.shallow_json(width = nil, options = nil)` becomes `Faker::Json.shallow_json(width: nil, options: nil)`
- `Faker::Lorem.characters(char_count = nil)` becomes `Faker::Lorem.characters(number: nil)`
- `Faker::Lorem.paragraph(sentence_count = nil, supplemental = nil, random_sentences_to_add = nil)` becomes `Faker::Lorem.paragraph(sentence_count: nil, supplemental: nil, random_sentences_to_add: nil)`
- `Faker::Lorem.paragraph_by_chars(chars = nil, supplemental = nil)` becomes `Faker::Lorem.paragraph_by_chars(number: nil, supplemental: nil)`
- `Faker::Lorem.paragraphs(paragraph_count = nil, supplemental = nil)` becomes `Faker::Lorem.paragraphs(number: nil, supplemental: nil)`
- `Faker::Lorem.question(word_count = nil, supplemental = nil, random_words_to_add = nil)` becomes `Faker::Lorem.question(word_count: nil, supplemental: nil, random_words_to_add: nil)`
- `Faker::Lorem.questions(question_count = nil, supplemental = nil)` becomes `Faker::Lorem.questions(number: nil, supplemental: nil)`
- `Faker::Lorem.sentence(word_count = nil, supplemental = nil, random_words_to_add = nil)` becomes `Faker::Lorem.sentence(word_count: nil, supplemental: nil, random_words_to_add: nil)`
- `Faker::Lorem.sentences(sentence_count = nil, supplemental = nil)` becomes `Faker::Lorem.sentences(number: nil, supplemental: nil)`
- `Faker::Lorem.words(num = nil, supplemental = nil)` becomes `Faker::Lorem.words(number: nil, supplemental: nil)`
- `Faker::LoremFlickr.colorized_image(size = nil, color = nil, search_terms = nil, match_all = nil)` becomes `Faker::LoremFlickr.colorized_image(size: nil, color: nil, search_terms: nil, match_all: nil)`
- `Faker::LoremFlickr.grayscale_image(size = nil, search_terms = nil, match_all = nil)` becomes `Faker::LoremFlickr.grayscale_image(size: nil, search_terms: nil, match_all: nil)`
- `Faker::LoremFlickr.image(size = nil, search_terms = nil, match_all = nil)` becomes `Faker::LoremFlickr.image(size: nil, search_terms: nil, match_all: nil)`
- `Faker::LoremFlickr.pixelated_image(size = nil, search_terms = nil, match_all = nil)` becomes `Faker::LoremFlickr.pixelated_image(size: nil, search_terms: nil, match_all: nil)`
- `Faker::LoremPixel.image(size = nil, is_gray = nil, category = nil, number = nil, text = nil, secure: nil)` becomes `Faker::LoremPixel.image(size: nil, is_gray: nil, category: nil, number: nil, text: nil, secure: nil)`
- `Faker::Markdown.sandwich(sentences = nil, repeat = nil)` becomes `Faker::Markdown.sandwich(sentences: nil, repeat: nil)`
- `Faker::Measurement.height(amount = nil)` becomes `Faker::Measurement.height(amount: nil)`
- `Faker::Measurement.length(amount = nil)` becomes `Faker::Measurement.length(amount: nil)`
- `Faker::Measurement.metric_height(amount = nil)` becomes `Faker::Measurement.metric_height(amount: nil)`
- `Faker::Measurement.metric_length(amount = nil)` becomes `Faker::Measurement.metric_length(amount: nil)`
- `Faker::Measurement.metric_volume(amount = nil)` becomes `Faker::Measurement.metric_volume(amount: nil)`
- `Faker::Measurement.metric_weight(amount = nil)` becomes `Faker::Measurement.metric_weight(amount: nil)`
- `Faker::Measurement.volume(amount = nil)` becomes `Faker::Measurement.volume(amount: nil)`
- `Faker::Measurement.weight(amount = nil)` becomes `Faker::Measurement.weight(amount: nil)`
- `Faker::Name.initials(character_count = nil)` becomes `Faker::Name.initials(number: nil)`
- `Faker::NationalHealthService.check_digit(number = nil)` becomes `Faker::NationalHealthService.check_digit(number: nil)`
- `Faker::Number.between(from = nil, to = nil)` becomes `Faker::Number.between(from: nil, to: nil)`
- `Faker::Number.decimal(l_digits = nil, r_digits = nil)` becomes `Faker::Number.decimal(l_digits: nil, r_digits: nil)`
- `Faker::Number.decimal_part(*args, &block)` becomes `Faker::Number.decimal_part(digits: nil)`
- `Faker::Number.hexadecimal(digits = nil)` becomes `Faker::Number.hexadecimal(digits: nil)`
- `Faker::Number.leading_zero_number(*args, &block)` becomes `Faker::Number.leading_zero_number(digits: nil)`
- `Faker::Number.negative(from = nil, to = nil)` becomes `Faker::Number.negative(from: nil, to: nil)`
- `Faker::Number.normal(mean = nil, standard_deviation = nil)` becomes `Faker::Number.normal(mean: nil, standard_deviation: nil)`
- `Faker::Number.number(digits = nil)` becomes `Faker::Number.number(digits: nil)`
- `Faker::Number.positive(from = nil, to = nil)` becomes `Faker::Number.positive(from: nil, to: nil)`
- `Faker::Number.within(range = nil)` becomes `Faker::Number.within(range: nil)`
- `Faker::PhoneNumber.extension(length = nil)` becomes `Faker::PhoneNumber.extension(length: nil)`
- `Faker::PhoneNumber.subscriber_number(length = nil)` becomes `Faker::PhoneNumber.subscriber_number(length: nil)`
- `Faker::Placeholdit.image(size = nil, format = nil, background_color = nil, text_color = nil, text = nil)` becomes `Faker::Placeholdit.image(size: nil, format: nil, background_color: nil, text_color: nil, text: nil)`
- `Faker::Relationship.familial(connection = nil)` becomes `Faker::Relationship.familial(connection: nil)`
- `Faker::Source.hello_world(lang = nil)` becomes `Faker::Source.hello_world(lang: nil)`
- `Faker::Source.print_1_to_10(lang = nil)` becomes `Faker::Source.print_1_to_10(lang: nil)`
- `Faker::String.random(length = nil)` becomes `Faker::String.random(length: nil)`
- `Faker::Stripe.ccv(card_type = nil)` becomes `Faker::Stripe.ccv(card_type: nil)`
- `Faker::Stripe.invalid_card(card_error = nil)` becomes `Faker::Stripe.invalid_card(card_error: nil)`
- `Faker::Stripe.valid_card(card_type = nil)` becomes `Faker::Stripe.valid_card(card_type: nil)`
- `Faker::Stripe.valid_token(card_type = nil)` becomes `Faker::Stripe.valid_token(card_type: nil)`
- `Faker::Time.backward(days = nil, period = nil, format = nil)` becomes `Faker::Time.backward(days: nil, period: nil, format: nil)`
- `Faker::Time.between(from, to, period = nil, format = nil)` becomes `Faker::Time.between(from:, to:, format: nil)`
- `Faker::Time.forward(days = nil, period = nil, format = nil)` becomes `Faker::Time.forward(days: nil, period: nil, format: nil)`
- `Faker::Types.complex_rb_hash(key_count = nil)` becomes `Faker::Types.complex_rb_hash(number: nil)`
- `Faker::Types.rb_array(len = nil)` becomes `Faker::Types.rb_array(len: nil)`
- `Faker::Types.rb_hash(key_count = nil, type = nil)` becomes `Faker::Types.rb_hash(number: nil, type: nil)`
- `Faker::Types.rb_integer(from = nil, to = nil)` becomes `Faker::Types.rb_integer(from: nil, to: nil)`
- `Faker::Types.rb_string(words = nil)` becomes `Faker::Types.rb_string(words: nil)`
- `Faker::Vehicle.kilometrage(min = nil, max = nil)` becomes `Faker::Vehicle.kilometrage(min: nil, max: nil)`
- `Faker::Vehicle.license_plate(state_abbreviation = nil)` becomes `Faker::Vehicle.license_plate(state_abbreviation: nil)`
- `Faker::Vehicle.mileage(min = nil, max = nil)` becomes `Faker::Vehicle.mileage(min: nil, max: nil)`
- `Faker::Vehicle.model(make_of_model = nil)` becomes `Faker::Vehicle.model(make_of_model: nil)`
- `Faker::WorldCup.group(group = nil)` becomes `Faker::WorldCup.group(group: nil)`
- `Faker::WorldCup.roster(country = nil, type = nil)` becomes `Faker::WorldCup.roster(country: nil, type: nil)`
- `Faker::Movies::StarWars.quote(character = nil)` becomes `Faker::Movies::StarWars.quote(character: nil)`

Additionally the following methods changed return values:

- `Faker::Number.number` now returns `Numeric` instead of `String` (see [PR #510](https://github.com/faker-ruby/faker/pull/510))

### Bug/Fixes

- [PR #1660](https://github.com/stympy/faker/pull/1660) Update FillMurray Links To Include www [@RaymondFallon](https://github.com/RaymondFallon)

### Deprecation

- [PR #1634](https://github.com/stympy/faker/pull/1634) Corrected other occurrences of spelling vehicle spelling error, deprecated Space launch_vehicule [@Siyanda](https://github.com/Siyanda)

### Documentation

- [PR #1653](https://github.com/stympy/faker/pull/1653) Add /faker-ruby/faker-bot to README [@vbrazo](https://github.com/vbrazo)

### Feature Request

- [PR #1417](https://github.com/stympy/faker/pull/1417) Rework Faker::Time::between [@pjohnmeyer](https://github.com/pjohnmeyer)
- [PR #510](https://github.com/stympy/faker/pull/510) Make Faker::Number return integers and floats instead of strings [@tejasbubane](https://github.com/tejasbubane)
- [PR #1651](https://github.com/stympy/faker/pull/1651) Preparing for v2 [@vbrazo](https://github.com/vbrazo)
- [PR #1664](https://github.com/stympy/faker/pull/1664) Replace positional arguments with keyword arguments [@vbrazo](https://github.com/vbrazo)

### Update/add locales

- [PR #1658](https://github.com/stympy/faker/pull/1658) Update Faker::Games::SuperSmashBros entries [@boardfish](https://github.com/boardfish)
- [PR #1649](https://github.com/stympy/faker/pull/1649) Remove mexicoMX [@vbrazo](https://github.com/vbrazo)

------------------------------------------------------------------------------

## [v1.9.6](https://github.com/stympy/faker/tree/1.9.6) (2019-07-05)

Fix lib/faker/version.rb

## [v1.9.5](https://github.com/stympy/faker/tree/v.1.9.5) (2019-07-04)

### Bug

- [PR #1644](https://github.com/stympy/faker/pull/1644) Revert fakerbot and move to own repository inside new organization [@vbrazo](https://github.com/vbrazo)

### Deprecate

- [PR #1516](https://github.com/stympy/faker/pull/1516) Deprecate Faker::Number.decimal_part and Faker::Number.leading_zero_number [@vbrazo](https://github.com/vbrazo)

### Documentation

- [PR #1640](https://github.com/stympy/faker/pull/1640) Add pull_request_template.md [@vbrazo](https://github.com/vbrazo)

### Feature Request

- [PR #1361](https://github.com/stympy/faker/pull/1361) Add Faker::File.dir [@tylerhunt](https://github.com/tylerhunt)

### Update Locales

- [PR #1643](https://github.com/stympy/faker/pull/1643) Add 558 Verb ing_forms from Verb base [@lightyrs](https://github.com/lightyrs)

------------------------------------------------------------------------------

## [v1.9.4](https://github.com/stympy/faker/tree/1.9.4) (2019-06-19)

### Bug/Fixes

- [PR #1605](https://github.com/stympy/faker/pull/1605) fix shallow_json for frozen_string_literal [@causztic](https://github.com/causztic)
- [PR #1597](https://github.com/stympy/faker/pull/1597) Fix broken test [@vbrazo](https://github.com/vbrazo)
- [PR #1578](https://github.com/stympy/faker/pull/1578) Namespaces should inherit Base [@vbrazo](https://github.com/vbrazo)

### Chores

- [PR #1626](https://github.com/stympy/faker/pull/1626) Update tty tree [@Zeragamba](https://github.com/Zeragamba)
- [PR #1559](https://github.com/stympy/faker/pull/1559) Fix name_with_middle field for en-AU [@psibi](https://github.com/psibi)
- [PR #1548](https://github.com/stympy/faker/pull/1548) Chore/improve pt-BR specs [@paulodiovani](https://github.com/paulodiovani)
- [PR #1542](https://github.com/stympy/faker/pull/1542) Fixed typos to the unreleased_README.md [@gkunwar](https://github.com/gkunwar)
- [PR #1541](https://github.com/stympy/faker/pull/1541) Add new categories to armenian [@hovikman](https://github.com/hovikman)

### Deprecation

- [PR #1549](https://github.com/stympy/faker/pull/1549) Faker::Movies::GratefulDead => Faker::Music::GratefulDead [@bcharna](https://github.com/bcharna)
- [PR #1538](https://github.com/stympy/faker/pull/1538) Add Sports namespace [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::Football`

### Documentation

- [PR #1636](https://github.com/stympy/faker/pull/1636) Fix default values for arguments in Lorem doc [@mikong](https://github.com/mikong)
- [PR #1617](https://github.com/stympy/faker/pull/1617) Fix Dota README [@TheSmartnik](https://github.com/TheSmartnik)
- [PR #1612](https://github.com/stympy/faker/pull/1612) Update returned example player [@ncallaway](https://github.com/ncallaway)
- [PR #1611](https://github.com/stympy/faker/pull/1611) Documentation error fix [@tomlockwood](https://github.com/tomlockwood)
- [PR #1575](https://github.com/stympy/faker/pull/1575) Add issues templates [@vbrazo](https://github.com/vbrazo)

### Feature Request

- [PR #1631](https://github.com/stympy/faker/pull/1631) Faker::Tezos: add block faker [@akettal](https://github.com/akettal)
- [PR #1619](https://github.com/stympy/faker/pull/1619) Add Faker::Music::Opera [@Adsidera](https://github.com/Adsidera)
- [PR #1607](https://github.com/stympy/faker/pull/1607) Add Faker::Game with title, genre, and platform generators. [@connorshea](https://github.com/connorshea)
- [PR #1603](https://github.com/stympy/faker/pull/1603) Add Faker::Internet.uuid [@ianks](https://github.com/ianks)
- [PR #1560](https://github.com/stympy/faker/pull/1560) Add Faker::Creature::Horse [@wndxlori](https://github.com/wndxlori)
- [PR #1507](https://github.com/stympy/faker/pull/1507) Add CLI - Integrate fakerbot 🤖 [@akabiru](https://github.com/akabiru)
- [PR #1540](https://github.com/stympy/faker/pull/1540) Add sic_code to company #355 [@bruno-b-martins](https://github.com/bruno-b-martins)
- [PR #1537](https://github.com/stympy/faker/pull/1537) Adds the Faker::Sports::Basketball generator [@ecbrodie](https://github.com/ecbrodie)
- [PR #1520](https://github.com/stympy/faker/pull/1520) Allow subdomains for Internet.domain_name [@cianooooo](https://github.com/cianooooo)

### Update/add locales

- [PR #1629](https://github.com/stympy/faker/pull/1629) Fix syntax error on game.yml file [@ricardobsilva](https://github.com/ricardobsilva)
- [PR #1627](https://github.com/stympy/faker/pull/1627) add more data for Faker::Games [@BlazingRockStorm](https://github.com/BlazingRockStorm)
- [PR #1620](https://github.com/stympy/faker/pull/1620) Added Yuumi as a Champion [@eddorre](https://github.com/eddorre)
- [PR #1621](https://github.com/stympy/faker/pull/1621) Updated classes to match the changes that Blizzard rolled out late last year. Updated hero pool to add the latest two heroes added to the game. [@eddorre](https://github.com/eddorre)
- [PR #1602](https://github.com/stympy/faker/pull/1602) Remove white space, fix minor typos [@darylf](https://github.com/darylf)
- [PR #1595](https://github.com/stympy/faker/pull/1595) Fix accented French surnames [@Samy-Amar](https://github.com/Samy-Amar)
- [PR #1585](https://github.com/stympy/faker/pull/1585) Add Meepo to Dota heroes and quotes [@justinoue](https://github.com/justinoue)
- [PR #1594](https://github.com/stympy/faker/pull/1594) Changed Startrek to Stargate :) [@Defoncesko](https://github.com/Defoncesko)
- [PR #1591](https://github.com/stympy/faker/pull/1591) fix-chinese-city [@locez](https://github.com/locez)
- [PR #1592](https://github.com/stympy/faker/pull/1592) Add coffee country for Japanese [@schmurfy](https://github.com/schmurfy)
- [PR #1593](https://github.com/stympy/faker/pull/1593) removes duplicates in fr-CA and fr-CH [@schmurfy](https://github.com/schmurfy)
- [PR #1587](https://github.com/stympy/faker/pull/1587) Add ancient god for Japanese [@yizknn](https://github.com/yizknn)
- [PR #1582](https://github.com/stympy/faker/pull/1582) Add fighters and DLC to Faker::Games::SuperSmashBros [@boardfish](https://github.com/boardfish)
- [PR #1583](https://github.com/stympy/faker/pull/1583) updates to RuPaul [@notactuallypagemcconnell](https://github.com/notactuallypagemcconnell)
- [PR #1581](https://github.com/stympy/faker/pull/1581) add latest list of phish tunes from phish.net/song that are by the band and not covers  [@notactuallypagemcconnell](https://github.com/notactuallypagemcconnell)
- [PR #1573](https://github.com/stympy/faker/pull/1573) Fix data of music albums [@sankichi92](https://github.com/sankichi92)
- [PR #1567](https://github.com/stympy/faker/pull/1567) Fix name_with_middle in Chinese locales [@rockymeza](https://github.com/rockymeza)
- [PR #1564](https://github.com/stympy/faker/pull/1564) Update League of legends content [@michebble](https://github.com/michebble)
- [PR #1558](https://github.com/stympy/faker/pull/1558) remove misspelling of Japanese [@michebble](https://github.com/michebble)
- [PR #1554](https://github.com/stympy/faker/pull/1554) Extend list of cryptocurrencies [@kamilbielawski](https://github.com/kamilbielawski)
- [PR #1552](https://github.com/stympy/faker/pull/1552) Fix subscription: Fix missing double quotes [@psibi](https://github.com/psibi)
- [PR #1551](https://github.com/stympy/faker/pull/1551) Yaml syntax for stargate.yml: Fix missing double quote [@psibi](https://github.com/psibi)
- [PR #1550](https://github.com/stympy/faker/pull/1550) Fix kpop - yaml syntax issue. Double quote is missing [@psibi](https://github.com/psibi)
- [PR #1545](https://github.com/stympy/faker/pull/1545) Remove trailing space from "kangaroo " & "gnu " translation in animals [@spikeheap](https://github.com/spikeheap)
- [PR #1543](https://github.com/stympy/faker/pull/1543) Add pt-BR genders [@fladson](https://github.com/fladson)

------------------------------------------------------------------------------

## [v1.9.3](https://github.com/stympy/faker/tree/v1.9.3) (2019-02-12)

[Full Changelog](https://github.com/stympy/faker/compare/v1.9.2...v1.9.3)

### Bug/Fixes

- [PR #1535](https://github.com/stympy/faker/pull/1535) Fix I18n bug [@vbrazo](https://github.com/vbrazo)

------------------------------------------------------------------------------

## [v1.9.2](https://github.com/stympy/faker/tree/v1.9.2) (2019-02-11)
[Full Changelog](https://github.com/stympy/faker/compare/v1.9.1...v1.9.2)

### Bug/Fixes
- [PR #1512](https://github.com/stympy/faker/pull/1512) Fix numerical part of Dutch postcode [@tilsammans](https://github.com/tilsammans)
- [PR #1477](https://github.com/stympy/faker/pull/1477) Fixed bank account length [@jguthrie100](https://github.com/jguthrie100)
- [PR #1494](https://github.com/stympy/faker/pull/1494) Fix Faker::Internet.ip_v4_address to include all IP ranges [@lucasqueiroz](https://github.com/lucasqueiroz)
- [PR #1456](https://github.com/stympy/faker/pull/1456) fix: omit . from slug [@ivanoblomov](https://github.com/ivanoblomov)
- [PR #1436](https://github.com/stympy/faker/pull/1436) Fix regex and add magic string to pass RuboCop check [@jakrzus](https://github.com/jakrzus)
- [PR #1425](https://github.com/stympy/faker/pull/1425) NHS: fix occasional bad numbers [@ChaoticBoredom](https://github.com/ChaoticBoredom)
- [PR #1421](https://github.com/stympy/faker/pull/1421) Faker::Internet.user_name can't handle UTF-8 arguments [@ivanoblomov](https://github.com/ivanoblomov)
- [PR #1423](https://github.com/stympy/faker/pull/1423) Add missing locale tests - Part II [@vbrazo](https://github.com/vbrazo)
- [PR #1389](https://github.com/stympy/faker/pull/1389) Load faker I18n using custom backend chaining [@pjohnmeyer](https://github.com/pjohnmeyer)
- [PR #1384](https://github.com/stympy/faker/pull/1384) Quick number method bugfix [@vbrazo](https://github.com/vbrazo)
- [PR #1377](https://github.com/stympy/faker/pull/1377) Fallback translation without available locales enforcement [@deivid-rodriguez](https://github.com/deivid-rodriguez)
- [PR #1368](https://github.com/stympy/faker/pull/1368) Don't force enforce_available_locales [@deivid-rodriguez](https://github.com/deivid-rodriguez)
- [PR #1355](https://github.com/stympy/faker/pull/1355) Fix global clear of unique values for Faker::UniqueGenerator [@kolasss](https://github.com/kolasss)
- [PR #1335](https://github.com/stympy/faker/pull/1335) Fix Company.luhn_algorithm and add missing tests [@01max](https://github.com/01max)
- [PR #1334](https://github.com/stympy/faker/pull/1334) Faker::Number.leading_zero_number should always start with 0 [@vbrazo](https://github.com/vbrazo)
- [PR #1317](https://github.com/stympy/faker/pull/1317) Change Faker::Lorem.multibyte logic [@ShabelnikM](https://github.com/ShabelnikM)
- [PR #527](https://github.com/stympy/faker/pull/527) Fix time period test that could result in a flake test within 15 days [@melonhead901](https://github.com/melonhead901)
- [PR #1310](https://github.com/stympy/faker/pull/1310) Add alias for middle_name and remove locale [@vbrazo](https://github.com/vbrazo)

### Chores
- [PR #1496](https://github.com/stympy/faker/pull/1496) Update yaml format in docs [@SpyMaster356](https://github.com/SpyMaster356)
- [PR #1508](https://github.com/stympy/faker/pull/1508) Changes before release [@vbrazo](https://github.com/vbrazo)
- [PR #1490](https://github.com/stympy/faker/pull/1490) Add missing Faker::HeroesOfTheStorm tests [@vbrazo](https://github.com/vbrazo)
- [PR #1457](https://github.com/stympy/faker/pull/1457) Add tests for new Faker::Internet.slug glue [@vbrazo](https://github.com/vbrazo)
- [PR #1434](https://github.com/stympy/faker/pull/1434) Add keyword argument to Faker::Games::Dota.quote [@vbrazo](https://github.com/vbrazo)
- [PR #1420](https://github.com/stympy/faker/pull/1420) Add Faker::JapaneseMedia namespace [@boardfish](https://github.com/boardfish)
- [PR #1411](https://github.com/stympy/faker/pull/1411) Add several missing locales [@vbrazo](https://github.com/vbrazo)
- [PR #1403](https://github.com/stympy/faker/pull/1403) Faker::SouthPark => Faker::Movies::SouthPark [@vbrazo](https://github.com/vbrazo)
- [PR #1401](https://github.com/stympy/faker/pull/1401) Faker::GratefulDead => Faker::Movies::GratefulDead [@vbrazo](https://github.com/vbrazo)
- [PR #1362](https://github.com/stympy/faker/pull/1362) Faker::Types minor cleanup [@stephengroat](https://github.com/stephengroat)
- [PR #1347](https://github.com/stympy/faker/pull/1347) Remove launchy dependency [@vbrazo](https://github.com/vbrazo)
- [PR #1311](https://github.com/stympy/faker/pull/1311) Target Ruby 2.3 [@tagliala](https://github.com/tagliala)
- [PR #372](https://github.com/stympy/faker/pull/372) Add test_password_could_achieve_max_length [@oleksii-ti](https://github.com/oleksii-ti)

### Deprecation
- [PR #1504](https://github.com/stympy/faker/pull/1504) Add Quotes namespace [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::FamousLastWords`, `::Matz`, `::MostInterestingManInTheWorld`, `::Robin`, `::Shakespeare`, `::SingularSiegler`, `::Yoda`
- [PR #1503](https://github.com/stympy/faker/pull/1503) Add Books namespace [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::Dune`, `Lovecraft`
- [PR #1480](https://github.com/stympy/faker/pull/1480) Add Music, Movies and TvShows namespaces [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::Hobbit`, `HitchhikersGuideToTheGalaxy`, `::HarryPotter`, `::RockBand`, `::MichaelScott`, `::RuPaul`
- [PR #1481](https://github.com/stympy/faker/pull/1481) Add Blockchain namespace [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::Bitcoin`, `::Ethereum`, `::Tezos`
- [PR #1471](https://github.com/stympy/faker/pull/1471) Add music and movies namespace [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::BackToTheFuture`, `::Lebowski`, `::LordOfTheRings`, `::PrincessBride`, `::StarWars`, `::UmphreysMcgee`, `::VForVendetta`
- [PR #1469](https://github.com/stympy/faker/pull/1469) Deprecate Faker::Hobbit and reorganize unreleased docs and tests [@vbrazo](https://github.com/vbrazo)
  - Deprecates `::Hobbit`
- [PR #1431](https://github.com/stympy/faker/pull/1431) Add Faker::TvShows namespace [@SpyMaster356](https://github.com/SpyMaster356)
  - Deprecates `::AquaTeenHungerForce`, `::BojackHorseman`, `::BreakingBad`, `::Buffy`, `::Community`, `::DrWho`, `::DumbAndDumber`, `::FamilyGuy`, `::Friends`, `::GameOfThrones`, `::HeyArnold`, `::HowIMetYourMother`, `::NewGirl`, `::ParksAndRec`, `::RickAndMorty`, `::Seinfeld`, `::SiliconValley`, `::Simpsons`, `::SouthPark`, `::StarTrek`, `::Stargate`, `::StrangerThings`, `::TheFreshPrinceOfBelAir`, `::TheITCrowd`, `::TheThickOfIt`, `::TwinPeaks`, `::VentureBros`
- [PR #1412](https://github.com/stympy/faker/pull/1412) Add Faker::Games namespace [@ChaoticBoredom](https://github.com/ChaoticBoredom)
  - Deprecates `::Dota`, `::ElderScrolls`, `::Fallout`, `::LeagueOfLegends`, `::Myst`, `::Overwatch`, `::Pokemon`, `::Witcher`, `::WorldOfWarcraft` and `::Zelda`
- [PR #1424](https://github.com/stympy/faker/pull/1424) Add Faker::Creature namespace [@ChaoticBoredom](https://github.com/ChaoticBoredom)
  - Deprecates `::Cat` and `::Dog`
- [PR #1420](https://github.com/stympy/faker/pull/1420) Add Faker::JapaneseMedia namespace [@boardfish](https://github.com/boardfish)
  - Deprecates `::DragonBall`, `::OnePiece` and `::SwordArtOnline`
- [PR #803](https://github.com/stympy/faker/pull/803) Modify Faker::Educator, Fix #576 [@ghbooth12](https://github.com/ghbooth12)

### Documentation
- [PR #1513](https://github.com/stympy/faker/pull/1513) Fix typo in Faker::Code documentation [@iox](https://github.com/iox)
- [PR #1497](https://github.com/stympy/faker/pull/1497) add TV Shows to table of contents [@SpyMaster356](https://github.com/SpyMaster356)
- [PR #1488](https://github.com/stympy/faker/pull/1488) Fix unreleased docs [@vbrazo](https://github.com/vbrazo)
- [PR #1462](https://github.com/stympy/faker/pull/1462) Fix documentation on Faker::Avatar [@mrstebo](https://github.com/mrstebo)
- [PR #1445](https://github.com/stympy/faker/pull/1445) Separate README.md: unreleased and latest version [@vbrazo](https://github.com/vbrazo)
- [PR #1243](https://github.com/stympy/faker/pull/1243) Add image file method to placeholdit [@nicolas-brousse](https://github.com/nicolas-brousse)
- [PR #1419](https://github.com/stympy/faker/pull/1419) Update CONTRIBUTING.md [@vbrazo](https://github.com/vbrazo)
- [PR #1414](https://github.com/stympy/faker/pull/1414) Fixing spelling mistake in Docs for Vehicle [@snoozins](https://github.com/snoozins)
- [PR #1408](https://github.com/stympy/faker/pull/1408) Add Verbs example to README [@matheusteixeira](https://github.com/matheusteixeira)
- [PR #1380](https://github.com/stympy/faker/pull/1380) Update year in License.txt [@dnamsons](https://github.com/dnamsons)
- [PR #1364](https://github.com/stympy/faker/pull/1364) Update readme for Faker::Code to fix typo [@matt297](https://github.com/matt297)
- [PR #1360](https://github.com/stympy/faker/pull/1360) added sushi and sorted by word [@yizknn](https://github.com/yizknn)
- [PR #1357](https://github.com/stympy/faker/pull/1357) Fix South Africa documentation [@bradleymarques](https://github.com/bradleymarques)
- [PR #1354](https://github.com/stympy/faker/pull/1354) Update docs for Lorem [@softwaregravy](https://github.com/softwaregravy)
- [PR #1353](https://github.com/stympy/faker/pull/1353) Update documentation for Faker::Number [@softwaregravy](https://github.com/softwaregravy)
- [PR #1329](https://github.com/stympy/faker/pull/1329) Update docs on behavior of price [@softwaregravy](https://github.com/softwaregravy)

### Feature Request
- [PR #1493](https://github.com/stympy/faker/pull/1493) Add Faker::Books::CultureSeries [@richardbulger](https://github.com/richardbulger)
- [PR #1489](https://github.com/stympy/faker/pull/1489) Format brazilian_company_number and brazilian_citizen_number [@jpkarvonen](https://github.com/jpkarvonen)
- [PR #1487](https://github.com/stympy/faker/pull/1487) Add Faker::TvShows::TheExpanse [@jpkarvonen](https://github.com/jpkarvonen)
- [PR #1475](https://github.com/stympy/faker/pull/1475) Adds Faker::Nation.flag [@JonathanWThom](https://github.com/JonathanWThom)
- [PR #1387](https://github.com/stympy/faker/pull/1387) Add Faker::Music::Phish [@nbolser](https://github.com/nbolser)
- [PR #1430](https://github.com/stympy/faker/pull/1430) Adding Faker::Company.brazilian_company_number [@gabteles](https://github.com/gabteles)
- [PR #1449](https://github.com/stympy/faker/pull/1449) Add Faker::Coin [@jerryskye](https://github.com/jerryskye)
- [PR #1466](https://github.com/stympy/faker/pull/1466) Add Faker::Address.country_name_to_code(name: 'united_states') [@vbrazo](https://github.com/vbrazo)
- [PR #1465](https://github.com/stympy/faker/pull/1465) Add Faker.country(country_code: nil) [@vbrazo](https://github.com/vbrazo)
- [PR #1460](https://github.com/stympy/faker/pull/1460) Add Faker::Marketing [@susiirwin](https://github.com/susiirwin)
- [PR #1451](https://github.com/stympy/faker/pull/1451) Add first name 'Simão' and title prefix to 'Eng.' [@jellyfunk](https://github.com/jellyfunk)
- [PR #1433](https://github.com/stympy/faker/pull/1433) Add Faker::DrivingLicence [@jellyfunk](https://github.com/jellyfunk)
- [PR #1440](https://github.com/stympy/faker/pull/1440) Add Faker::Subscription [@fabersky](https://github.com/fabersky)
- [PR #1438](https://github.com/stympy/faker/pull/1438) Add Faker::Football.position [@fblupi](https://github.com/fblupi)
- [PR #1426](https://github.com/stympy/faker/pull/1426) Add Faker::PhoneNumber.country_code [@AmrAdelKhalil](https://github.com/AmrAdelKhalil)
- [PR #1427](https://github.com/stympy/faker/pull/1427) Add Faker::Games::SuperSmashBros [@boardfish](https://github.com/boardfish)
- [PR #1410](https://github.com/stympy/faker/pull/1410) Add Faker::Vehicle.singapore_license_plate [@anonoz](https://github.com/anonoz)
- [PR #1422](https://github.com/stympy/faker/pull/1422) Add Faker::Games::SonicTheHedgehog [@boardfish](https://github.com/boardfish)
- [PR #1413](https://github.com/stympy/faker/pull/1413) Add Faker::Games::Heroes [@tangens](https://github.com/tangens)
- [PR #1409](https://github.com/stympy/faker/pull/1409) Add DC Comics titles [@matheusteixeira](https://github.com/matheusteixeira)
- [PR #1400](https://github.com/stympy/faker/pull/1400) Add Faker::Movies::Ghostbusters [@eddorre](https://github.com/eddorre)
- [PR #1399](https://github.com/stympy/faker/pull/1399) Add Faker::Games::HeroesOfTheStorm [@illsism](https://github.com/illsism)
- [PR #1396](https://github.com/stympy/faker/pull/1396) Add Faker::Creature::Animal [@molbrown](https://github.com/molbrown)
- [PR #1382](https://github.com/stympy/faker/pull/1382) Adding Faker::IDNumber.brazilian_citizen_number [@bschettino](https://github.com/bschettino)
- [PR #1062](https://github.com/stympy/faker/pull/1062) Markdown exclude method [@russellschmidt](https://github.com/russellschmidt)
- [PR #1381](https://github.com/stympy/faker/pull/1381) Add Faker::Games::HalfLife [@jthomp](https://github.com/jthomp)
- [PR #1374](https://github.com/stympy/faker/pull/1374) Add Faker::Beer.brand [@thalesap](https://github.com/thalesap)
- [PR #1302](https://github.com/stympy/faker/pull/1302) Add Faker::Alphanumeric [@mtancoigne](https://github.com/mtancoigne)
- [PR #1156](https://github.com/stympy/faker/pull/1156) Add Faker::Json [@the-wendell](https://github.com/the-wendell)
- [PR #1359](https://github.com/stympy/faker/pull/1359) Add Faker::Tezos [@Pierre-Michard](https://github.com/Pierre-Michard)
- [PR #1366](https://github.com/stympy/faker/pull/1366) Add Faker::Seinfeld.business [@dsgraham](https://github.com/dsgraham)
- [PR #1358](https://github.com/stympy/faker/pull/1358) Add cat breed for Japanese [@yizknn](https://github.com/yizknn)
- [PR #1365](https://github.com/stympy/faker/pull/1365) Add Faker::Number.within [@QuantumWaver](https://github.com/QuantumWaver)
- [PR #1336](https://github.com/stympy/faker/pull/1336) Implements and tests South African business registration numbers [@bradleymarques](https://github.com/bradleymarques)
- [PR #1346](https://github.com/stympy/faker/pull/1346) Add Faker::Relationship [@QuantumWaver](https://github.com/QuantumWaver)
- [PR #1348](https://github.com/stympy/faker/pull/1348) Add Faker::Finance.vat_number [@vbrazo](https://github.com/vbrazo)
- [PR #1342](https://github.com/stympy/faker/pull/1342) Added Faker::CryptoCoin scope [@jacksonpires](https://github.com/jacksonpires)
- [PR #1338](https://github.com/stympy/faker/pull/1338) Add new translations to the en-ZA locale [@bradleymarques](https://github.com/bradleymarques)
- [PR #1341](https://github.com/stympy/faker/pull/1341) Add Faker::Construction [@benwyrosdick](https://github.com/benwyrosdick)
- [PR #1130](https://github.com/stympy/faker/pull/1130) Faker::Vehicle API updates [@lucasqueiroz](https://github.com/lucasqueiroz)
- [PR #1324](https://github.com/stympy/faker/pull/1319) Add Faker::SouthAfrica [@bradleymarques](https://github.com/bradleymarques)
- [PR #1319](https://github.com/stympy/faker/pull/1319) Added Faker::DC Comics [@JoelLindow](https://github.com/JoelLindow)
- [PR #1320](https://github.com/stympy/faker/pull/1320) Add Faker::Buffy [@inveterateliterate](https://github.com/inveterateliterate)
- [PR #1148](https://github.com/stympy/faker/pull/1148) Adding Industry Segments Class [@cdesch](https://github.com/cdesch)
- [PR #893](https://github.com/stympy/faker/pull/893) Add Faker::ChileRut [@oxfist](https://github.com/oxfist)
- [PR #1315](https://github.com/stympy/faker/pull/1315) Add Faker::GratefulDead [@wileybaba](https://github.com/wileybaba)
- [PR #1314](https://github.com/stympy/faker/pull/1314) Add Faker::SouthPark [@saurabhudaniya200](https://github.com/saurabhudaniya200)
- [PR #1313](https://github.com/stympy/faker/pull/1313) Add Faker::Restaurant [@dwhitlow](https://github.com/dwhitlow)
- [PR #1307](https://github.com/stympy/faker/pull/1307) Add "exclude" method to UniqueGenerator [@mtancoigne](https://github.com/mtancoigne)
- [PR #1115](https://github.com/stympy/faker/pull/1115) Add Faker::Cosmere [@JauntyJames](https://github.com/JauntyJames)
- [PR #801](https://github.com/stympy/faker/pull/801) Add Faker::NHS - Support for the British National Health Service [@substrakt-health](https://github.com/substrakt-health)

### Suggestion
- [PR #1246](https://github.com/stympy/faker/pull/1246) Store list of generators with enabled uniqueness for faster clear [@MarcPer](https://github.com/MarcPer)

### Update/add locales
- [PR #1514](https://github.com/stympy/faker/pull/1514) Distinguish between 'brand' and 'name' [@iwaim](https://github.com/iwaim)
- [PR #1509](https://github.com/stympy/faker/pull/1509) Fix Faker::Address.country_by_code [@IlyasValiullov](https://github.com/IlyasValiullov)
- [PR #1492](https://github.com/stympy/faker/pull/1492) Fix abbreviation for Osten [@sonOfRa](https://github.com/sonOfRa)
- [PR #1499](https://github.com/stympy/faker/pull/1499) Adds some items on pt-BR locales seniority and education levels. And removes duplicated items from cities list. [@ramonlg](https://github.com/ramonlg)
- [PR #1501](https://github.com/stympy/faker/pull/1501) fix asajj_ventress alternate name [@ethan-dowler](https://github.com/ethan-dowler)
- [PR #1502](https://github.com/stympy/faker/pull/1502) Add support for Armenian language [@hovikman](https://github.com/hovikman)
- [PR #1486](https://github.com/stympy/faker/pull/1486) Added some professions in company.yml [@ReneIvanov](https://github.com/ReneIvanov)
- [PR #1474](https://github.com/stympy/faker/pull/1474) Fr format and translation [@maxime-lenne](https://github.com/maxime-lenne)
- [PR #1468](https://github.com/stympy/faker/pull/1468) Update "Black Pink" to "Blackpink" [@agungyuliaji](https://github.com/agungyuliaji)
- [PR #1464](https://github.com/stympy/faker/pull/1464) Add dog breed for Japanese [@yizknn](https://github.com/yizknn)
- [PR #1461](https://github.com/stympy/faker/pull/1461) Add Orphea to heroes of the storm locale file. [@eddorre](https://github.com/eddorre)
- [PR #1458](https://github.com/stympy/faker/pull/1458) Update Faker::DragonBall.characters locales [@JoaoHenriqueVale](https://github.com/JoaoHenriqueVale)
- [PR #1450](https://github.com/stympy/faker/pull/1450) Update device list and serial codes [@raresabr](https://github.com/raresabr)
- [PR #1443](https://github.com/stympy/faker/pull/1443) Add new array of cities from brazil [@WilliamCSA04](https://github.com/WilliamCSA04)
- [PR #1447](https://github.com/stympy/faker/pull/1447) Add Maroon 5 and Paramore to music [@Jcambass](https://github.com/Jcambass)
- [PR #1446](https://github.com/stympy/faker/pull/1446) fix: Remove deplicate 'color' from ja.yml [@yizknn](https://github.com/yizknn)
- [PR #1441](https://github.com/stympy/faker/pull/1441) Add Faker::Job pt-BR locales [@wellingtongvs](https://github.com/wellingtongvs)
- [PR #1428](https://github.com/stympy/faker/pull/1428) Add Faker::Games::SonicTheHedgehog.game [@boardfish](https://github.com/boardfish)
- [PR #1415](https://github.com/stympy/faker/pull/1415) Add new Overwatch items [@lucasqueiroz](https://github.com/lucasqueiroz)
- [PR #1407](https://github.com/stympy/faker/pull/1407) Add more data for Faker::Friends [@JIntrocaso](https://github.com/JIntrocaso)
- [PR #1402](https://github.com/stympy/faker/pull/1402) Update heroes_of_the_storm.yml [@eddorre](https://github.com/eddorre)
- [PR #1398](https://github.com/stympy/faker/pull/1398) Fix female_first_name and male_first_name [@vbrazo](https://github.com/vbrazo)
- [PR #1395](https://github.com/stympy/faker/pull/1395) Add middle_name to other locales [@vbrazo](https://github.com/vbrazo)
- [PR #1394](https://github.com/stympy/faker/pull/1394) Add name_with_middle - es locale and missing tests [@vbrazo](https://github.com/vbrazo)
- [PR #1393](https://github.com/stympy/faker/pull/1393) Add missing pt-BR methods and locale tests [@vbrazo](https://github.com/vbrazo)
- [PR #1392](https://github.com/stympy/faker/pull/1392) Add missing locales/methods for Faker::Name pt-BR [@heitorado](https://github.com/heitorado)
- [PR #1391](https://github.com/stympy/faker/pull/1391) Add state abbr for Sergipe and Tocatins [@VSPPedro](https://github.com/VSPPedro)
- [PR #1390](https://github.com/stympy/faker/pull/1390) Add more Dutch names [@EhsanZ](https://github.com/EhsanZ)
- [PR #1386](https://github.com/stympy/faker/pull/1386) Add locale file for Arabic language and test it [@EhsanZ](https://github.com/EhsanZ)
- [PR #1385](https://github.com/stympy/faker/pull/1385) Updated license plate by state for Brazil [@edgardmessias](https://github.com/edgardmessias)
- [PR #1373](https://github.com/stympy/faker/pull/1373) 📝 Correct some minor spelling errors [@mermop](https://github.com/mermop)
- [PR #1372](https://github.com/stympy/faker/pull/1372) Add space planet and galaxy for Japanese [@yizknn](https://github.com/yizknn)
- [PR #1370](https://github.com/stympy/faker/pull/1370) Add missed comma [@7up4](https://github.com/7up4)
- [PR #1352](https://github.com/stympy/faker/pull/1352) Add Japanese Food Sushi for Japanese and English [@yizknn](https://github.com/yizknn)
- [PR #1343](https://github.com/stympy/faker/pull/1343) Update cell phone format to be phonelib compatible for Vietnam locale [@Looooong](https://github.com/Looooong)
- [PR #1340](https://github.com/stympy/faker/pull/1340) Fix typos and additions for Faker::Esport [@Mayurifag](https://github.com/Mayurifag)
- [PR #1332](https://github.com/stympy/faker/pull/1332) Fix typo in buffy.big_bads [@tragiclifestories](https://github.com/tragiclifestories)
- [PR #1327](https://github.com/stympy/faker/pull/1327) fixed 2 quotes [@MinimumViablePerson](https://github.com/MinimumViablePerson)
- [PR #1316](https://github.com/stympy/faker/pull/1316) Add more dishes to the menu [@bjacquet](https://github.com/bjacquet)

------------------------------------------------------------------------------
## [v1.9.1](https://github.com/stympy/faker/tree/v1.9.1) (2018-07-11)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.7...v1.9.1)

### Feature Request

- [PR #1476](https://github.com/stympy/faker/pull/1476) Add Faker::House [@jguthrie100](https://github.com/jguthrie100)
- [PR #1308](https://github.com/stympy/faker/pull/1308) Add Faker::BojackHorseman [@saurabhudaniya200](https://github.com/saurabhudaniya200)
- [PR #1292](https://github.com/stympy/faker/pull/1292) Add Faker::Bank - account_number and routing_number [@vbrazo](https://github.com/vbrazo)
- [PR #1300](https://github.com/stympy/faker/pull/1300) Add Faker::GreekPhilosophers [@15ngburton](https://github.com/15ngburton)
- [PR #1004](https://github.com/stympy/faker/pull/1004) Add Faker::Ethereum [@kaizenx](https://github.com/kaizenx)
- [PR #551](https://github.com/stympy/faker/pull/551) Add gender to name generator [@Maicolben](https://github.com/Maicolben)
- [PR #1283](https://github.com/stympy/faker/pull/1283) Add Faker::Military [@jjasghar](https://github.com/jjasghar)
- [PR #1279](https://github.com/stympy/faker/pull/1279) Add Faker::HarryPotter.spell [@A9u](https://github.com/A9u)
- [PR #799](https://github.com/stympy/faker/pull/799) Faker::ElectricalComponents [@bheim6](https://github.com/bheim6)
- [PR #1050](https://github.com/stympy/faker/pull/1050) Add Faker::Invoice to generate valid bank slip references [@onnimonni](https://github.com/onnimonni)
- [PR #817](https://github.com/stympy/faker/pull/817) Faker::Lorem.multibyte for multibyte chars [@frankywahl](https://github.com/frankywahl)
- [PR #877](https://github.com/stympy/faker/pull/877) Add Canada SIN generator in Faker::Code [@gkunwar](https://github.com/gkunwar)
- [PR #1268](https://github.com/stympy/faker/pull/1268) Add Faker::Nation.national_sport [@gkunwar](https://github.com/gkunwar)
- [PR #1273](https://github.com/stympy/faker/pull/1273) Add Faker::Device [@vbrazo](https://github.com/vbrazo)
- [PR #1272](https://github.com/stympy/faker/pull/1272) Add Faker::DrWho.actor [@timcustard](https://github.com/timcustard)
- [PR #1270](https://github.com/stympy/faker/pull/1270) Add Faker::Name.middle_name [@vbrazo](https://github.com/vbrazo)
- [PR #1266](https://github.com/stympy/faker/pull/1266) Add Faker::Science.element_symbol [@timcustard](https://github.com/timcustard)
- [PR #1101](https://github.com/stympy/faker/pull/1101) Add Faker::Company.czech_organisation_number [@jindrichskupa](https://github.com/jindrichskupa)
- [PR #1265](https://github.com/stympy/faker/pull/1265) Add Faker::WorldCup [@snayrouz](https://github.com/snayrouz)
- [PR #1141](https://github.com/stympy/faker/pull/1141) Add Faker::Coffee.intensifier [@oyeanuj](https://github.com/oyeanuj)
- [PR #1260](https://github.com/stympy/faker/pull/1260) Add Faker::Auto features to Faker::Vehicle [@mrstebo](https://github.com/mrstebo)
- [PR #1259](https://github.com/stympy/faker/pull/1259) Add the ability to add separators to emails. [@aamarill](https://github.com/aamarill)
- [PR #1064](https://github.com/stympy/faker/pull/1064) Add Faker::Markdown.sandwich [@russellschmidt](https://github.com/russellschmidt)
- [PR #1222](https://github.com/stympy/faker/pull/1222) Add paragraph_by_chars functionality [@jguthrie100](https://github.com/jguthrie100)
- [PR #1107](https://github.com/stympy/faker/pull/1107) Add tokens to Faker::Stripe [@wecohere](https://github.com/wecohere)
- [PR #1258](https://github.com/stympy/faker/pull/1258) Remove simplecov-console and add coverage_report rake task [@vbrazo](https://github.com/vbrazo)
- [PR #1247](https://github.com/stympy/faker/pull/1247) Generate capital city of random Nation [@gkunwar](https://github.com/gkunwar)
- [PR #1250](https://github.com/stympy/faker/pull/1250) House appliances [@rafaelcpalmeida](https://github.com/rafaelcpalmeida)
- [PR #1239](https://github.com/stympy/faker/pull/1239) Update Faker::Food to separate out Fruits and Veggies [@susiirwin](https://github.com/susiirwin)
- [PR #1221](https://github.com/stympy/faker/pull/1221) Updated the Readme file with the new logo [@tobaloidee](https://github.com/tobaloidee)
- [PR #1109](https://github.com/stympy/faker/pull/1109) Added Princess Bride [@jayphodges](https://github.com/jayphodges)
- [PR #987](https://github.com/stympy/faker/pull/987) Add Faker::Cannabis class [@GhostGroup](https://github.com/GhostGroup)
- [PR #1199](https://github.com/stympy/faker/pull/1199) Add Faker::StrangerThings [@Connerh92](https://github.com/Connerh92)
- [PR #1129](https://github.com/stympy/faker/pull/1129) Added SingularSiegler quotes [@splashinn](https://github.com/splashinn)
- [PR #1235](https://github.com/stympy/faker/pull/1235) Added Faker::Community [@vbrazo](https://github.com/vbrazo)
- [PR #1144](https://github.com/stympy/faker/pull/1144) Added polish_register_of_national_economy and polish_taxpayer_identification_number [@rafalpetryka](https://github.com/rafalpetryka)
- [PR #1201](https://github.com/stympy/faker/pull/1201) Adding Currency Symbol to Faker [@SaimonL](https://github.com/SaimonL)
- [PR #1230](https://github.com/stympy/faker/pull/1230) Add Faker::SwordArtOnline [@lnchambers](https://github.com/lnchambers)
- [PR #792](https://github.com/stympy/faker/pull/792) Add Faker::FamousLastWords [@susiirwin](https://github.com/susiirwin)
- [PR #1174](https://github.com/stympy/faker/pull/1174) Dota API: Str Heroes, heroes quotes, Items, Teams, Players [@felipesousafs](https://github.com/darylf)
- [PR #1220](https://github.com/stympy/faker/pull/1220) Updates for Faker::Myst [@SpyMaster356](https://github.com/SpyMaster356)
- [PR #1218](https://github.com/stympy/faker/pull/1218) Add Faker::Myst [@SpyMaster356](https://github.com/SpyMaster356)
- [PR #818](https://github.com/stympy/faker/pull/818) LoremFlickr support [@mrstebo](https://github.com/mrstebo)
- [PR #1192](https://github.com/stympy/faker/pull/1192) Space: Added space launch vehicle [@gauth-ier](https://github.com/Gauth-ier)
- [PR #1211](https://github.com/stympy/faker/pull/1211) Add bands, genres, and albums to Music [@jmkoni](https://github.com/jmkoni)
- [PR #1215](https://github.com/stympy/faker/pull/1215) Added Nato Phonetic Alphabet [@timcustard](https://github.com/timcustard)
- [PR #1209](https://github.com/stympy/faker/pull/1209) Add Faker::Source [@graciano](https://github.com/graciano)
- [PR #1147](https://github.com/stympy/faker/pull/1147) Add Spanish citizen id and docs [@PuZZleDucK](https://github.com/PuZZleDucK)
- [PR #1189](https://github.com/stympy/faker/pull/1189) Add Faker::Football [@AlexGascon](https://github.com/AlexGascon)
- [PR #1202](https://github.com/stympy/faker/pull/1202) adds both inclusive and binary gender option [@jmkoni](https://github.com/jmkoni)
- [PR #1193](https://github.com/stympy/faker/pull/1193) Add Faker::MichaelScott API [@snayrouz](https://github.com/snayrouz)
- [PR #1179](https://github.com/stympy/faker/pull/1179) Random color with Placeholdit [@nicolas-brousse](https://github.com/nicolas-brousse)
- [PR #1190](https://github.com/stympy/faker/pull/1190) Add Nation object, its specs and docs [@gkunwar](https://github.com/gkunwar)
- [PR #1210](https://github.com/stympy/faker/pull/1210) Add coveralls [@vbrazo](https://github.com/vbrazo)
- [PR #924](https://github.com/stympy/faker/pull/924) RuboCop + fixes [@stephengroat](https://github.com/stephengroat)
- [PR #900](https://github.com/stympy/faker/pull/900) Add Japanese lorem words to locale [@vietqhoang](https://github.com/vietqhoang)

### Update/add locales
- [PR #1297](https://github.com/stympy/faker/pull/1297) Faker::WorldCup updates [@JoaoHenriqueVale](https://github.com/JoaoHenriqueVale)
- [PR #616](https://github.com/stympy/faker/pull/616) add german commerce translations [@weh](https://github.com/weh)
- [PR #1281](https://github.com/stympy/faker/pull/1281) Some competitions were in the coaches array [@Eusebiotrigo](https://github.com/Eusebiotrigo)
- [PR #1103](https://github.com/stympy/faker/pull/1103) Fix inconsistent capitalization in dishes, ingredients and spices, and some other small issues under 'food' [@evrimfeyyaz](https://github.com/evrimfeyyaz)
- [PR #1262](https://github.com/stympy/faker/pull/1262) Add fr_CH locale [@elentras](https://github.com/elentras)
- [PR #1261](https://github.com/stympy/faker/pull/1261) Add fr_CA locale [@elentras](https://github.com/elentras)
- [PR #1275](https://github.com/stympy/faker/pull/1275) Fix typo; RedWine should be two words [@johnmuhl](https://github.com/johnmuhl)
- [PR #1269](https://github.com/stympy/faker/pull/1269) Update Faker::ProgrammingLanguage.name locales [@vbrazo](https://github.com/vbrazo)
- [PR #1140](https://github.com/stympy/faker/pull/1140) Add Estonian and Latvian locales [@maciej-szlosarczyk](https://github.com/maciej-szlosarczyk)
- [PR #1249](https://github.com/stympy/faker/pull/1249) Update list of name prefixes for sv locale. [kamilbielawski](https://github.com/kamilbielawski)
- [PR #1228](https://github.com/stympy/faker/pull/1228) Added Japanese color to yml [@katao](https://github.com/katao)
- [PR #1106](https://github.com/stympy/faker/pull/1106) Adds turkish phone number formats [@zasman](https://github.com/ZASMan)
- [PR #794](https://github.com/stympy/faker/pull/794) Adding country code + minor locale updates [@vveliev](https://github.com/vveliev)
- [PR #439](https://github.com/stympy/faker/pull/439) Remove Eichmann surname [@jonahwh](https://github.com/jonahwh)
- [PR #1203](https://github.com/stympy/faker/pull/1203) Finnish locale has 50 most common male, female, and last names [@Glenf](https://github.com/Glenf)
- [PR #1183](https://github.com/stympy/faker/pull/1183) Correct the spelling of Gringotts [@rhoen](https://github.com/rhoen)
- [PR #1236](https://github.com/stympy/faker/pull/1236) Updates dessert faker [@susiirwin](https://github.com/susiirwin)
- [PR #1229](https://github.com/stympy/faker/pull/1229) sv.yml: Typos [@olleolleolle](https://github.com/olleolleolle)
- [PR #1108](https://github.com/stympy/faker/pull/1108) Update Faker::Dessert [@natalietate](https://github.com/natalietate)
- [PR #1122](https://github.com/stympy/faker/pull/1122) Fix formatting for Brazilian phone and cell phone numbers [@lucasqueiroz](https://github.com/lucasqueiroz)
- [PR #1138](https://github.com/stympy/faker/pull/1138) Update locales - Faker::Overwatch [@tanner0101](https://github.com/tanner0101)
- [PR #1117](https://github.com/stympy/faker/pull/1117) Added Ukrainian entries to yml [@RomanIsko](https://github.com/RomanIsko)

### Bug/Fixes
- [PR #1305](https://github.com/stympy/faker/pull/1305) Fix YAML syntax - single quote escape (on vehicle.yml) [@YumaInaura](https://github.com/YumaInaura)
- [PR #1196](https://github.com/stympy/faker/pull/1196) Fix PhoneNumber in es-MX [@drewish](https://github.com/drewish)
- [PR #1133](https://github.com/stympy/faker/pull/1133) Fix I18n 0.9.3 compatibility [@tagliala](https://github.com/tagliala)
- [PR #1292](https://github.com/stympy/faker/pull/1292) Fix flexible keys crashing when current locale does not provide them [@deivid-rodriguez](https://github.com/deivid-rodriguez)
- [PR #1274](https://github.com/stympy/faker/pull/1274) Allow Faker::Address.zip_code to have leading zero [@igor-starostenko](https://github.com/igor-starostenko)
- [PR #1241](https://github.com/stympy/faker/pull/1241) Add missing tests reported by SimpleCov [@aamarill](https://github.com/aamarill)
- [PR #1240](https://github.com/stympy/faker/pull/1240) Add some tests [@aamarill](https://github.com/aamarill)
- [PR #1238](https://github.com/stympy/faker/pull/1238) pluralized file to match link name in the readme [@Connerh92](https://github.com/Connerh92)
- [PR #1232](https://github.com/stympy/faker/pull/1232) Fix file permissions [@tagliala](https://github.com/tagliala)
- [PR #1205](https://github.com/stympy/faker/pull/1205) Show the type of field that violated a uniqueness constraint [@AndrewRayCode](https://github.com/AndrewRayCode)
- [PR #1227](https://github.com/stympy/faker/pull/1227) Update RuboCop to 0.56.0 [@tagliala](https://github.com/tagliala)
- [PR #1225](https://github.com/stympy/faker/pull/1225) Test against latest Ruby versions [@tagliala](https://github.com/tagliala)
- [PR #1134](https://github.com/stympy/faker/pull/1134) Test against latest Ruby versions [@tagliala](https://github.com/tagliala)
- [PR #1223](https://github.com/stympy/faker/pull/1223) Fix minitest warnings [@vbrazo](https://github.com/vbrazo)
- [PR #1198](https://github.com/stympy/faker/pull/1198) Rename methods on Faker::Types to avoid shadowing ruby standard methods [@MarcPer](https://github.com/MarcPer)
- [PR #1142](https://github.com/stympy/faker/pull/1142) Missing i18n jobs fix [@PuZZleDucK](https://github.com/PuZZleDucK)
- [PR #1213](https://github.com/stympy/faker/pull/1213) Add missing tests after adding Coveralls [@vbrazo](https://github.com/vbrazo)
- [PR #1212](https://github.com/stympy/faker/pull/1212) Coveralls should ignore test folder [@vbrazo](https://github.com/timcustard)
- [PR #1181](https://github.com/stympy/faker/pull/1181) Fix: Moved the Google Omniauth key id_info from root into extra [@SirRawlins](https://github.com/SirRawlins)
- [PR #1207](https://github.com/stympy/faker/pull/1207) use default rake task [@stephengroat](https://github.com/stephengroat)
- [PR #1136](https://github.com/stympy/faker/pull/1136) Modify Faker::Internet.slug [@philduffen](https://github.com/philduffen)
- [PR #1170](https://github.com/stympy/faker/pull/1170) First_name and last_name should use the parse method - :ru locale [@vbrazo](https://github.com/vbrazo)
- [PR #1197](https://github.com/stympy/faker/pull/1197) Fixes NL postcode [@JonathanWThom](https://github.com/JonathanWThom)
- [PR #1172](https://github.com/stympy/faker/pull/1172) Fix Fixnum reference warning [@vbrazo](https://github.com/vbrazo)
- [PR #1173](https://github.com/stympy/faker/pull/1173) Fix tests warning [@vbrazo](https://github.com/vbrazo)

### Chores
- [PR #1304](https://github.com/stympy/faker/pull/1304) Fix Faker::Source ruby language examples [@YumaInaura](https://github.com/YumaInaura)
- [PR #1306](https://github.com/stympy/faker/pull/1306) Rename Internet#user_name to #username [@tylerhunt](https://github.com/tylerhunt)
- [PR #1293](https://github.com/stympy/faker/pull/1293) Update RuboCop to 0.57.2 [@tagliala](https://github.com/tagliala)
- [PR #1294](https://github.com/stympy/faker/pull/1294) Simpler requiring of test helper [@deivid-rodriguez](https://github.com/deivid-rodriguez)
- [PR #1288](https://github.com/stympy/faker/pull/1288) rake console changes - description and contributing.md [@MarcPer](https://github.com/MarcPer)
- [PR #719](https://github.com/stympy/faker/pull/719) Random words to add should be 0 [@swapsCAPS](https://github.com/swapsCAPS)

### Documentation
- [PR #1478](https://github.com/stympy/faker/pull/1478) Fixed documentation for Faker::Internet.password [@mrstebo](https://github.com/mrstebo)
- [PR #1453](https://github.com/stympy/faker/pull/1453) Add description to RuboCop cops [@vbrazo](https://github.com/vbrazo)
- [PR #1121](https://github.com/stympy/faker/pull/1121) Better docs for Faker::Food.description [@jujulisan](https://github.com/jujulisan)
- [PR #1257](https://github.com/stympy/faker/pull/1257) Fix method name in Faker::SingularSiegler [@mrstebo](https://github.com/mrstebo)
- [PR #1256](https://github.com/stympy/faker/pull/1256) Fixing documentation - Faker::Name to Faker::Zelda [@mrstebo](https://github.com/mrstebo)
- [PR #1254](https://github.com/stympy/faker/pull/1254) Added missing documentation. [@mrstebo](https://github.com/mrstebo)
- [PR #1252](https://github.com/stympy/faker/pull/1252) Add missing documentation - Faker::Address to Faker::Myst [@vbrazo](https://github.com/vbrazo)
- [PR #1248](https://github.com/stympy/faker/pull/1248) Remove duplications from company.md [@vrinek](https://github.com/vrinek)
- [PR #1146](https://github.com/stympy/faker/pull/1146) Update company docs [@PuZZleDucK](https://github.com/PuZZleDucK)
- [PR #974](https://github.com/stympy/faker/pull/974) Specify version number each class was introduced [@darylf](https://github.com/darylf)
- [PR #1128](https://github.com/stympy/faker/pull/1128) Use ruby syntax highlighting in Omniauth doc [@swrobel](https://github.com/swrobel)
- [PR #1204](https://github.com/stympy/faker/pull/1204) Update sample output of `Faker::App.version` [@joshuapinter](https://github.com/joshuapinter)
- [PR #1135](https://github.com/stympy/faker/pull/1135) Added documentation for dumb and dumber [@cnharris10](https://github.com/cnharris10)
- [PR #1177](https://github.com/stympy/faker/pull/1177) Update Faker::Number.between docs [@SpyMaster356](https://github.com/SpyMaster356)
- [PR #1124](https://github.com/stympy/faker/pull/1124) Fix ranges for Brazilian zip codes [@lucasqueiroz](https://github.com/lucasqueiroz)
- New collaborator - Vitor Oliveira [@vbrazo](https://github.com/vbrazo)

### Deprecation
- [PR #1264](https://github.com/stympy/faker/pull/1264) Prepare Faker::Name.job_titles and Faker::Name.title for deprecation
  - Removing these methods as they are available in `Faker::Job`

## [v1.8.7](https://github.com/stympy/faker/tree/v1.8.7) (2017-12-22)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.6...v1.8.7)

**Additions**

- Faker::Company.type
- Faker::Job.education_level and Faker::Job.employment_type
- More characters and quotes for Seinfeld

**Fixes**

- Revert a change in 1.8.5 that caused Star Wars methods to return a
  single string rather than an array (#1093)

## [v1.8.6](https://github.com/stympy/faker/tree/v1.8.6) (2017-12-21)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.5...v1.8.6)

**Additions**

- Faker::App.semantic_version
- Faker::Types
- New methods in Faker::StarWars: call_squadron, call_sign, call_number

**Other changes**

- Changed i18n dependency from `~> 0.9.1` to `>= 0.7`

## [v1.8.5](https://github.com/stympy/faker/tree/v1.8.5) (2017-12-06)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.4...v1.8.5)

**Closed issues:**

- The latest version does not contain Faker::ProgarmmingLanguage, but the documentation said it does. [\#1083](https://github.com/stympy/faker/issues/1083)
- undefined method `initials' for Faker::Name:Class [\#1076](https://github.com/stympy/faker/issues/1076)
- Undefined method `dish' for Faker::Food:Class [\#1038](https://github.com/stympy/faker/issues/1038)
- Need Silicon Valley [\#1026](https://github.com/stympy/faker/issues/1026)
- Would it be possible to tie quotes to characters? [\#1011](https://github.com/stympy/faker/issues/1011)
- Generated phone numbers dont seem to be valid. [\#1010](https://github.com/stympy/faker/issues/1010)
- Faker::RickAndMorty not supported in 1.7.3 [\#988](https://github.com/stympy/faker/issues/988)
- Weird crash with Faker 1.8.3 [\#982](https://github.com/stympy/faker/issues/982)
- Faker::PhoneNumber.cell\_phone not enforcing locale [\#499](https://github.com/stympy/faker/issues/499)
- https url scheme [\#459](https://github.com/stympy/faker/issues/459)
- New feature: Google video and image searching [\#306](https://github.com/stympy/faker/issues/306)
- The array extension method :sample throw an argument error when the array is empty [\#94](https://github.com/stympy/faker/issues/94)
- phone\_number can generate invalid US numbers [\#24](https://github.com/stympy/faker/issues/24)

**Merged pull requests:**

- Fixes a few typos in names and deletes a duplicate [\#1084](https://github.com/stympy/faker/pull/1084) ([katelovescode](https://github.com/katelovescode))
- Fix Faker::Dog and add tests [\#1082](https://github.com/stympy/faker/pull/1082) ([wtanna](https://github.com/wtanna))
- Remove broken example from README [\#1081](https://github.com/stympy/faker/pull/1081) ([dentarg](https://github.com/dentarg))
- Remove problematic char from German street roots [\#1080](https://github.com/stympy/faker/pull/1080) ([Kjir](https://github.com/Kjir))
- Add Faker::VForVendetta [\#1073](https://github.com/stympy/faker/pull/1073) ([backpackerhh](https://github.com/backpackerhh))
- Fixes typos, removes a duplicate [\#1072](https://github.com/stympy/faker/pull/1072) ([katelovescode](https://github.com/katelovescode))
- "Flint\s\sof the mountains" ==\> "Flint\sof the mountains" [\#1071](https://github.com/stympy/faker/pull/1071) ([seanwedig](https://github.com/seanwedig))
- add ru\_chars to Char [\#1070](https://github.com/stympy/faker/pull/1070) ([startaper](https://github.com/startaper))
- Updated documentation to match correct methods [\#1069](https://github.com/stympy/faker/pull/1069) ([LasseSviland](https://github.com/LasseSviland))
- Add the @flexible\_key value to the Vehicle Class [\#1067](https://github.com/stympy/faker/pull/1067) ([agustin](https://github.com/agustin))
- kpop [\#1066](https://github.com/stympy/faker/pull/1066) ([j0shuachen](https://github.com/j0shuachen))
- Change git URL to use https instead git protocol [\#1065](https://github.com/stympy/faker/pull/1065) ([buncismamen](https://github.com/buncismamen))
- Add more quotes to the silicon valley yml file to provide more variety [\#1060](https://github.com/stympy/faker/pull/1060) ([danielwheeler1987](https://github.com/danielwheeler1987))
- change korean postcode format [\#1058](https://github.com/stympy/faker/pull/1058) ([sunghyuk](https://github.com/sunghyuk))
- Breaking bad [\#1056](https://github.com/stympy/faker/pull/1056) ([danilobarion1986](https://github.com/danilobarion1986))
- Star wars quotes [\#1054](https://github.com/stympy/faker/pull/1054) ([russellschmidt](https://github.com/russellschmidt))
- Dune and Potential Solution to Issue 1011 [\#1051](https://github.com/stympy/faker/pull/1051) ([russellschmidt](https://github.com/russellschmidt))
- add Malaysia's commercials and islamics bank [\#1045](https://github.com/stympy/faker/pull/1045) ([sanik90](https://github.com/sanik90))
- organize and add star wars data [\#1043](https://github.com/stympy/faker/pull/1043) ([tjchecketts](https://github.com/tjchecketts))
- Fix usage document [\#1040](https://github.com/stympy/faker/pull/1040) ([sashiyama](https://github.com/sashiyama))
- introduce Aqua Teen Hunger Force characters [\#1037](https://github.com/stympy/faker/pull/1037) ([ethagnawl](https://github.com/ethagnawl))
- added 1 hero, 2 locations and 2 quotes [\#1016](https://github.com/stympy/faker/pull/1016) ([murog](https://github.com/murog))
- Fix usage document. [\#1013](https://github.com/stympy/faker/pull/1013) ([n0h0](https://github.com/n0h0))
- Add dumb and dumber class [\#1008](https://github.com/stympy/faker/pull/1008) ([cnharris10](https://github.com/cnharris10))
- Update Russian resources [\#1002](https://github.com/stympy/faker/pull/1002) ([edubenetskiy](https://github.com/edubenetskiy))
- Add more Seinfeld characters [\#1001](https://github.com/stympy/faker/pull/1001) ([gregeinfrank](https://github.com/gregeinfrank))
- Adds Faker::OnePiece [\#998](https://github.com/stympy/faker/pull/998) ([Leohige](https://github.com/Leohige))
- Stargate [\#997](https://github.com/stympy/faker/pull/997) ([katymccloskey](https://github.com/katymccloskey))
- Tells users how to handle uninitialized constant error [\#995](https://github.com/stympy/faker/pull/995) ([jwpincus](https://github.com/jwpincus))
- Renamed word\_of\_warcraft to world\_of\_warcraft [\#994](https://github.com/stympy/faker/pull/994) ([Ranhiru](https://github.com/Ranhiru))
- Add default\_country for Japan and Korea [\#990](https://github.com/stympy/faker/pull/990) ([Mangoov](https://github.com/Mangoov))
- Fix typo in de.yml [\#986](https://github.com/stympy/faker/pull/986) ([IngoAlbers](https://github.com/IngoAlbers))
- Add pt-BR translate [\#985](https://github.com/stympy/faker/pull/985) ([marcosvpcortes](https://github.com/marcosvpcortes))
- Fix for NL postal code [\#984](https://github.com/stympy/faker/pull/984) ([petrosg](https://github.com/petrosg))
- French traduction for Faker::Pokemon [\#983](https://github.com/stympy/faker/pull/983) ([Dakurei](https://github.com/Dakurei))
- Added material to the Commerce docs. [\#903](https://github.com/stympy/faker/pull/903) ([mrstebo](https://github.com/mrstebo))
- Added Spanish Organization Number [\#897](https://github.com/stympy/faker/pull/897) ([cmunozgar](https://github.com/cmunozgar))

## [v1.8.4](https://github.com/stympy/faker/tree/v1.8.4) (2017-07-13)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.3...v1.8.4)

**Merged pull requests:**

- Remove errant tab character in YAML [\#981](https://github.com/stympy/faker/pull/981) ([steveh](https://github.com/steveh))

## [v1.8.3](https://github.com/stympy/faker/tree/v1.8.3) (2017-07-12)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.2...v1.8.3)

**Closed issues:**

- Can't pass zero \(0\) to the default rand method \(Faker override\) [\#976](https://github.com/stympy/faker/issues/976)
- Add Faker::Address.mailing\_address [\#841](https://github.com/stympy/faker/issues/841)

**Merged pull requests:**

- Fix tests warnings [\#979](https://github.com/stympy/faker/pull/979) ([gssbzn](https://github.com/gssbzn))
- \[\#976\] Handles zero as max for rand [\#978](https://github.com/stympy/faker/pull/978) ([gssbzn](https://github.com/gssbzn))
- Fix spelling of Wookiee [\#977](https://github.com/stympy/faker/pull/977) ([miloprice](https://github.com/miloprice))
- Faker: Umphreys mcgee [\#942](https://github.com/stympy/faker/pull/942) ([Ryanspink1](https://github.com/Ryanspink1))
- Faker: Venture bros [\#940](https://github.com/stympy/faker/pull/940) ([Ryanspink1](https://github.com/Ryanspink1))
- seinfeld faker  [\#936](https://github.com/stympy/faker/pull/936) ([cews7](https://github.com/cews7))
- elder scrolls faker [\#933](https://github.com/stympy/faker/pull/933) ([CjMoore](https://github.com/CjMoore))
- Add greek\_organization method to University Faker [\#932](https://github.com/stympy/faker/pull/932) ([andrewdwooten](https://github.com/andrewdwooten))
- add Hogwarts and Ilvermorny houses to Harry Potter faker [\#925](https://github.com/stympy/faker/pull/925) ([samanthamorco](https://github.com/samanthamorco))

## [v1.8.2](https://github.com/stympy/faker/tree/v1.8.2) (2017-07-11)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.1...v1.8.2)

**Closed issues:**

- Cannot require 'faker' after update to 1.8.1 [\#975](https://github.com/stympy/faker/issues/975)
- NoMethodError: super: no superclass method `between' for Faker::Time:Class [\#973](https://github.com/stympy/faker/issues/973)

## [v1.8.1](https://github.com/stympy/faker/tree/v1.8.1) (2017-07-10)
[Full Changelog](https://github.com/stympy/faker/compare/v1.8.0...v1.8.1)

**Closed issues:**

- Faker::Internet.domain\_word == "" [\#956](https://github.com/stympy/faker/issues/956)
- Faker::Coffee [\#935](https://github.com/stympy/faker/issues/935)
- Internet password method sometimes doesn't include special chars [\#927](https://github.com/stympy/faker/issues/927)
- Faker HowIMet [\#917](https://github.com/stympy/faker/issues/917)
- NoMethodError: super: no superclass method `backward' for Faker::Time:Class [\#915](https://github.com/stympy/faker/issues/915)
- Faker 1.8 release [\#906](https://github.com/stympy/faker/issues/906)
- Material missing in Faker::Commerce documentation [\#901](https://github.com/stympy/faker/issues/901)
- Tests fail that have nothing to do with my changes. What should I do? [\#864](https://github.com/stympy/faker/issues/864)
- uninitialized constant Faker::RuPaul [\#856](https://github.com/stympy/faker/issues/856)
- Faker::Internet.domain\_word returns empty string [\#843](https://github.com/stympy/faker/issues/843)
- unitilialized constant Faker::Demographic [\#812](https://github.com/stympy/faker/issues/812)

**Merged pull requests:**

- Fix Address.community documentation [\#972](https://github.com/stympy/faker/pull/972) ([landongrindheim](https://github.com/landongrindheim))
- edit superclass [\#971](https://github.com/stympy/faker/pull/971) ([iz4blue](https://github.com/iz4blue))
- adding important data for hipster to en.yml [\#946](https://github.com/stympy/faker/pull/946) ([dbwest](https://github.com/dbwest))
- Locale: update zh-CN cell phone formats [\#934](https://github.com/stympy/faker/pull/934) ([liluo](https://github.com/liluo))
- Fixing special chars addition in passwords. [\#926](https://github.com/stympy/faker/pull/926) ([allam-matsubara](https://github.com/allam-matsubara))
- Update commerce documentation [\#907](https://github.com/stympy/faker/pull/907) ([dv2](https://github.com/dv2))

## [v1.8.0](https://github.com/stympy/faker/tree/v1.8.0) (2017-07-09)
[Full Changelog](https://github.com/stympy/faker/compare/v1.7.3...v1.8.0)

**Closed issues:**

- Zelda Location [\#968](https://github.com/stympy/faker/issues/968)
- Real passwords / passphrases [\#962](https://github.com/stympy/faker/issues/962)
- Generating fake link \[Feature Request\] [\#955](https://github.com/stympy/faker/issues/955)
- Clean-up Robin's "Holy Steam Valve" quote [\#948](https://github.com/stympy/faker/issues/948)
- Faker::Time.between produces times out of range [\#894](https://github.com/stympy/faker/issues/894)
- \[Feature Request\] Add User Agent strings [\#880](https://github.com/stympy/faker/issues/880)
- Faker::Omniauth is not deterministic and breaking the build [\#876](https://github.com/stympy/faker/issues/876)
- undefined method `name =' or undefined method `  =' [\#871](https://github.com/stympy/faker/issues/871)
- Faker::French Suggestion [\#869](https://github.com/stympy/faker/issues/869)
- Documentation not correct for Faker::Color.hsl\_color and hsla\_color [\#866](https://github.com/stympy/faker/issues/866)
- Faker::PhoneNumber.area\_code and .exchange\_code returning nil [\#861](https://github.com/stympy/faker/issues/861)
- Faker::RickAndMorty not available in v1.7.3 from RubyGems [\#851](https://github.com/stympy/faker/issues/851)
- Adding Faker to Create in controller, possible? [\#842](https://github.com/stympy/faker/issues/842)
- Faker 1.7.3 uses Ruby 2 features [\#825](https://github.com/stympy/faker/issues/825)
- Fillmurry = error [\#823](https://github.com/stympy/faker/issues/823)
- Base\#numerify generating phone numbers and other number fields with a weird format [\#741](https://github.com/stympy/faker/issues/741)
- Markdown/HTML Support [\#630](https://github.com/stympy/faker/issues/630)
- Update WIKI and clean README [\#588](https://github.com/stympy/faker/issues/588)
- Can't overwrite locale elements using the .yml file [\#424](https://github.com/stympy/faker/issues/424)
- Faker::Lorem.paragraph raises I18n::MissingTranslationData without manual locale override [\#278](https://github.com/stympy/faker/issues/278)
- Generate unique values [\#251](https://github.com/stympy/faker/issues/251)

**Merged pull requests:**

- Add Faker::Address.community [\#969](https://github.com/stympy/faker/pull/969) ([landongrindheim](https://github.com/landongrindheim))
- Added Faker::Food.dish [\#967](https://github.com/stympy/faker/pull/967) ([aomega08](https://github.com/aomega08))
- Add translations for Malaysia [\#965](https://github.com/stympy/faker/pull/965) ([alienxp03](https://github.com/alienxp03))
- Adds some new dutch names to the locales [\#961](https://github.com/stympy/faker/pull/961) ([stefanvermaas](https://github.com/stefanvermaas))
- French traduction for Faker::Pokemon [\#960](https://github.com/stympy/faker/pull/960) ([Dakurei](https://github.com/Dakurei))
- Add characters to the RickAndMorty database [\#958](https://github.com/stympy/faker/pull/958) ([roninCode](https://github.com/roninCode))
- \[Resolved\] Internet domain word issue [\#957](https://github.com/stympy/faker/pull/957) ([SagareGanesh](https://github.com/SagareGanesh))
- Pokemon\#moves [\#954](https://github.com/stympy/faker/pull/954) ([joel-g](https://github.com/joel-g))
- Remove extraneous text from Robin quote [\#953](https://github.com/stympy/faker/pull/953) ([jsteel](https://github.com/jsteel))
- Added Simpsons. [\#950](https://github.com/stympy/faker/pull/950) ([RaimundHuebel](https://github.com/RaimundHuebel))
- add default task test for rake [\#923](https://github.com/stympy/faker/pull/923) ([stephengroat](https://github.com/stephengroat))
- Use the latest Rubies on Travis CI [\#920](https://github.com/stympy/faker/pull/920) ([hisas](https://github.com/hisas))
- Add meaningful error message when country code not found [\#916](https://github.com/stympy/faker/pull/916) ([mrstebo](https://github.com/mrstebo))
- Add Faker::HitchhikersGuideToTheGalaxy [\#914](https://github.com/stympy/faker/pull/914) ([pedroCervi](https://github.com/pedroCervi))
- Add Funny Name [\#912](https://github.com/stympy/faker/pull/912) ([jsonreeder](https://github.com/jsonreeder))
- Fix pt-BR city suffix [\#896](https://github.com/stympy/faker/pull/896) ([marcelo-leal](https://github.com/marcelo-leal))
- Adds League of Legends summoner spells, masteries and rank [\#892](https://github.com/stympy/faker/pull/892) ([DonkeyFish456](https://github.com/DonkeyFish456))
- fix typo in test file [\#890](https://github.com/stympy/faker/pull/890) ([akintner](https://github.com/akintner))
- Hobbit characters, locations, & quotes [\#889](https://github.com/stympy/faker/pull/889) ([ski-climb](https://github.com/ski-climb))
- Added Omniauth Github faker [\#888](https://github.com/stympy/faker/pull/888) ([ahmed-taj](https://github.com/ahmed-taj))
- Add locations to Faker::Zelda [\#885](https://github.com/stympy/faker/pull/885) ([thejonanshow](https://github.com/thejonanshow))
- add all setup and files for star trek faker [\#884](https://github.com/stympy/faker/pull/884) ([akintner](https://github.com/akintner))
- improve german cell phone numbers [\#882](https://github.com/stympy/faker/pull/882) ([timoschilling](https://github.com/timoschilling))
- Add How I Met Your Mother [\#879](https://github.com/stympy/faker/pull/879) ([jdconrad89](https://github.com/jdconrad89))
- Add League of Legends [\#878](https://github.com/stympy/faker/pull/878) ([Dpalazzari](https://github.com/Dpalazzari))
- Add Faker::Robin [\#868](https://github.com/stympy/faker/pull/868) ([leanucci](https://github.com/leanucci))
- Fixed hsla and hsla\_color documentation. [\#867](https://github.com/stympy/faker/pull/867) ([mrstebo](https://github.com/mrstebo))
- Add links to doc in README [\#865](https://github.com/stympy/faker/pull/865) ([taleh007](https://github.com/taleh007))
- Added bg locale [\#858](https://github.com/stympy/faker/pull/858) ([ppopov1357](https://github.com/ppopov1357))
- Add Faker::Overwatch [\#857](https://github.com/stympy/faker/pull/857) ([tomdracz](https://github.com/tomdracz))
- Add Faker::HeyArnold [\#855](https://github.com/stympy/faker/pull/855) ([MatthewDG](https://github.com/MatthewDG))
- Fix India Postal Code format [\#853](https://github.com/stympy/faker/pull/853) ([dv2](https://github.com/dv2))
- Fix typo in music.md [\#852](https://github.com/stympy/faker/pull/852) ([martinbjeldbak](https://github.com/martinbjeldbak))
- Fixed regex pattern in TestLocale::test\_regex. [\#849](https://github.com/stympy/faker/pull/849) ([karlwilbur](https://github.com/karlwilbur))
- Faker::Compass [\#848](https://github.com/stympy/faker/pull/848) ([karlwilbur](https://github.com/karlwilbur))
- en.yml: demographic, demonym: add missing double quote before Fijian [\#847](https://github.com/stympy/faker/pull/847) ([PascalSchumacher](https://github.com/PascalSchumacher))
- Update Zelda with Breath of the Wild [\#846](https://github.com/stympy/faker/pull/846) ([lauramosher](https://github.com/lauramosher))
- add RuPaul quotes [\#845](https://github.com/stympy/faker/pull/845) ([raphaeleidus](https://github.com/raphaeleidus))
- Add example for Faker::Date.birthday [\#844](https://github.com/stympy/faker/pull/844) ([janpieper](https://github.com/janpieper))
- Adds Coffee [\#840](https://github.com/stympy/faker/pull/840) ([nathanjh](https://github.com/nathanjh))
- WIP add dragon ball characters to faker [\#839](https://github.com/stympy/faker/pull/839) ([Cdunagan05](https://github.com/Cdunagan05))
- Update README.md [\#836](https://github.com/stympy/faker/pull/836) ([jbkimble](https://github.com/jbkimble))
- Truncate Twitter screen\_name length [\#834](https://github.com/stympy/faker/pull/834) ([abraham](https://github.com/abraham))
- Improve Faker::Twitter compatibility [\#831](https://github.com/stympy/faker/pull/831) ([abraham](https://github.com/abraham))
- doc: Add Internet.name length optional arguments [\#830](https://github.com/stympy/faker/pull/830) ([li-xinyang](https://github.com/li-xinyang))
- Matz [\#829](https://github.com/stympy/faker/pull/829) ([denys281](https://github.com/denys281))
- Add norwegian organization number [\#827](https://github.com/stympy/faker/pull/827) ([leifcr](https://github.com/leifcr))
- \[Resolved\] Fillmurray image Fixnum match issue [\#824](https://github.com/stympy/faker/pull/824) ([SagareGanesh](https://github.com/SagareGanesh))
- Rick and morty [\#821](https://github.com/stympy/faker/pull/821) ([JessCodes](https://github.com/JessCodes))
- Fix i18n file load issue [\#811](https://github.com/stympy/faker/pull/811) ([jacknoble](https://github.com/jacknoble))
- Create a Dessert faker [\#791](https://github.com/stympy/faker/pull/791) ([susiirwin](https://github.com/susiirwin))

## [v1.7.3](https://github.com/stympy/faker/tree/v1.7.3) (2017-02-05)
[Full Changelog](https://github.com/stympy/faker/compare/v1.7.2...v1.7.3)

**Closed issues:**

- Creates invalid UK postcodes [\#790](https://github.com/stympy/faker/issues/790)
- remove first name Adolf [\#788](https://github.com/stympy/faker/issues/788)
- Config for adding format restriction. [\#695](https://github.com/stympy/faker/issues/695)
- How to avoid special characters in faker string field [\#615](https://github.com/stympy/faker/issues/615)
- Add Demographic Data [\#585](https://github.com/stympy/faker/issues/585)
- OmniAuth ready responses [\#507](https://github.com/stympy/faker/issues/507)
- US Zip Codes Sometimes Returns Non-Actual Zip Codes [\#275](https://github.com/stympy/faker/issues/275)

**Merged pull requests:**

- Harry Potter [\#820](https://github.com/stympy/faker/pull/820) ([jaclynjessup](https://github.com/jaclynjessup))
- Update readme [\#819](https://github.com/stympy/faker/pull/819) ([ktrant84](https://github.com/ktrant84))
- en.yml: Typo Golum -\> Gollum [\#816](https://github.com/stympy/faker/pull/816) ([jtibbertsma](https://github.com/jtibbertsma))
- Add Faker::Twitter [\#815](https://github.com/stympy/faker/pull/815) ([abraham](https://github.com/abraham))
- Fixed Validity of UK postcodes [\#814](https://github.com/stympy/faker/pull/814) ([darkstego](https://github.com/darkstego))
- Fixed russian locale [\#813](https://github.com/stympy/faker/pull/813) ([fobo66](https://github.com/fobo66))
- Allow unique values to be cleared [\#810](https://github.com/stympy/faker/pull/810) ([dslh](https://github.com/dslh))
- Friends info [\#808](https://github.com/stympy/faker/pull/808) ([ktrant84](https://github.com/ktrant84))
- Update superhero.md [\#805](https://github.com/stympy/faker/pull/805) ([vitaliy-fry](https://github.com/vitaliy-fry))
- adds Zelda [\#800](https://github.com/stympy/faker/pull/800) ([audy](https://github.com/audy))
- Remove the word 'fap' [\#798](https://github.com/stympy/faker/pull/798) ([probablycorey](https://github.com/probablycorey))
- en.yml: fix typo in demographic race [\#797](https://github.com/stympy/faker/pull/797) ([PascalSchumacher](https://github.com/PascalSchumacher))
- Adds Faker::Demographic [\#796](https://github.com/stympy/faker/pull/796) ([baron816](https://github.com/baron816))
- Typofix: nfinite -\> Infinite [\#795](https://github.com/stympy/faker/pull/795) ([mgold](https://github.com/mgold))
- Update output for zip functions [\#787](https://github.com/stympy/faker/pull/787) ([yovasx2](https://github.com/yovasx2))
- doc fix job.md [\#786](https://github.com/stympy/faker/pull/786) ([ieldanr](https://github.com/ieldanr))
- Refactors code in some Faker basic classes [\#785](https://github.com/stympy/faker/pull/785) ([tiagofsilva](https://github.com/tiagofsilva))

## [v1.7.2](https://github.com/stympy/faker/tree/v1.7.2) (2017-01-03)
[Full Changelog](https://github.com/stympy/faker/compare/v1.7.1...v1.7.2)

**Closed issues:**

- Faker::Avatar error: read server certificate B: certificate verify failed [\#763](https://github.com/stympy/faker/issues/763)
- assert Faker::Internet.email.match\(/.+@\[^.\].+\.\w+/\) fails randomly [\#737](https://github.com/stympy/faker/issues/737)
- Incorrect HSL color format [\#728](https://github.com/stympy/faker/issues/728)
- Can we add the \#Hacktoberfest label for pull requests this month [\#717](https://github.com/stympy/faker/issues/717)
- Faker::Boolean.boolean error [\#714](https://github.com/stympy/faker/issues/714)
- Faker::Food not found [\#688](https://github.com/stympy/faker/issues/688)
- Fix seed for random values [\#684](https://github.com/stympy/faker/issues/684)
- README alphabetical order of Usage [\#660](https://github.com/stympy/faker/issues/660)
- At which point do we break off functionality? [\#653](https://github.com/stympy/faker/issues/653)
- Time zone abbreviation  [\#631](https://github.com/stympy/faker/issues/631)
- ruby 2.3.1 rails 5 [\#627](https://github.com/stympy/faker/issues/627)
- Faker::Time::between doesn't respect requested period [\#526](https://github.com/stympy/faker/issues/526)

**Merged pull requests:**

- IPv4: private and reserved [\#784](https://github.com/stympy/faker/pull/784) ([randoum](https://github.com/randoum))
- Update bank method [\#783](https://github.com/stympy/faker/pull/783) ([swapnilchincholkar](https://github.com/swapnilchincholkar))
- Refactors code in some base classes [\#782](https://github.com/stympy/faker/pull/782) ([tiagofsilva](https://github.com/tiagofsilva))
- Refactors code in some base classes [\#781](https://github.com/stympy/faker/pull/781) ([tiagofsilva](https://github.com/tiagofsilva))
- Refute blank [\#707](https://github.com/stympy/faker/pull/707) ([SherSpock](https://github.com/SherSpock))

## [v1.7.1](https://github.com/stympy/faker/tree/v1.7.1) (2016-12-25)
[Full Changelog](https://github.com/stympy/faker/compare/v1.7.0...v1.7.1)

**Closed issues:**

- Getting "Segmentation fault: 11" when I upgrade last 3 repos to faker 1.7.0 [\#780](https://github.com/stympy/faker/issues/780)
- New release? [\#767](https://github.com/stympy/faker/issues/767)

**Merged pull requests:**

- Added Faker::Fillmurray hotlink to usages list [\#779](https://github.com/stympy/faker/pull/779) ([Jedeu](https://github.com/Jedeu))

## [v1.7.0](https://github.com/stympy/faker/tree/v1.7.0) (2016-12-24)
[Full Changelog](https://github.com/stympy/faker/compare/v1.6.6...v1.7.0)

**Closed issues:**

- Alphanumeric password. [\#773](https://github.com/stympy/faker/issues/773)
- Unique method is undefined [\#771](https://github.com/stympy/faker/issues/771)
- Request: Human faces? [\#756](https://github.com/stympy/faker/issues/756)
- Faker for images not working [\#738](https://github.com/stympy/faker/issues/738)
- Fixed seed [\#724](https://github.com/stympy/faker/issues/724)
- Company logo ,company buzzword, Date is not working rails 4  [\#718](https://github.com/stympy/faker/issues/718)
- Image issue [\#704](https://github.com/stympy/faker/issues/704)
- Faker::Hacker.say\_something\_smart [\#691](https://github.com/stympy/faker/issues/691)
- Faker::Commerce.promotion\_code Missing Translation [\#689](https://github.com/stympy/faker/issues/689)
- Generating real email addresses [\#685](https://github.com/stympy/faker/issues/685)
- Faker::GameOfThrones.character has too little items [\#658](https://github.com/stympy/faker/issues/658)
- Pokemon class not working [\#645](https://github.com/stympy/faker/issues/645)
- NameError: uninitialized constant Educator [\#572](https://github.com/stympy/faker/issues/572)
- Causing memory error if Faker::Internet.email with integer argument [\#478](https://github.com/stympy/faker/issues/478)
- undefined method `Number' for Faker:Module [\#153](https://github.com/stympy/faker/issues/153)

**Merged pull requests:**
- Refactors code in Faker::Color [\#777](https://github.com/stympy/faker/pull/777) ([tiagofsilva](https://github.com/tiagofsilva))
- Add Faker::TwinPeaks \[fixed\] [\#775](https://github.com/stympy/faker/pull/775) ([pedantic-git](https://github.com/pedantic-git))
- Added wookie\_sentence method documentation to README [\#772](https://github.com/stympy/faker/pull/772) ([toddnestor](https://github.com/toddnestor))
- Refactored finance.rb [\#770](https://github.com/stympy/faker/pull/770) ([Newman101](https://github.com/Newman101))
- ex-MX.yml: city\_prefix and city\_suffix: replace empty list with empty… [\#769](https://github.com/stympy/faker/pull/769) ([PascalSchumacher](https://github.com/PascalSchumacher))
- Correct HSL and HSLA color formatting [\#768](https://github.com/stympy/faker/pull/768) ([mwgalloway](https://github.com/mwgalloway))
- Adds wookie sentence generator [\#766](https://github.com/stympy/faker/pull/766) ([toddnestor](https://github.com/toddnestor))
- Add Faker::Ancient [\#765](https://github.com/stympy/faker/pull/765) ([phoenixweiss](https://github.com/phoenixweiss))
- Added Slovakian unit tests [\#764](https://github.com/stympy/faker/pull/764) ([Newman101](https://github.com/Newman101))
- added bank setup [\#762](https://github.com/stympy/faker/pull/762) ([RasMachineMan](https://github.com/RasMachineMan))
- Added Russian unit tests [\#761](https://github.com/stympy/faker/pull/761) ([Newman101](https://github.com/Newman101))
- Add eSports data [\#760](https://github.com/stympy/faker/pull/760) ([FanaHOVA](https://github.com/FanaHOVA))
- add lorempixel [\#759](https://github.com/stympy/faker/pull/759) ([senid231](https://github.com/senid231))
- Added nb-NO locale unit tests [\#758](https://github.com/stympy/faker/pull/758) ([Newman101](https://github.com/Newman101))
- Added Japanese unit tests [\#757](https://github.com/stympy/faker/pull/757) ([Newman101](https://github.com/Newman101))
- Update educator.rb [\#755](https://github.com/stympy/faker/pull/755) ([huyderman](https://github.com/huyderman))
- Some Turkish Translations \#1 [\#754](https://github.com/stympy/faker/pull/754) ([BatuhanW](https://github.com/BatuhanW))
- Add some german translations ... [\#753](https://github.com/stympy/faker/pull/753) ([Kjarrigan](https://github.com/Kjarrigan))
- Add method for ensuring unique values [\#752](https://github.com/stympy/faker/pull/752) ([jonmast](https://github.com/jonmast))
- Delete unneeded line for Faker::Internet.password [\#751](https://github.com/stympy/faker/pull/751) ([bakunyo](https://github.com/bakunyo))
- Add Mew to Pokemon::Name [\#750](https://github.com/stympy/faker/pull/750) ([kenta-s](https://github.com/kenta-s))
- Update docs to make it clearer what args to Lorem.sentence and Lorem.paragraph do [\#749](https://github.com/stympy/faker/pull/749) ([ulyssesrex](https://github.com/ulyssesrex))
- Add optional https urls [\#747](https://github.com/stympy/faker/pull/747) ([kaiuhl](https://github.com/kaiuhl))
- Creates tests for Address\#zip\_code [\#746](https://github.com/stympy/faker/pull/746) ([tiagofsilva](https://github.com/tiagofsilva))
- Creates Address\#full\_address customizable by locale [\#745](https://github.com/stympy/faker/pull/745) ([tiagofsilva](https://github.com/tiagofsilva))
- Improves readability of Hipster\#resolve. [\#743](https://github.com/stympy/faker/pull/743) ([tiagofsilva](https://github.com/tiagofsilva))
- Use Random::DEFAULT instead of Random.new.rand / SecureRandom [\#740](https://github.com/stympy/faker/pull/740) ([smangelsdorf](https://github.com/smangelsdorf))
- Added Korean unit tests [\#739](https://github.com/stympy/faker/pull/739) ([Newman101](https://github.com/Newman101))
- it.yml: name.suffix: replace list with empty string, to make it consi… [\#736](https://github.com/stympy/faker/pull/736) ([PascalSchumacher](https://github.com/PascalSchumacher))
- fix german university name generation [\#734](https://github.com/stympy/faker/pull/734) ([PascalSchumacher](https://github.com/PascalSchumacher))
- fr.yml: remove 13 after lille [\#733](https://github.com/stympy/faker/pull/733) ([PascalSchumacher](https://github.com/PascalSchumacher))
- Add Normal \(Gaussian\) distribution to Faker::Number [\#731](https://github.com/stympy/faker/pull/731) ([rabidaudio](https://github.com/rabidaudio))
- added indonesian locale [\#730](https://github.com/stympy/faker/pull/730) ([bprayudha](https://github.com/bprayudha))
- Added dragons to the Game of Throne universe. [\#729](https://github.com/stympy/faker/pull/729) ([archbloom](https://github.com/archbloom))
- Tweak es-MX locale data for addresses [\#727](https://github.com/stympy/faker/pull/727) ([joiggama](https://github.com/joiggama))
- Add Game of Thrones quotes [\#726](https://github.com/stympy/faker/pull/726) ([rajivrnair](https://github.com/rajivrnair))
- adds Faker::Artist.name [\#725](https://github.com/stympy/faker/pull/725) ([forresty](https://github.com/forresty))
- Resolve warnings during tests [\#722](https://github.com/stympy/faker/pull/722) ([andy-j](https://github.com/andy-j))
- Add chords to music [\#721](https://github.com/stympy/faker/pull/721) ([andy-j](https://github.com/andy-j))
- Add major and minor keys to music [\#720](https://github.com/stympy/faker/pull/720) ([andy-j](https://github.com/andy-j))
- Fixed the inaccurate swedish organization number generator [\#715](https://github.com/stympy/faker/pull/715) ([hex0cter](https://github.com/hex0cter))
- Fix typos in brazilian portuguese countries translations [\#713](https://github.com/stympy/faker/pull/713) ([Yaakushi](https://github.com/Yaakushi))
- Fix typo in 'Secondary' [\#712](https://github.com/stympy/faker/pull/712) ([edtjones](https://github.com/edtjones))
- Changed quotes in food.rb [\#710](https://github.com/stympy/faker/pull/710) ([Newman101](https://github.com/Newman101))
- Added type checks to PL unit test [\#709](https://github.com/stympy/faker/pull/709) ([Newman101](https://github.com/Newman101))
- Fix Faker::Educator "secondary" spelling [\#708](https://github.com/stympy/faker/pull/708) ([gadtfly](https://github.com/gadtfly))
- adds meteorite to Faker::Space [\#702](https://github.com/stympy/faker/pull/702) ([kfrz](https://github.com/kfrz))
- fixed typo in secondary\_school [\#701](https://github.com/stympy/faker/pull/701) ([garyharan](https://github.com/garyharan))
- Improve Address.postcode example to reflect actual output [\#700](https://github.com/stympy/faker/pull/700) ([goulvench](https://github.com/goulvench))
- Fixed invalid name in pl.yml [\#694](https://github.com/stympy/faker/pull/694) ([Yobilat](https://github.com/Yobilat))
- Fixed failing build [\#683](https://github.com/stympy/faker/pull/683) ([Newman101](https://github.com/Newman101))
- added south african locales [\#682](https://github.com/stympy/faker/pull/682) ([Letladi](https://github.com/Letladi))
- Add Food link for readme [\#681](https://github.com/stympy/faker/pull/681) ([martymclaugh](https://github.com/martymclaugh))
- Add updated en-nz locale data [\#680](https://github.com/stympy/faker/pull/680) ([geordidearns](https://github.com/geordidearns))
- Fixed typo in dutch translation [\#679](https://github.com/stympy/faker/pull/679) ([nschmoller](https://github.com/nschmoller))
- Add pokemon [\#677](https://github.com/stympy/faker/pull/677) ([bakunyo](https://github.com/bakunyo))
- Food [\#672](https://github.com/stympy/faker/pull/672) ([martymclaugh](https://github.com/martymclaugh))
- Added charcaters and houses data for game of thrones in en.yml [\#670](https://github.com/stympy/faker/pull/670) ([vamsipavanmahesh](https://github.com/vamsipavanmahesh))
- add Faker::Commerce.promotion\_code [\#669](https://github.com/stympy/faker/pull/669) ([jGRUBBS](https://github.com/jGRUBBS))
- Eliminate and prevent leading and trailing white space [\#665](https://github.com/stympy/faker/pull/665) ([retroGiant89](https://github.com/retroGiant89))
- Fix for memory overflow error Issue: \#478 [\#664](https://github.com/stympy/faker/pull/664) ([anuj-verma](https://github.com/anuj-verma))
- Added unit tests to es-MX locale [\#661](https://github.com/stympy/faker/pull/661) ([Newman101](https://github.com/Newman101))
- Added default country test to en-AU locale [\#656](https://github.com/stympy/faker/pull/656) ([Newman101](https://github.com/Newman101))
- Fixed incorrect locale configuration [\#655](https://github.com/stympy/faker/pull/655) ([Newman101](https://github.com/Newman101))
- Add support for dutch university names [\#654](https://github.com/stympy/faker/pull/654) ([nysthee](https://github.com/nysthee))
- Added default country check to en-PAK unit tests [\#652](https://github.com/stympy/faker/pull/652) ([Newman101](https://github.com/Newman101))
- Added even method to Luhn algorithm [\#650](https://github.com/stympy/faker/pull/650) ([Newman101](https://github.com/Newman101))
- Add more names to pt-BR [\#649](https://github.com/stympy/faker/pull/649) ([haggen](https://github.com/haggen))
- Add Nigerian locale to locales [\#647](https://github.com/stympy/faker/pull/647) ([oluosiname](https://github.com/oluosiname))
- Refactor Luhn Checksum [\#619](https://github.com/stympy/faker/pull/619) ([Newman101](https://github.com/Newman101))
- Added en-SG unit tests [\#618](https://github.com/stympy/faker/pull/618) ([Newman101](https://github.com/Newman101))
- Improved de-AT unit tests [\#614](https://github.com/stympy/faker/pull/614) ([Newman101](https://github.com/Newman101))
- Changed quotes in color.rb [\#606](https://github.com/stympy/faker/pull/606) ([Newman101](https://github.com/Newman101))

## [v1.6.6](https://github.com/stympy/faker/tree/v1.6.6) (2016-07-25)
[Full Changelog](https://github.com/stympy/faker/compare/v1.6.5...v1.6.6)

**Closed issues:**

-  Faker::Vehicle.vin gives undefined method `match' [\#638](https://github.com/stympy/faker/issues/638)
- Faker::Date.backward\(14\) [\#632](https://github.com/stympy/faker/issues/632)
- Shouldn't we capitalize the result of `Faker::Hacker.say\_something\_smart`? [\#623](https://github.com/stympy/faker/issues/623)

**Merged pull requests:**

- Fixed Faker::Vehicle.vin Fixnum issue \#638 [\#639](https://github.com/stympy/faker/pull/639) ([amoludage](https://github.com/amoludage))
- fix readme link for fakerpokemon [\#637](https://github.com/stympy/faker/pull/637) ([shinwang1](https://github.com/shinwang1))
- Making pull request to add Pokemon names and locations to stumpy/faker [\#636](https://github.com/stympy/faker/pull/636) ([shinwang1](https://github.com/shinwang1))
- Added shorthand for self-assignment on date.rb [\#635](https://github.com/stympy/faker/pull/635) ([Newman101](https://github.com/Newman101))
- Fixed a method call in date.rb [\#633](https://github.com/stympy/faker/pull/633) ([Newman101](https://github.com/Newman101))
- Add Game of Thrones faker [\#629](https://github.com/stympy/faker/pull/629) ([duduribeiro](https://github.com/duduribeiro))
- Add German translations for Commerce [\#626](https://github.com/stympy/faker/pull/626) ([laurens](https://github.com/laurens))
- Solved Issue \#623 [\#625](https://github.com/stympy/faker/pull/625) ([Newman101](https://github.com/Newman101))

## v1.6.5 (2016-07-08)
* Removed Faker::ChuckNorris.name

## v1.6.4 (2016-07-06)
* Removed support for Ruby 1.9.3
* Added Faker::ChuckNorris, Faker::Crypto, Faker::Educator, Faker::File, Faker::Music, Faker::Space, Faker::Vehicle, and Faker::Yoda
* Fixed bug with credit card types
* DST fixes in Faker::Time
* Added Faker::Name.name_with_middle
* Added Faker::Code.imei
* Added Faker::Code.asin
* Added Faker::Lorem.question and Faker::Lorem.questions
* Added Faker::Internet.private_ip_v4_address
* Added Faker::Company.australian_business_number
* Other miscellaneous fixes and locale updates

## v1.6.3 (2016-02-23)
* Fix for UTF problem in Ruby 1.9.3
* Fix for Faker::StarWars.character
* Updated sv locale

## v1.6.2 (2016-02-20)
* Fix for locale-switching (Russian email addresses)
* Added Faker::Beer, Faker::Boolean, Faker::Cat, Faker::StarWars, and Faker::Superhero
* Added Faker::Color.color_name
* Added Faker::Date.between_except
* Fixed Faker::Internet.ip_v4_cidr and Faker::Internet.ip_v6_cidr
* Added locales: ca, ca-CAT, da-DK, fi-FI, and pt

## v1.6.1 (2015-11-23)
* Fix for locale issues in tests

## v1.6.0 (2015-11-23)
* Lots of bug fixes -- most notably, a fix for email addresses and domains in non-en locales
* Updated locales: de, en-AU, en-NZ, en-SG, en-US, en-au-ocker, en, es, fr, he, it, ja, nb-NO, pl, pt-BR, sk, and zh-CN
* Updated classes: Address, Avatar, Book, Code, Commerce, Company, Hipster, IDNumber, Internet, Number, Placeholdit, Shakespeare, and Time

## v1.5.0 (2015-08-17)
* Added logos
* Added Slack Emoji
* Updated image generators
* Updated Dutch Locale
* Added support for generating RGB values, HSL colors, alpha channel, and HSLA colors
* Added locale for Uganda
* Added basic Ukrainian support
* Added university name generator
* Updated documentation
* Updated a variety of locales
* Various fixes

## v1.4.3 (2014-08-15)
* Updated Russian locale
* Added EIN generator
* Fixed Swedish locale
* Added birthday to Faker::Date
* Added Faker::App

## v1.4.2 (2014-07-15)
* Added Swedish locale
* README update

## v1.4.1 (2014-07-04)
* Bugfix and cleanup

## v1.4.0 (2014-07-03)
* Many enhancements and bugfixes

## v1.3.0 (2014-03-08)
* Many enhancements and few bugfixes

## v1.2.0 (2013-07-27)
* Many major and minor enhancements :)

## v1.1.2 (2012-09-18)
* 1 minor change:
    * Fixed Ruby 1.8 compatibility

## v1.1.1 (2012-09-17)
* 1 minor change:
    * Removed ja locale because of parse errors

## v1.1.0 (2012-09-15)
* 1 major change:
    * Removed deprecated methods from Address: earth_country, us_state, us_state_abbr, uk_postcode, uk_county
* Many minor changes (please see github pull requests for credits)
    * Added many localizations
    * Added range and array support for Lorem

## v1.0.1 (2011-09-27)
* 1 minor enhancement
    * Added safe_email method to get someaddress@example.com [Kazimierz Kiełkowicz]
* 1 bug fix:
    * Use the locale fallback properly when parsing string formats

## v1.0.0 (2011-09-08)
* 2 major enhancements
    * Moved all formats to locale files
    * Stopped interfering with I18n's global settings for fallbacks
* 3 minor bug fixes:
    * Ruby 1.9.2 fixes [eMxyzptlk]
    * UTF8 fixes [maxmiliano]
    * Updated IPv4 generator to return valid addresses [Sylvain Desbureaux]
* Many minor enhancements:
    * Added bork locale for bork-ified lorem [johnbentcope]
    * Added IPv6 address generator [jc00ke]
    * Removed deprecation warnings for Array#rand [chrismarshall]
    * Added German translation and I18n improvements [Matthias Kühnert]
    * Added Dutch translation [moretea]
    * Added Lat/Long generator [Andy Callaghan]
    * Added buzzword-laden title generator [supercleanse]
    * Added optional extended wordlist for lorem [chriskottom]
    * Updated German translation [Jan Schwenzien]
    * Locale improvements [suweller]
    * Added limit to lorem generator [darrenterhune]
    * Added Brazilian Portuguese translation [maxmiliano]
    * Added Australian translation [madeindata]
    * Added Canadian translation [igbanam]
    * Added Norwegian translation [kytrinyx]
    * Lots of translation-related cleanup [kytrinyx]


## v0.9.5 (2011-01-27)
* 1 minor bug fix:
    * Fixed YAML [Aaron Patterson]
* 3 minor enhancements:
    * Added default rake task to run all tests [Aaron Patterson]
    * Removed shuffle method [Aaron Patterson]
    * Use psych if present [Aaron Patterson]

## v0.9.4 (2010-12-29)
* 1 minor bug fix:
    * Stopped getting in the way of Rails' late locale loading

## v0.9.3 (2010-12-28)
* 1 minor enhancement:
    * Added a faker namespace for translations

## v0.9.2 (2010-12-22)
* 1 bug fix:
    * Stopped stomping on I18n load path

## v0.9.1 (2010-12-22)
* 1 bug fix:
    * Stopped setting I18n default locale
* 1 major enhancement:
    * Added method_missing to Address to add methods based on data in locale files
* 1 minor enhancement:
    * Added Swiss locale [Lukas Westermann]

## v0.9.0 (2010-12-21)
* 1 major enhancement:
    * Moved strings and some formats to locale files

## v0.3.1 (2008-04-03)
* 1 minor enhancement:
    * Added city to Address

## v0.3.0 (2008-01-01)
* 3 major enhancements:
    * Added Lorem to generate fake Latin
    * Added secondary_address to Address, and made inclusion of
    secondary address in street_address optional (false by
    default).
    * Added UK address methods [Caius Durling]

## v0.2.1 (2007-12-05)
* 1 major enhancement:
    * Dropped facets to avoid conflict with ActiveSupport
* 2 minor enhancements:
    * Changed the output of user_name to randomly separate with a . or _
    * Added a few tests

## v0.1.0 (2007-11-22)

* 1 major enhancement:
    * Initial release


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
