0.2.1 / 2015-02-25
==================
  * Fix leaking global

0.2.0 / 2014-12-15
==================

  * Fix `find` export
  * Allow user to pass `options` parameter, letting you customize the normalizer

0.1.1 / 2014-09-09
==================

  * Allow the terminal value to be null or undefined

0.1.0 / 2014-09-02
==================

 * moved to a standard normalization with only letters, numbers and dots

0.0.11 / 2014-08-30
===================

  * Merge pull request #7 from segmentio/fix/bug
  * fix edge case for facade

0.0.10 / 2014-08-30
===================

  * Merge pull request #6 from segmentio/fix/shared-prefix
  * adding more tests for an edge case we didnt consider

0.0.9 / 2014-08-30
==================

  * Merge pull request #5 from segmentio/fix/test
  * work on blank objects

0.0.8 / 2014-08-29
==================

 * add performance test, getting 100000/1800 = 55ops/ms
 * refactor to iterate in reverse, so we can handle dots in key names

0.0.8 / 2014-08-29
==================

 * Merge pull request #4 from segmentio/support/nested-dots
 * move comment to normalize
 * move out normalize method
 * add performance test, getting 100000/1800 = 55ops/ms
 * add performance test, getting 100000/1120 = 90ops/ms = 90000ops/sec
 * refactor to iterate in reverse, so we can handle dots in key names

0.0.7 / 2014-06-12
==================

 * add a fix for identity matching

0.0.6 / 2014-02-11
==================

 * use proper case dep
 * add travis.yml
 * fix `test` target

0.0.5 / 2013-12-19
==================

 * bump version

0.0.4 / 2013-12-19
==================

 * use ianstormtaylor/case

0.0.3 / 2013-12-05
==================

 * add client side tests
 * fix client side

0.0.2 / 2013-12-04
==================

 * test: adding falsey test
 * fix: component.json typo
