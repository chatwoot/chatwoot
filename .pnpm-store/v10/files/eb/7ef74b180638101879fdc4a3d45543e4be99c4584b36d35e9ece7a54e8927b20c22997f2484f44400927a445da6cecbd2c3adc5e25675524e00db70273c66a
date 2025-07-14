3.4.9 / 2022-04-08
==================

  * Fixes sourcemaps.

3.4.8 / 2022-02-14
==================

  * Removes "klona", replacing with a utility cloning function for properties.

3.4.6 / 2021-07-12
==================

  * Remove nulls from track.products()

3.4.5 / 2021-07-09
==================

  * Handle null on context.device for Facade

3.4.4 / 2021-07-08
==================

  * Minimize package size

3.4.3 / 2021-07-08
==================

  * Always clone raw event

3.4.0 / 2021-06-25
==================

  * Add ".rawEvent()" method 
  
3.3.8 / 2021-05-17
==================

  * Replace third party library "ndhoule/clone" with lighter "lukeed/klona"

3.3.6 / 2020-11-06
==================

  * Remove third party library "is-email"

3.3.3 / 2020-11-06
==================

  * Remove third party library "type-component" in favor of native JS functions

3.3.0 / 2020-09-23
==================

  * Optimize bundle size
  * Upgrade libraries
  * Compile modern code with TypeScript

3.2.6 / 2019-05-21
==================

* Add types for Delete and Alias in the declaration file.

3.2.5 / 2019-05-13
==================

* Update ts declaration file to use a namespace. This should improve the experience when using JSdoc.

3.2.4 / 2019-04-22
==================

* add types file


3.2.3 / 2018-02-27
==================

* add support for delete

3.2.2 / 2017-09-26
==================

* identify: add companyName()

3.2.1 / 2017-06-19
==================

* track: fallback to revenue property in .subtotal method
* update .subtotal tests
* pin package.json dependencies

3.2.0 / 2016-11-21
==================

  * track: add .shippingMethod, .paymentMethod methods

3.1.0 / 2016-08-30
==================

  * create individual helper functions for each object_id
  * update .orderId unction to support ecom spec v2

3.0.3 / 2016-06-06
==================

  * Update `Order Completed` Regexp in track.prototype.revenue

3.0.2 / 2016-05-17
==================

  * Misc cleanup and test harness improvements

3.0.1 / 2016-05-16
==================

  * Modernize test/CI harness
    * Note: Coverage in Sauce Labs is disabled due to repeated browser timeouts/crashes. Need to investigate this further
  * Lint compliance
  * Fix tests on IE8, IE7

3.0.0 / 2016-04-07
==================

  * remove travis
  * circle: add explict test phases
  * Makefile: add back lint, node-tests and coverage
  * circle,Makefile: build "build.js"
  * facade: fix "traverse" require
  * add `circle.yml`
  * package: replace "isodate-traverse" with "@segment/isodate-traverse"
  * remove component, add browserify

2.2.2 / 2016-02-18
==================

  * updating travis
  * add email helper to page/screen events

2.2.1 / 2015-10-28
==================

  * Update referrer methods on track and page to use `properties.referrer`, `context.referrer.url` and `context.page.referrer`
  * update track#email to fallback to context.traits.email

2.2.0 / 2015-08-18
==================

  * enable aliasing of page properties

1.5.0 / 2015-08-18
==================

  * enable aliasing of page properties

2.1.1 / 2015-06-30
==================

 * Facade: take deep clone of object at instantiation time when `options.clone = true` (fixes https://github.com/segmentio/facade/issues/77)

2.1.0 / 2014-12-03
==================

 * facade: pass options around
 * facade: option to skip iso-traverse
 * track: add repeat()

2.0.5 / 2014-11-06
==================

  * options: support legacy options

2.0.4 / 2014-11-03
==================

  * add .region() to address lib

2.0.3 / 2014-10-27
==================

  * context.device,timezone: adding tests + implementation

2.0.2 / 2014-10-09
==================

 * fix page.track() and screen.track()

2.0.1 / 2014-09-26
==================

  * Pass options to each type of facade

2.0.0 / 2014-09-26
==================

 * Add clone option

1.4.7 / 2014-09-18
==================

 * travis: add token
 * make: catch test changes
 * add referrer

1.4.6 / 2014-09-04
==================

  * Merge pull request #63 from segmentio/add/discount
  * adding discount proxy and computation to subtotal

1.4.5 / 2014-09-02
==================

 * updating obj-case dep

1.4.4 / 2014-08-29
==================

 * track: dont override address()

1.4.3 / 2014-08-21
==================

 * address: move to facade base prototype

1.4.2 / 2014-08-19
==================

 * identify: add .avatarUrl fallback to .avatar()
 * page: add .title(), .path(), .url()
 * group: add .name()
 * group: add .email() that behaves like identify.email()
 * group: add .employees() and .industry()

1.4.1 / 2014-08-19
==================

 * address: add address traits to group and identify

1.4.0 / 2014-08-13
==================

 * screen: fix .context()
 * page: fix .context()
 * page: fix .timestamp()
 * screen: fix .timestamp()
 * add .phones()
 * .phone(): fallback to .phones[0]
 * add .websites()
 * add Facade.one()
 * add Facade.multi()
 * add .position()
 * add .avatar() fallback to .photoUrl
 * add .gender(), .birthday() and .age()
 * make: bench on make test
 * make: add bench target
 * make: test target should test all (travis gotchas etc..)
 * track#subtotal: fix lookup and add tests
 * deps: add type()
 * track#products: make sure it always returns an array
 * deps: upgrade duo

1.3.0 / 2014-08-07
==================

 * tests: add more alias tests
 * Marketo is no longer disabled by default

1.2.2 / 2014-07-23
==================

 * adding benchmarks, moving traverse
 * updating 1-1 mapping for aliased .traits()

1.2.1 / 2014-07-16
==================

 * .timestamp(): add .getTime() test
 * test-sauce: add tests name
 * test-sauce: test only on firefox
 * use new-date, to fix incorrect date in firefox
 * use duo-test

1.2.0 / 2014-06-23
==================

 * component bump
 * Merge pull request #44 from segmentio/move/global-traits
 * remvoing debugger hahah
 * mirroring  aliasing and id between track.traits and facade.traits
 * moving track.traits to be global
 * updating docs

1.1.0 / 2014-06-17
==================

 * component bump
 * Merge pull request #42 from segmentio/groupId
 * adding grouoId to context.groupId to support account level settings
 * Update Readme.md

1.0.1 / 2014-06-12
==================

 * updating obj-case dep

1.0.0 / 2014-06-12
==================

 * duo: adding duo

0.3.10 / 2014-05-16
==================

 * bump again

0.3.8 / 2014-05-16
==================

 * bump component.json version

0.3.7 / 2014-05-16
==================

 * add better revenue intuition for ecommerce

0.3.6 / 2014-05-16
==================

 * add fallback from revenue to total

0.3.5 / 2014-05-08
==================

 * adding enabled fix for new spec

0.3.4 / 2014-05-06
==================

 * add .context() for new spec
 * adding .library() method

0.3.3 / 2014-04-21
==================

 * adding .type()

0.3.2 / 2014-04-05
==================

 * fix: track.email()

0.3.1 / 2014-03-19
==================

 * adds date parsing to nested fields

0.3.0 / 2014-03-10
==================

 * add screen
 * support new spec

0.2.12 / 2014-03-07
==================

 * re-add useragent

0.2.11 / 2014-03-06
==================

 * support "id" as "orderId"

0.2.10 / 2014-03-06
==================

 * add .userId() and .sessionId() to all actions

0.2.9 / 2014-02-17
==================

* bumping version

0.2.8 / 2014-02-11
==================

 * updating obj-case

0.2.7 / 2014-02-07
==================

 * add country
 * add more ecommerce properties

0.2.6 / 2014-02-02
==================

 * add defaults to .currency() and .quantity()
 * add transactionId

0.2.5 / 2014-02-02
==================

 * add ecommerce

0.2.4 / 2014-01-30
==================

 * upgrade isodate to 0.3.0

0.2.3 / 2014-01-14
==================

 * use obj-case in options()
 * add fix for non-string name fields

0.2.2 / 2014-01-07
==================

 * update dependencies
 * add .travis.yml

0.2.0 / 2013-12-18
==================

  * fix obj-case dep


0.1.4 / 2013-12-14
==================

 * add identify#description

0.1.3 / 2013-12-02
==================

  * identify: adding fixes for `lastName` with multiple spaces
  * track: adding simple identify tests

0.1.2 / 2013-09-26
==================

  * adding casting for string timestamps

0.1.1 / 2013-09-06
==================

  * adding fix for `options.providers.all`

0.1.0 / 2013-08-29
==================

  * Initial release
