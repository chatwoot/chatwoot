# History

## 1.5.1 / 2024-01-31

- Peter Goldstein updated CI configuration to add Ruby 3.1 and Masato Nakamura
  added Ruby 3.2 and 3.3. [#82][], [#89][]

- Updated the CI configuration, resolving [#82][] to add Ruby 3.1. Masato

- Switched to [standard ruby][] formatting.

- Justin Steele converted the licence file to Markdown. [#84][]

- Updated the gem SPDX identifier for GPL 2.0 or later, resolving [#86][] by Vit
  Ondruch.

- Resolve a potential security issue with `ldiff` in its use of `IO.read`
  instead of `File.read`. [#91][]

- Added MFA authentication requirement for release to RubyGems. [#90][]

- Added dependabot management for actions and gems. [#90][]

- Updated CodeQL coniguration. [#90][]

## 1.5.0 / 2021-12-23

- Updated the CI configuration and monkey-patch Hoe.

- Kenichi Kamiya fixed a test configuration deprecation in SimpleCov. [#69][]

- Tien introduced several corrections and code improvements:

  - Removed an off-by-one error when calculating an index value by embracing
    Ruby iteration properly. This had a side-effect of fixing a long-standing
    bug in `#traverse_sequences` where the traversal would not be transitive.
    That is, `LCS(s2, s1)` should produce a sequence that is transitive with
    `LCS(s1, s2)` on traversal, and applying the diff computed from those
    results would result in equivalent changes that could be played forward or
    backward as appropriate. [#71][], [#75][]

  - The above fix resulted in a changed order of the longest common subsequence
    when callbacks were applied. After analysis, it was determined that the
    computed subsequence was _equivalent_ to the prior version, so the test was
    updated. This also resulted in the clarification of documentation when
    traversing the subsequences. [#79][]

  - An infinite loop case in the case where Diff::LCS would be included into an
    enumerable class has been fixed. [#73][]

  - Clarified the purpose of a threshold test in calculation of LCS. [#72][],
    [#80][]

- Removed autotest directory

## 1.4.4 / 2020-07-01

- Fixed an issue reported by Jun Aruga in the Diff::LCS::Ldiff binary text
  detection. [#44][]

- Fixed a theoretical issue reported by Jun Aruga in Diff::LCS::Hunk to raise
  a more useful exception. [#43][]

- Added documentation that should address custom object issues as reported in
  [#35][].

- Fixed more diff errors, in part reported in [#65][].

  - The use of `Numeric#abs` is incorrect in `Diff::LCS::Block#diff_size`. The
    diff size _must_ be accurate for correct change placement.

  - When selecting @max_diff_size in Diff::LCS::Hunk, choose it based on
    `block.diff_size.abs`.

  - Made a number of changes that will, unfortunately, increase allocations at
    the cost of being safe with frozen strings.

  - Add some knowledge that when `Diff::LCS::Hunk#diff` is called, that we are
    processing the _last_ hunk, so some changes will be made to how the output
    is generated.

    - `old`, `ed`, and `reverse_ed` formats have no differences.

    - `unified` format will report `\ No newline at end of file` given the
      correct conditions, at most once. Unified range reporting also differs for
      the last hunk such that the `length` of the range is reduced by one.

    - `context` format will report `\No newline at end of file` given the
      correct conditions, up to once per "file". Context range reporting also
      differs for the last hunk such that the `end` part of the range is reduced
      by one to a minimum of one.

- Added a bunch more tests for the cases above, and fixed `hunk_spec.rb` so that
  the phrase being compared isn't nonsense French.

- Updated formatting.

- Added a Rake task to assist with manual testing on Ruby 1.8.

## 1.4.3 / 2020-06-29

- Fixed several issues with the 1.4 on Rubies older than 2.0. Some of this was
  providing useful shim functions to Hoe 3.x (which dropped these older Rubies
  a while ago). Specifically:

  - Removed Array#lazy from a method in Diff::LCS::Hunk.

  - Changed some unit tests to use old-style Symbol-keyed hashes.

  - Changed some unit test helper functions to no longer use keyword parameters,
    but only a trailing options hash.

  - Made the use of `psych` dependent on `RUBY_VERSION >= 1.9`.

  Resolves [#63][].

## 1.4.2 / 2020-06-23

- Camille Drapier fixed a small issue with RuboCop configuration. [#59][]

- Applied another fix (and unit test) to fix an issue for the Chef team.
  [#60][], [#61][]

## 1.4.1 / 2020-06-23

- Fix an issue where diff sizes could be negative, and they should be. [#57][],
  [#58][]

## 1.4 / 2020-06-23

- Ruby versions lower than 2.4 are soft-deprecated and will not be run as part
  of the CI process any longer.

- Akinora MUSHA (knu) added the ability for Diff::LCS::Change objects to be
  implicitly treated arrays. Originally provided as pull request [#47][], but it
  introduced a number of test failures as documented in [#48][], and remediation
  of Diff::LCS itself was introduced in [#49][].

- Resolved [#5][] with some tests comparing output from `system` calls to
  `bin/ldiff` with some pre-generated output. Resolved [#6][] with these tests.

- Resolved a previously undetected `bin/ldiff` issue with `--context` output not
  matching `diff --context` output.

- Resolved an issue with later versions of Ruby not working with an `OptParse`
  specification of `Numeric`; this has been changed to `Integer`.

- Brandon Fish added truffleruby in [#52][].

- Fixed two missing classes as reported in [#53][].

## 1.3 / 2017-01-18

- Bugs fixed:

  - Fixed an error for bin/ldiff --version. Fixes issue [#21][].

  - Force Diff::LCS::Change and Diff::LCS::ContextChange to only perform
    equality comparisons against themselves. Provided by Kevin Mook in pull
    request [#29][].

  - Fix tab expansion in htmldiff, provided by Mark Friedgan in pull request
    [#25][].

  - Silence Ruby 2.4 Fixnum deprecation warnings. Fixes issue [#38][] and pull
    request [#36][].

  - Ensure that test dependencies are loaded properly. Fixes issue [#33][] and
    pull request [#34][].

  - Fix issue [#1][] with incorrect intuition of patch direction. Tentative fix,
    but the previous failure cases pass now.

- Tooling changes:

  - Added SimpleCov and Coveralls support.

  - Change the homepage (temporarily) to the GitHub repo.

  - Updated testing and gem infrastructure.

  - Modernized the specs.

- Cleaned up documentation.

- Added a Code of Conduct.

## 1.2.5 / 2013-11-08

- Bugs fixed:

  - Comparing arrays flattened them too far, especially with Diff::LCS.sdiff.
    Fixed by Josh Bronson in pull request [#23][].

## 1.2.4 / 2013-04-20

- Bugs fixed:

  - A bug was introduced after 1.1.3 when pruning common sequences at the start
    of comparison. Paul Kunysch (@pck) fixed this in pull request [#18][].
    Thanks!

  - The Rubinius (1.9 mode) bug in [rubinius/rubinius#2268][] has been fixed by
    the Rubinius team two days after it was filed. Thanks for fixing this so
    quickly!

- Switching to Raggi's hoe-gemspec2 for gemspec generation.

## 1.2.3 / 2013-04-11

- Bugs Fixed:

  - The new encoding detection for diff output generation (added in 1.2.2)
    introduced a bug if the left side of the comparison was the empty set.
    Originally found in [rspec/rspec-expectations#238][] and
    [rspec/rspec-expectations#239][]. Jon Rowe developed a reasonable heuristic
    (left side, right side, empty string literal) to avoid this bug.

  - There is a known issue with Rubinius in 1.9 mode reported in
    [rubinius/rubinius#2268][] and demonstrated in the Travis CI builds. For all
    other tested platforms, diff-lcs is considered stable. As soon as a suitably
    small test-case can be created for the Rubinius team to examine, this will
    be added to the Rubinius issue around this.

## 1.2.2 / 2013-03-30

- Bugs Fixed:

  - Diff::LCS::Hunk could not properly generate a difference for comparison sets
    that are not US-ASCII-compatible because of the use of literal regular
    expressions and strings. Jon Rowe found this in
    [rspec/rspec-expectations#219][] and provided a first pass implementation in
    pull request [#15][]. I've reworked it because of test failures in Rubinius
    when running in Ruby 1.9 mode. This coerces the added values to the encoding
    of the old dataset (as determined by the first piece of the old dataset).

  - Adding Travis CI testing for Ruby 2.0.

## 1.2.1 / 2013-02-09

- Bugs Fixed:

  - As seen in [rspec/rspec-expectations#200][], the release of Diff::LCS 1.2
    introduced an unnecessary public API change to Diff::LCS::Hunk (see the
    change at [rspec/rspec-expectations@3d6fc82c][] for details). The new method
    name (and behaviour) is more correct, but I should not have renamed the
    function or should have at least provided an alias. This release restores
    Diff::LCS::Hunk#unshift as an alias to #merge. Note that the old #unshift
    behaviour was incorrect and will not be restored.

## 1.2.0 / 2013-01-21

- Minor Enhancements:

  - Added special case handling for Diff::LCS.patch so that it handles patches
    that are empty or contain no changes.

  - Added two new methods (#patch_me and #unpatch_me) to the includable module.

- Bugs Fixed:

  - Fixed issue [#1][] patch direction detection.

  - Resolved issue [#2][] by handling `string[string.size, 1]` properly (it
    returns `""` not `nil`).

  - Michael Granger (ged) fixed an implementation error in Diff::LCS::Change and
    added specs in pull request [#8][]. Thanks!

  - Made the code auto-testable.

  - Vít Ondruch (voxik) provided the latest version of the GPL2 license file in
    pull request [#10][]. Thanks!

  - Fixed a documentation issue with the includable versions of #patch! and
    #unpatch! where they implied that they would replace the original value.
    Given that Diff::LCS.patch always returns a copy, the documentation was
    incorrect and has been corrected. To provide the behaviour that was
    originally documented, two new methods were added to provide this behaviour.
    Found by scooter-dangle in issue [#12][]. Thanks!

- Code Style Changes:

  - Removed trailing spaces.

  - Calling class methods using `.` instead of `::`.

  - Vít Ondruch (voxik) removed unnecessary shebangs in pull request [#9][].
    Thanks!

  - Kenichi Kamiya (kachick) removed some warnings of an unused variable in
    lucky pull request [#13][]. Thanks!

  - Embarked on a major refactoring to make the files a little more manageable
    and understand the code on a deeper level.

  - Adding to http://travis-ci.org.

## 1.1.3 / 2011-08-27

- Converted to 'hoe' for release.

- Converted tests to RSpec 2.

- Extracted the body of htmldiff into a class available from diff/lcs/htmldiff.

- Migrated development and issue tracking to GitHub.

- Bugs fixed:

  - Eliminated the explicit use of RubyGems in both bin/htmldiff and bin/ldiff.
    Resolves issue [#4][].

  - Eliminated Ruby warnings. Resolves issue [#3][].

## 1.1.2 / 2004-10-20

- Fixed a problem reported by Mauricio Fernandez in htmldiff.

## 1.1.1 / 2004-09-25

- Fixed bug #891 (Set returned from patch command does not contain last equal
  part).

- Fixed a problem with callback initialisation code (it assumed that all
  callbacks passed as classes can be initialised; now, it rescues NoMethodError
  in the event of private :new being called).

- Modified the non-initialisable callbacks to have a private #new method.

- Moved ldiff core code to Diff::LCS::Ldiff (diff/lcs/ldiff.rb).

## 1.1.0

- Eliminated the need for Diff::LCS::Event and removed it.

- Added a contextual diff callback, Diff::LCS::ContextDiffCallback.

- Implemented patching/unpatching for standard Diff callback output formats with
  both #diff and #sdiff.

- Extensive documentation changes.

## 1.0.4

- Fixed a problem with bin/ldiff output, especially for unified format. Newlines
  that should have been present weren't.

- Changed the .tar.gz installer to generate Windows batch files if ones do not
  exist already. Removed the existing batch files as they didn't work.

## 1.0.3

- Fixed a problem with #traverse_sequences where the first difference from the
  left sequence might not be appropriately captured.

## 1.0.2

- Fixed an issue with ldiff not working because actions were changed from
  symbols to strings.

## 1.0.1

- Minor modifications to the gemspec, the README.

- Renamed the diff program to ldiff (as well as the companion batch file) so as
  to not collide with the standard diff program.

- Fixed issues with RubyGems. Requires RubyGems > 0.6.1 or >= 0.6.1 with the
  latest CVS version.

## 1.0

- Initial release based mostly on Perl's Algorithm::Diff.

[#1]: https://github.com/halostatue/diff-lcs/issues/1
[#2]: https://github.com/halostatue/diff-lcs/issues/2
[#3]: https://github.com/halostatue/diff-lcs/issues/3
[#4]: https://github.com/halostatue/diff-lcs/issues/4
[#5]: https://github.com/halostatue/diff-lcs/issues/5
[#6]: https://github.com/halostatue/diff-lcs/issues/6
[#8]: https://github.com/halostatue/diff-lcs/pull/8
[#9]: https://github.com/halostatue/diff-lcs/pull/9
[#10]: https://github.com/halostatue/diff-lcs/pull/10
[#12]: https://github.com/halostatue/diff-lcs/issues/12
[#13]: https://github.com/halostatue/diff-lcs/pull/13
[#15]: https://github.com/halostatue/diff-lcs/pull/15
[#18]: https://github.com/halostatue/diff-lcs/pull/18
[#21]: https://github.com/halostatue/diff-lcs/issues/21
[#23]: https://github.com/halostatue/diff-lcs/pull/23
[#25]: https://github.com/halostatue/diff-lcs/pull/25
[#29]: https://github.com/halostatue/diff-lcs/pull/29
[#33]: https://github.com/halostatue/diff-lcs/issues/33
[#34]: https://github.com/halostatue/diff-lcs/pull/34
[#35]: https://github.com/halostatue/diff-lcs/issues/35
[#36]: https://github.com/halostatue/diff-lcs/pull/36
[#38]: https://github.com/halostatue/diff-lcs/issues/38
[#43]: https://github.com/halostatue/diff-lcs/issues/43
[#44]: https://github.com/halostatue/diff-lcs/issues/44
[#47]: https://github.com/halostatue/diff-lcs/pull/47
[#48]: https://github.com/halostatue/diff-lcs/issues/48
[#49]: https://github.com/halostatue/diff-lcs/pull/49
[#52]: https://github.com/halostatue/diff-lcs/pull/52
[#53]: https://github.com/halostatue/diff-lcs/issues/53
[#57]: https://github.com/halostatue/diff-lcs/issues/57
[#58]: https://github.com/halostatue/diff-lcs/pull/58
[#59]: https://github.com/halostatue/diff-lcs/pull/59
[#60]: https://github.com/halostatue/diff-lcs/issues/60
[#61]: https://github.com/halostatue/diff-lcs/pull/61
[#63]: https://github.com/halostatue/diff-lcs/issues/63
[#65]: https://github.com/halostatue/diff-lcs/issues/65
[#69]: https://github.com/halostatue/diff-lcs/issues/69
[#71]: https://github.com/halostatue/diff-lcs/issues/71
[#72]: https://github.com/halostatue/diff-lcs/issues/72
[#73]: https://github.com/halostatue/diff-lcs/issues/73
[#75]: https://github.com/halostatue/diff-lcs/issues/75
[#79]: https://github.com/halostatue/diff-lcs/issues/79
[#80]: https://github.com/halostatue/diff-lcs/issues/80
[#82]: https://github.com/halostatue/diff-lcs/pull/82
[#84]: https://github.com/halostatue/diff-lcs/pull/84
[#86]: https://github.com/halostatue/diff-lcs/pull/86
[#89]: https://github.com/halostatue/diff-lcs/pull/89
[#90]: https://github.com/halostatue/diff-lcs/pull/90
[#91]: https://github.com/halostatue/diff-lcs/issues/91
[rspec/rspec-expectations#200]: https://github.com/rspec/rspec-expectations/pull/200
[rspec/rspec-expectations#219]: https://github.com/rspec/rspec-expectations/issues/219
[rspec/rspec-expectations#238]: https://github.com/rspec/rspec-expectations/issues/238
[rspec/rspec-expectations#239]: https://github.com/rspec/rspec-expectations/issues/239
[rspec/rspec-expectations@3d6fc82c]: https://github.com/rspec/rspec-expectations/commit/3d6fc82c
[rubinius/rubinius#2268]: https://github.com/rubinius/rubinius/issues/2268
[standard ruby]: https://github.com/standardrb/standard
