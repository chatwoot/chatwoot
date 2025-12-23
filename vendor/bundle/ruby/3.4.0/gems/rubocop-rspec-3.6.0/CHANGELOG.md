# Changelog

## Master (Unreleased)

## 3.6.0 (2025-04-18)

- Fix false positive in `RSpec/Pending`, where it would mark the default block `it` as an offense. ([@bquorning])
- Fix issue when `Style/ContextWording` is configured with a Prefix being interpreted as a boolean, like `on`. ([@sakuro])
- Add new `RSpec/IncludeExamples` cop to enforce using `it_behaves_like` over `include_examples`. ([@dvandersluis])
- Change `RSpec/ScatteredSetup` to allow `around` hooks to be scattered. ([@ydah])
- Fix an error `RSpec/ChangeByZero` cop when without expect block. ([@lee266])
- Fix a false positive for `RSpec/DescribedClass` when `SkipBlocks` is true and numblocks are used. ([@earlopain])

## 3.5.0 (2025-02-16)

- Don't let `RSpec/PredicateMatcher` replace `respond_to?` with two arguments with the RSpec `respond_to` matcher. ([@bquorning])
- Fix `RSpec/PredicateMatcher` support for `eql` and `equal` matchers. ([@bquorning])
- Pluginfy RuboCop RSpec. ([@koic])

## 3.4.0 (2025-01-20)

- Fix `RSpec/SortMetadata` cop to limit sorting to trailing metadata arguments. ([@cbliard])
- Replace `RSpec/StringAsInstanceDoubleConstant` with `RSpec/VerifiedDoubleReference` configured to only support constant class references. ([@corsonknowles])
- Fix `RSpec/EmptyExampleGroup` cop false positive when a simple conditional is used inside an iterator. ([@lovro-bikic])

## 3.3.0 (2024-12-12)

- Deprecate `top_level_group?` method from `TopLevelGroup` mixin as all of its callers were intentionally removed from `Rubocop/RSpec`. ([@corsonknowles])
- Fix false positive for RSpec/EmptyMetadata for splat kwargs. ([@pirj])

## 3.2.0 (2024-10-26)

- Fix `RSpec/VoidExpect` to only operate inside an example block. ([@corsonknowles])
- Change `RSpec/ContextWording` cop to always report an offense when both `Prefixes` and `AllowedPatterns` are empty. ([@ydah])
- Add support for `and` and `or` compound matchers to `RSpec/ChangeByZero` cop. ([@ydah])

## 3.1.0 (2024-10-01)

- Add `RSpec/StringAsInstanceDoubleConstant` to check for and correct strings used as instance_doubles. ([@corsonknowles])
- Fix false-positive for `RSpec/UnspecifiedException` when a method is literally named `raise_exception`. ([@aarestad])
- Fix false-positive for `RSpec/UnspecifiedException` when `not_to raise_error` is used within a block. ([@aarestad], [@G-Rath])

## 3.0.5 (2024-09-07)

- Fix false-negative and error for `RSpec/MetadataStyle` when non-literal args are used in metadata in `EnforceStyle: hash`. ([@cbliard])
- Improve offense message for `RSpec/IndexedLet`. ([@earlopain])

## 3.0.4 (2024-08-05)

- Fix false-negative for `UnspecifiedException` when matcher is chained. ([@r7kamura])

## 3.0.3 (2024-07-12)

- Add support for Unicode RIGHT SINGLE QUOTATION MARK in `RSpec/ExampleWording`. ([@jdufresne])
- Suppress deprecation warning for `RSpec/MultipleExpectations`, `RSpec/MultipleMemoizedHelpers`, and `RSpec/NestedGroups` cops. ([@koic])

## 3.0.2 (2024-07-02)

- Fix wrong autocorrect for `RSpec/ScatteredSetup` when hook contains heredoc. ([@earlopain])
- Fix false negative for `RSpec/PredicateMatcher` when expectation contains custom failure message. ([@earlopain])
- Facilitate the 3.0 upgrade flow with proper extracted cop messages. ([@jeppester])

## 3.0.1 (2024-06-11)

- Bump RuboCop requirement to +1.61. ([@ydah])

## 3.0.0 (2024-06-11)

- Remove extracted cops in `Capybara`, `FactoryBot` and `Rails` departments. ([@ydah])
- Remove `RuboCop::RSpec::Language::NodePattern`. ([@ydah])
- Remove `RSpec/FilePath` cop. ([@ydah])
- Remove `RSpec/Capybara/FeatureMethods` cop. If you are using this cop, change it to use `RSpec/Dialect`. ([@ydah])
- Add new `RSpec/MissingExpectationTargetMethod` cop. ([@krororo])
- Fix an error for `RSpec/ScatteredSetup` when one of the hooks is an empty block. ([@earlopain])

These previously pending cops are now enabled by default: `RSpec/BeEmpty`, `RSpec/BeEq`, `RSpec/BeNil`, `RSpec/ChangeByZero`, `RSpec/ClassCheck`, `RSpec/ContainExactly`, `RSpec/DuplicatedMetadata`, `RSpec/EmptyMetadata`, `RSpec/EmptyOutput`, `RSpec/Eq`, `RSpec/ExcessiveDocstringSpacing`, `RSpec/ExpectInLet`, `RSpec/IdenticalEqualityAssertion`, `RSpec/IndexedLet`, `RSpec/IsExpectedSpecify`, `RSpec/MatchArray`, `RSpec/MetadataStyle`, `RSpec/NoExpectationExample`, `RSpec/PendingWithoutReason`, `RSpec/ReceiveMessages`, `RSpec/RedundantAround`, `RSpec/RedundantPredicateMatcher`, `RSpec/RemoveConst`, `RSpec/RepeatedSubjectCall`, `RSpec/SkipBlockInsideExample`, `RSpec/SortMetadata`, `RSpec/SpecFilePathFormat`, `RSpec/SpecFilePathSuffix`, `RSpec/SubjectDeclaration`, `RSpec/UndescriptiveLiteralsDescription`, and `RSpec/VerifiedDoubleReference`.

Read more about how to upgrade in https://docs.rubocop.org/rubocop-rspec/upgrade_to_version_3.html

## 2.31.0 (2024-06-07)

- Support `AutoCorrect: contextual` option for LSP. ([@ydah])

## 2.30.0 (2024-06-03)

- Add new `RSpec/ExpectInLet` cop. ([@yasu551])

## 2.29.2 (2024-05-02)

- Fix beginless and endless range bug for RepeatedIncludeExample cop. ([@hasghari])
- Fix a false positive for `RSpec/RepeatedSubjectCall` when subject is used as argument to function call. ([@K-S-A])

## 2.29.1 (2024-04-05)

- Fix an error in the default configuration. ([@ydah])

## 2.29.0 (2024-04-04)

- Fix an autocorrect error for `RSpec/ExpectActual`. ([@bquorning])
- Add new `RSpec/UndescriptiveLiteralsDescription` cop. ([@ydah])
- Add new `RSpec/EmptyOutput` cop. ([@bquorning])

## 2.28.0 (2024-03-30)

- Extract RSpec Rails cops to a separate repository, [`rubocop-rspec_rails`](https://github.com/rubocop/rubocop-rspec_rails). The `rubocop-rspec_rails` repository is a dependency of `rubocop-rspec` and the cops related to rspec-rails are aliased (`RSpec/Rails/Foo` == `RSpecRails/Foo`) until v3.0 is released, so the change will be invisible to users until then. ([@ydah])

## 2.27.1 (2024-03-03)

- Fix a false positive for `RSpec/RepeatedSubjectCall` when `subject.method_call`. ([@ydah])
- Add configuration option `OnlyStaticConstants` to `RSpec/DescribedClass`. ([@ydah])

## 2.27.0 (2024-03-01)

- Add new `RSpec/IsExpectedSpecify` cop. ([@ydah])
- Add new `RSpec/RepeatedSubjectCall` cop. ([@drcapulet])
- Add support for `assert_true`, `assert_false`, `assert_not_equal`, `assert_not_nil`, `*_empty`, `*_predicate`, `*_kind_of`, `*_in_delta`, `*_match`, `*_instance_of` and `*_includes` assertions in `RSpec/Rails/MinitestAssertions`. ([@ydah], [@G-Rath])
- Support asserts with messages in `RSpec/BeEmpty`. ([@G-Rath])
- Fix a false positive for `RSpec/ExpectActual` when used with rspec-rails routing matchers. ([@naveg])
- Add configuration option `ResponseMethods` to `RSpec/Rails/HaveHttpStatus`. ([@ydah])
- Fix a false negative for `RSpec/DescribedClass` when class with constant. ([@ydah])
- Fix a false positive for `RSpec/ExampleWithoutDescription` when `specify` with multi-line block and missing description. ([@ydah])
- Fix an incorrect autocorrect for `RSpec/ChangeByZero` when compound expectations with line break before `.by(0)`. ([@ydah])

## 2.26.1 (2024-01-05)

- Fix an error for `RSpec/SharedExamples` when using examples without argument. ([@ydah])

## 2.26.0 (2024-01-04)

- Add new `RSpec/RedundantPredicateMatcher` cop. ([@ydah])
- Add new `RSpec/RemoveConst` cop. ([@swelther])
- Add support for correcting "it will" (future tense) for `RSpec/ExampleWording`. ([@jdufresne])
- Add support for `symbol` style for `RSpec/SharedExamples`. ([@jessieay])
- Ensure `PendingWithoutReason` can detect violations inside shared groups. ([@robinaugh])

## 2.25.0 (2023-10-27)

- Add support single quoted string and percent string and heredoc for `RSpec/Rails/HttpStatus`. ([@ydah])
- Change to be inline disable for `RSpec/SpecFilePathFormat` like `RSpec/FilePath`. ([@ydah])
- Fix a false positive for `RSpec/MetadataStyle` with example groups having multiple string arguments. ([@franzliedke])

## 2.24.1 (2023-09-23)

- Fix an error when using `RSpec/FilePath` and revert to enabled by default. If you have already moved to `RSpec/SpecFilePathSuffix` and `RSpec/SpecFilePathFormat`, disable `RSpec/FilePath` explicitly as `Enabled: false`. The `RSpec/FilePath` before migration and the `RSpec/SpecFilePathSuffix` and `RSpec/SpecFilePathFormat` as the target are available respectively. ([@ydah])

## 2.24.0 (2023-09-08)

- Split `RSpec/FilePath` into `RSpec/SpecFilePathSuffix` and `RSpec/SpecFilePathFormat`. `RSpec/FilePath` cop is disabled by default and the two new cops are pending and need to be enabled explicitly. ([@ydah])
- Add new `RSpec/Eq` cop. ([@ydah])
- Add `RSpec/MetadataStyle` and `RSpec/EmptyMetadata` cops. ([@r7kamura])
- Add support `RSpec/Rails/HttpStatus` when `have_http_status` with string argument. ([@ydah])
- Fix an infinite loop error when `RSpec/ExcessiveDocstringSpacing` finds a description with non-ASCII leading/trailing whitespace. ([@bcgraham])
- Fix an incorrect autocorrect for `RSpec/ReceiveMessages` when return values declared between stubs. ([@marocchino])
- Fix a false positive `RSpec/Focus` when chained method call and inside define method. ([@ydah])

## 2.23.2 (2023-08-09)

- Fix an incorrect autocorrect for `RSpec/ReceiveMessages` when method is only non-word character. ([@marocchino])
- Fix a false positive for `RSpec/ReceiveMessages` when return with splat. ([@marocchino])

## 2.23.1 (2023-08-07)

- Mark to `Safe: false` for `RSpec/Rails/NegationBeValid` cop. ([@ydah])
- Declare autocorrect as unsafe for `RSpec/ReceiveMessages`. ([@bquorning])

## 2.23.0 (2023-07-30)

- Add new `RSpec/Rails/NegationBeValid` cop. ([@ydah])
- Fix a false negative for `RSpec/ExcessiveDocstringSpacing` when finds description with em space. ([@ydah])
- Fix a false positive for `RSpec/EmptyExampleGroup` when example group with examples defined in `if` branch inside iterator. ([@ydah])
- Update the message output of `RSpec/ExpectActual` to include the word 'value'. ([@corydiamand])
- Fix a false negative for `RSpec/Pending` when `it` without body. ([@ydah])
- Add new `RSpec/ReceiveMessages` cop. ([@ydah])
- Change default.yml path to use `**/spec/*` instead of `spec/*`. ([@ydah])
- Add `AllowedIdentifiers` and `AllowedPatterns` configuration option to `RSpec/IndexedLet`. ([@ydah])
- Fix `RSpec/NamedSubject` when block has no body. ([@splattael])
- Fix `RSpec/LetBeforeExamples` autocorrect incompatible with `RSpec/ScatteredLet` autocorrect. ([@ydah])
- Update `RSpec/Focus` to support `shared_context` and `shared_examples`. ([@tmaier])

## 2.22.0 (2023-05-06)

- Extract factory_bot cops to a separate repository, [`rubocop-factory_bot`](https://github.com/rubocop/rubocop-factory_bot). The `rubocop-factory_bot` repository is a dependency of `rubocop-rspec` and the factory_bot cops are aliased (`RSpec/FactoryBot/Foo` == `FactoryBot/Foo`) until v3.0 is released, so the change will be invisible to users until then. ([@ydah])

## 2.21.0 (2023-05-05)

- Fix a false positive in `RSpec/IndexedLet` with suffixes after index-like numbers. ([@pirj])
- Fix an error for `RSpec/Rails/HaveHttpStatus` with comparison with strings containing non-numeric characters. ([@ydah])
- Fix an error for `RSpec/MatchArray` when `match_array` with no argument. ([@ydah])
- Add support `a_block_changing` and `changing` for `RSpec/ChangeByZero`. ([@ydah])
- Drop Ruby 2.6 support. ([@ydah])

## 2.20.0 (2023-04-18)

- Add new `RSpec/IndexedLet` cop. ([@dmitrytsepelev])
- Add new `RSpec/BeEmpty` cop. ([@ydah], [@bquorning])
- Add autocorrect support for `RSpec/ScatteredSetup`. ([@ydah])
- Add support `be_status` style for `RSpec/Rails/HttpStatus`. ([@ydah])
- Add support for shared example groups to `RSpec/EmptyLineAfterExampleGroup`. ([@pirj])
- Add support for `RSpec/HaveHttpStatus` when using `response.code`. ([@ydah])
- Fix order of expected and actual in correction for `RSpec/Rails/MinitestAssertions`. ([@mvz])
- Fix a false positive for `RSpec/DescribedClassModuleWrapping` when RSpec.describe numblock is nested within a module. ([@ydah])
- Fix a false positive for `RSpec/FactoryBot/ConsistentParenthesesStyle` inside `&&`, `||` and `:?` when `omit_parentheses` is on. ([@dmitrytsepelev])
- Fix a false positive for `RSpec/PendingWithoutReason` when pending/skip has a reason inside an example group. ([@ydah])
- Fix a false negative for `RSpec/RedundantAround` when redundant numblock `around`. ([@ydah])
- Change `RSpec/ContainExactly` to ignore calls with no arguments, and change `RSpec/MatchArray` to ignore calls with an empty array literal argument. ([@ydah], [@bquorning])
- Make `RSpec/MatchArray` and `RSpec/ContainExactly` pending. ([@ydah])

## 2.19.0 (2023-03-06)

- Fix a false positive for `RSpec/ContextWording` when context is interpolated string literal or execute string. ([@ydah])
- Fix a false positive for `RSpec/DescribeMethod` when multi-line describe without `#` and `.` at the beginning. ([@ydah], [@pirj])
- Fix a false positive for `RSpec/VariableName` when inside non-spec code. ([@ydah])
- Fix a false positive for `RSpec/VariableDefinition` when inside non-spec code. ([@ydah])
- Add new `RSpec/PendingBlockInsideExample` cop. ([@ydah])
- Add `RSpec/RedundantAround` cop. ([@r7kamura])
- Add `RSpec/Rails/TravelAround` cop. ([@r7kamura])
- Add `RSpec/ContainExactly` and `RSpec/MatchArray` cops. ([@faucct])
- Fix a false positive for `RSpec/PendingWithoutReason` when not inside example and pending/skip with block. ([@ydah], [@pirj])
- Fix a false positive for `RSpec/PendingWithoutReason` when `skip` is passed a block inside example. ([@ydah], [@pirj])
- Rename `RSpec/PendingBlockInsideExample` cop to `RSpec/SkipBlockInsideExample`. ([@pirj])
- Deprecate `send_pattern`/`block_pattern`/`numblock_pattern` helpers in favour of using node pattern explicitly. ([@pirj], [@ydah])
- Fix an incorrect autocorrect for `RSpec/VerifiedDoubleReference` when namespaced class. ([@ydah])

## 2.18.1 (2023-01-19)

- Add `rubocop-capybara` version constraint to prevent sudden cop enabling when it hits 3.0. ([@pirj])

## 2.18.0 (2023-01-16)

- Extract Capybara cops to a separate repository, [`rubocop-capybara`](https://github.com/rubocop/rubocop-capybara). The `rubocop-capybara` repository is a dependency of `rubocop-rspec` and the Capybara cops are aliased (`RSpec/Capybara/Foo` == `Capybara/Foo`) until v3.0 is released, so the change will be invisible to users until then. ([@pirj])

## 2.17.1 (2023-01-16)

- Fix a false negative for `RSpec/Pending` when using skipped in metadata is multiline string. ([@ydah])
- Fix a false positive for `RSpec/NoExpectationExample` when using skipped in metadata is multiline string. ([@ydah])
- Fix a false positive for `RSpec/ContextMethod` when multi-line context with `#` at the beginning. ([@ydah])
- Fix an incorrect autocorrect for `RSpec/PredicateMatcher` when multiline expect and predicate method with heredoc. ([@ydah])
- Fix a false positive for `RSpec/PredicateMatcher` when `include` with multiple argument. ([@ydah])

## 2.17.0 (2023-01-13)

- Fix a false positive for `RSpec/PendingWithoutReason` when pending/skip is argument of methods. ([@ydah])
- Add new `RSpec/Capybara/MatchStyle` cop. ([@ydah])
- Add new `RSpec/Rails/MinitestAssertions` cop. ([@ydah])
- Fix a false positive for `RSpec/PendingWithoutReason` when not inside example. ([@ydah])
- Fix a false negative for `RSpec/PredicateMatcher` when using `include` and `respond_to`. ([@ydah])
- Fix a false positive for `RSpec/StubbedMock` when stubbed message expectation with a block and block parameter. ([@ydah])

## 2.16.0 (2022-12-13)

- Add new `RSpec/FactoryBot/FactoryNameStyle` cop. ([@ydah])
- Improved processing speed for `RSpec/Be`, `RSpec/ExpectActual`, `RSpec/ImplicitExpect`, `RSpec/MessageSpies`, `RSpec/PredicateMatcher` and `RSpec/Rails/HaveHttpStatus`. ([@ydah])
- Fix wrong autocorrection in `n_times` style on `RSpec/FactoryBot/CreateList`. ([@r7kamura])
- Fix a false positive for `RSpec/FactoryBot/ConsistentParenthesesStyle` when using `generate` with multiple arguments. ([@ydah])
- Mark `RSpec/BeEq` as `Safe: false`. ([@r7kamura])
- Add `RSpec/DuplicatedMetadata` cop. ([@r7kamura])
- Mark `RSpec/BeEql` as `Safe: false`. ([@r7kamura])
- Add `RSpec/PendingWithoutReason` cop. ([@r7kamura])

## 2.15.0 (2022-11-03)

- Fix a false positive for `RSpec/RepeatedDescription` when different its block expectations are used. ([@ydah])
- Add `named_only` style to `RSpec/NamedSubject`. ([@kuahyeow])
- Fix `RSpec/FactoryBot/ConsistentParenthesesStyle` to ignore calls without the first positional argument. ([@pirj])
- Fix `RSpec/FactoryBot/ConsistentParenthesesStyle` to ignore calls inside a Hash or an Array. ([@pirj])
- Fix `RSpec/NestedGroups` to correctly use `AllowedGroups` config. ([@samrjenkins])
- Remove `Runners` and `HookScopes` RSpec DSL elements from configuration. ([@pirj])
- Add `with default RSpec/Language config` helper to `lib` (under `rubocop/rspec/shared_contexts/default_rspec_language_config_context`), to allow use for downstream cops based on `RuboCop::Cop::RSpec::Base`. ([@smcgivern])

## 2.14.2 (2022-10-25)

- Fix an incorrect autocorrect for `FactoryBot/ConsistentParenthesesStyle` with `omit_parentheses` option when method name and first argument are not on same line. ([@ydah])
- Fix autocorrection loop in `RSpec/ExampleWording` for insufficient example wording. ([@pirj])
- Fix `RSpec/SortMetadata` not to reorder arguments of `include_`/`it_behaves_like`. ([@pirj])
- Fix a false positive for `RSpec/NoExpectationExample` when allowed pattern methods with arguments. ([@ydah])
- Change `RSpec/FilePath` so that it only checks suffix when path is under spec/routing or type is defined as routing. ([@r7kamura])

## 2.14.1 (2022-10-24)

- Fix an error for `RSpec/Rails/InferredSpecType` with redundant type before other Hash metadata. ([@ydah])

## 2.14.0 (2022-10-23)

- Add `require_implicit` style to `RSpec/ImplicitSubject`. ([@r7kamura])
- Fix a false positive for `RSpec/Capybara/SpecificMatcher` when `have_css("a")` without attribute. ([@ydah])
- Update `RSpec/ExampleWording` cop to raise error for insufficient descriptions. ([@akrox58])
- Add new `RSpec/Capybara/NegationMatcher` cop. ([@ydah])
- Add `AllowedPatterns` configuration option to `RSpec/NoExpectationExample`. ([@ydah])
- Improve `RSpec/NoExpectationExample` cop to ignore examples skipped or pending via metadata. ([@pirj])
- Add `RSpec/FactoryBot/ConsistentParenthesesStyle` cop. ([@Liberatys])
- Add `RSpec/Rails/InferredSpecType` cop. ([@r7kamura])
- Add new `RSpec/Capybara/SpecificActions` cop. ([@ydah])
- Update `config/default.yml` removing deprecated option to make the config correctable by users. ([@ignaciovillaverde])
- Do not attempt to auto-correct example groups with `include_examples` in `RSpec/LetBeforeExamples`. ([@pirj])
- Add new `RSpec/SortMetadata` cop. ([@leoarnold])
- Add support for subject! method to `RSpec/SubjectDeclaration`. ([@ydah])

## 2.13.2 (2022-09-23)

- Fix an error for `RSpec/Capybara/SpecificFinders` with no parentheses. ([@ydah])
- Fix a false positive for `RSpec/NoExpectationExample` with pending using `skip` or `pending` inside an example. ([@ydah])
- Exclude `have_text` and `have_content` that raise `ArgumentError` with `RSpec/Capybara/VisibilityMatcher` where `:visible` is an invalid option. ([@ydah])
- Fix a false negative for `RSpec/Capybara/VisibilityMatcher` with negative matchers. ([@ydah])

## 2.13.1 (2022-09-12)

- Include config/obsoletion.yml in the gemspec. ([@hosamaly])

## 2.13.0 (2022-09-12)

- Fix `RSpec/FilePath` cop missing mismatched expanded namespace. ([@sl4vr])
- Add new `AllowConsecutiveOneLiners` (default true) option for `RSpec/EmptyLineAfterHook` cop. ([@ngouy])
- Add autocorrect support for `RSpec/EmptyExampleGroup`. ([@r7kamura])
- Fix `RSpec/ChangeByZero` with compound expressions using `&` or `|` operators. ([@BrianHawley])
- Add `RSpec/NoExpectationExample`. ([@r7kamura])
- Add some expectation methods to default configuration. ([@r7kamura])
- Fix a false positive for `RSpec/Capybara/SpecificMatcher`. ([@ydah])
- Fix a false negative for `RSpec/Capybara/SpecificMatcher` for `have_field`. ([@ydah])
- Fix a false positive for `RSpec/Capybara/SpecificMatcher` when may not have a `href` by `have_link`. ([@ydah])
- Add `NegatedMatcher` configuration option to `RSpec/ChangeByZero`. ([@ydah])
- Add new `RSpec/Capybara/SpecificFinders` cop. ([@ydah])
- Add support for numblocks to `RSpec/AroundBlock`, `RSpec/EmptyLineAfterHook`, `RSpec/ExpectInHook`, `RSpec/HookArgument`, `RSpec/HooksBeforeExamples`, `RSpec/IteratedExpectation`, and `RSpec/NoExpectationExample`. ([@ydah])
- Fix incorrect documentation URLs when using `rubocop --show-docs-url`. ([@r7kamura])
- Add `AllowedGroups` configuration option to `RSpec/NestedGroups`. ([@ydah])
- Deprecate `IgnoredPatterns` option in favor of the `AllowedPatterns` options. ([@ydah])
- Add `AllowedPatterns` configuration option to `RSpec/ContextWording`. ([@ydah])
- Add `RSpec/ClassCheck` cop. ([@r7kamura])
- Fix a false positive for `RSpec/Capybara/SpecificMatcher` when pseudo-classes. ([@ydah])
- Fix a false negative for `RSpec/SubjectStub` when the subject is declared with the `subject!` method and called by name. ([@eikes])
- Support `Array.new(n)` on `RSpec/FactoryBot/CreateList` cop. ([@r7kamura])

## 2.12.1 (2022-07-03)

- Fix a false positive for `RSpec/Capybara/SpecificMatcher`. ([@ydah])

## 2.12.0 (2022-07-02)

- Fix incorrect path suggested by `RSpec/FilePath` cop when second argument contains spaces. ([@tejasbubane])
- Fix autocorrect for EmptyLineSeparation. ([@johnny-miyake])
- Add new `RSpec/Capybara/SpecificMatcher` cop. ([@ydah])
- Fixed false offense detection in `FactoryBot/CreateList` when a n.times block is including method calls in the factory create arguments. ([@ngouy])
- Fix error in `RSpec/RSpec/FactoryBot/CreateList` cop for empty block. ([@tejasbubane])
- Update `RSpec/MultipleExpectations` cop documentation with examples of aggregate_failures use. ([@edgibbs])
- Declare autocorrect as unsafe for `RSpec/VerifiedDoubleReference`. ([@Drowze])
- Add new `RSpec/Rails/HaveHttpStatus` cop. ([@akiomik])

## 2.11.1 (2022-05-18)

- Fix a regression in `RSpec/ExpectChange` flagging chained method calls. ([@pirj])

## 2.11.0 (2022-05-18)

- Drop Ruby 2.5 support. ([@ydah])
- Add new `RSpec/ChangeByZero` cop. ([@ydah])
- Improve `RSpec/ExpectChange` to detect namespaced and top-level constants. ([@M-Yamashita01])
- Introduce an amendment to `Metrics/BlockLength` to exclude spec files. ([@luke-hill])

## 2.10.0 (2022-04-19)

- Fix a false positive for `RSpec/EmptyExampleGroup` when expectations in case statement. ([@ydah])
- Add `RSpec/VerifiedDoubleReference` cop. ([@t3h2mas])
- Make `RSpec/BeNil` cop configurable with a `be_nil` style and a `be` style. ([@bquorning])
- Fix `Capybara/CurrentPathExpectation` autocorrect incompatible with `Style/TrailingCommaInArguments` autocorrect. ([@ydah])

## 2.9.0 (2022-02-28)

- Add new `RSpec/BeNil` cop. ([@bquorning])
- Add new `RSpec/BeEq` cop. ([@bquorning])

## 2.8.0 (2022-01-24)

- Fix `RSpec/FactoryBot/SyntaxMethods` and `RSpec/Capybara/FeatureMethods` to inspect shared groups. ([@pirj])
- Fix `RSpec/LeadingSubject` failure in non-spec code. ([@pirj])
- Add bad example to `RSpec/SubjectStub` cop. ([@oshiro3])
- Replace non-styleguide cops `StyleGuide` attribute with `Reference`. ([@pirj])
- Fix `RSpec/SubjectStub` to disallow stubbing of subjects defined in parent example groups. ([@pirj])

## 2.7.0 (2021-12-26)

- Add new `RSpec/FactoryBot/SyntaxMethods` cop. ([@leoarnold])
- Exclude `task` type specs from `RSpec/DescribeClass` cop. ([@harry-graham])

## 2.6.0 (2021-11-08)

- Fix merging RSpec DSL configuration from third-party gems. ([@pirj])
- Fix `RSpec/ExcessiveDocstringSpacing` false positive for multi-line indented strings. ([@G-Rath])
- Fix `Include` configuration for sub-departments. ([@pirj])
- Ignore heredocs in `RSpec/ExcessiveDocstringSpacing`. ([@G-Rath])
- Stop `RSpec/ExampleWording` from trying to correct heredocs. ([@G-Rath])
- Add autocorrect support for `RSpec/VariableDefinition`. ([@r7kamura])

## 2.5.0 (2021-09-21)

- Declare autocorrect as unsafe for `ExpectChange`. ([@francois-ferrandis])
- Fix each example for `RSpec/HookArgument`. ([@lokhi])
- Exclude unrelated Rails directories from `RSpec/DescribeClass`. ([@MothOnMars])
- Add `RSpec/ExcessiveDocstringSpacing` cop. ([@G-Rath])
- Add `RSpec/SubjectDeclaration` cop. ([@dswij])
- Fix excessive whitespace removal in `RSpec/EmptyHook` autocorrection. ([@pirj])
- Bump RuboCop requirement to v1.19.0. ([@pirj])
- Fix false positive in `RSpec/IteratedExpectation` when there is single, non-expectation statement in the block body. ([@Darhazer])

## 2.4.0 (2021-06-09)

- Update `RSpec/FilePath` to check suffix when given a non-constant top-level node (e.g. features). ([@topalovic])
- Add missing documentation for `single_statement_only` style of `RSpec/ImplicitSubject` cop. ([@tejasbubane])
- Fix an exception in `DescribedClass` when accessing a constant on a variable in a spec that is nested in a namespace. ([@rrosenblum])
- Add new `RSpec/IdenticalEqualityAssertion` cop. ([@tejasbubane])
- Add `RSpec/Rails/AvoidSetupHook` cop. ([@paydaylight])
- Fix false negative in `RSpec/ExpectChange` cop with block style and chained method call. ([@tejasbubane])

## 2.3.0 (2021-04-28)

- Allow `RSpec/ContextWording` to accept multi-word prefixes. ([@hosamaly])
- Drop support for ruby 2.4. ([@bquorning])
- Add `CountAsOne` configuration option to `RSpec/ExampleLength`. ([@stephannv])
- Fix a false positive for `RSpec/RepeatedExampleGroupBody` when `pending` or `skip` have argument(s). ([@Tietew])

## 2.2.0 (2021-02-02)

- Fix `HooksBeforeExamples`, `LeadingSubject`, `LetBeforeExamples` and `ScatteredLet` autocorrection to take into account inline comments and comments immediately before the moved node. ([@Darhazer])
- Improve rubocop-rspec performance. ([@Darhazer], [@bquorning])
- Include `Enabled: true` to prevent a mismatched configuration parameter warning when `RSpec` cops are explicitly enabled in the user configuration. ([@pirj])

## 2.1.0 (2020-12-17)

- Fix `RSpec/FilePath` false positive for relative file path runs with long namespaces. ([@ahukkanen])
- Update `RSpec/Focus` to have auto-correction. ([@dvandersluis])

## 2.0.1 (2020-12-02)

- Fixed infinite loop in `RSpec/ExpectActual` autocorrection when both expected and actual values are literals. ([@Darhazer])

## 2.0.0 (2020-11-06)

- Remove deprecated class `::RuboCop::Cop::RSpec::Cop`. ([@bquorning])
- Retire `RSpec/InvalidPredicateMatcher` cop. ([@pirj])
- Remove the code responsible for filtering files to inspect. ([@pirj])
- Make RSpec language elements configurable. ([@sl4vr])
- Remove `CustomIncludeMethods` `RSpec/EmptyExampleGroup` option in favour of the new RSpec DSL configuration. ([@pirj])
- Enabled pending cop (`RSpec/StubbedMock`). ([@pirj])

## 2.0.0.pre (2020-10-22)

- Update RuboCop dependency to v1.0.0. ([@bquorning])
- Change namespace of several cops (`Capybara/*` -> `RSpec/Capybara/*`, `FactoryBot/*` -> `RSpec/FactoryBot/*`, `Rails/*` -> `RSpec/Rails/*`). ([@pirj], [@bquorning])

## 1.44.1 (2020-10-20)

- Relax `rubocop-ast` version constraint. ([@PhilCoggins])

## 1.44.0 (2020-10-20)

- Move our documentation from rubocop-rspec.readthedocs.io to docs.rubocop.org/rubocop-rspec. ([@bquorning])
- Add `RSpec/RepeatedIncludeExample` cop. ([@biinari])
- Add `RSpec/StubbedMock` cop. ([@bquorning], [@pirj])
- Add `IgnoredMetadata` configuration option to `RSpec/DescribeClass`. ([@Rafix02])
- Fix false positives in `RSpec/EmptyExampleGroup`. ([@pirj])
- Fix a false positive for `RSpec/EmptyExampleGroup` when example is defined in an `if` branch. ([@koic])

## 1.43.2 (2020-08-25)

- Fix `RSpec/FilePath` when checking a file with a shared example. ([@pirj])
- Fix subject nesting detection in `RSpec/LeadingSubject`. ([@pirj])

## 1.43.1 (2020-08-17)

- Fix `RSpec/FilePath` when checking a file defining e.g. an empty class. ([@bquorning])

## 1.43.0 (2020-08-17)

- Add a new base cop class `::RuboCop::Cop::RSpec::Base`. The old base class `::RuboCop::Cop::RSpec::Cop` is deprecated, and will be removed in the next major release. ([@bquorning])
- Add support for subject detection after includes and example groups in `RSpec/LeadingSubject`. ([@pirj])
- Ignore trailing punctuation in context description prefix. ([@elliterate])
- Relax `RSpec/VariableDefinition` cop so interpolated and multiline strings are accepted even when configured to enforce the `symbol` style. ([@bquorning])
- Fix `RSpec/EmptyExampleGroup` to flag example groups with examples in invalid scopes. ([@mlarraz])
- Fix `RSpec/EmptyExampleGroup` to ignore examples groups with examples defined inside iterators. ([@pirj])
- Improve `RSpec/NestedGroups`, `RSpec/FilePath`, `RSpec/DescribeMethod`, `RSpec/MultipleDescribes`, `RSpec/DescribeClass`'s top-level example group detection. ([@pirj])
- Add detection of `let!` with a block-pass or a string literal to `RSpec/LetSetup`. ([@pirj])
- Add `IgnoredPatterns` configuration option to `RSpec/VariableName`. ([@jtannas])
- Add `RSpec/MultipleMemoizedHelpers` cop. ([@mockdeep])

## 1.42.0 (2020-07-09)

- Update RuboCop dependency to 0.87.0 because of changes to internal APIs. ([@bquorning], [@Darhazer])

## 1.41.0 (2020-07-03)

- Extend the list of Rails spec types for `RSpec/DescribeClass`. ([@pirj])
- Fix `FactoryBot/AttributeDefinedStatically` to allow `#traits_for_enum` without a block. ([@harrylewis])
- Improve the performance of `FactoryBot/AttributeDefinedStatically`, `RSpec/InstanceVariable`, `RSpec/LetSetup`, `RSpec/NestedGroups` and `RSpec/ReturnFromStub`. ([@andrykonchin])

## 1.40.0 (2020-06-11)

- Add new `RSpec/VariableName` cop. ([@tejasbubane])
- Add new `RSpec/VariableDefinition` cop. ([@tejasbubane])
- Expand `Capybara/VisibilityMatcher` to support more than just `have_selector`. ([@twalpole])
- Add new `SpecSuffixOnly` option to `RSpec/FilePath` cop. ([@zdennis])
- Allow `RSpec/RepeatedExampleGroupBody` to differ only by described_class. ([@robotdana])
- Fix `RSpec/FilePath` detection across sibling directories. ([@rolfschmidt])
- Improve the performance of `RSpec/SubjectStub` by an order of magnitude. ([@andrykonchin])

## 1.39.0 (2020-05-01)

- Fix `RSpec/FilePath` detection when absolute path includes test subject. ([@eitoball])
- Add new `Capybara/VisibilityMatcher` cop. ([@aried3r])
- Ignore String constants by `RSpec/Describe`. ([@AlexWayfer])
- Drop support for ruby 2.3. ([@bquorning])
- Fix multiple cops to detect `let` with proc argument. ([@tejasbubane])
- Add autocorrect support for `RSpec/ScatteredLet`. ([@Darhazer])
- Add new `RSpec/EmptyHook` cop. ([@tejasbubane])

## 1.38.1 (2020-02-15)

- Fix `RSpec/RepeatedDescription` to detect descriptions with interpolation and methods. ([@lazycoder9])

## 1.38.0 (2020-02-11)

- Fix `RSpec/InstanceVariable` detection inside custom matchers. ([@pirj])
- Fix `RSpec/ScatteredSetup` to distinguish hooks with different metadata. ([@pirj])
- Add autocorrect support for `RSpec/ExpectActual` cop. ([@dduugg], [@pirj])
- Add `RSpec/RepeatedExampleGroupBody` cop. ([@lazycoder9])
- Add `RSpec/RepeatedExampleGroupDescription` cop. ([@lazycoder9])
- Add block name and other lines to `RSpec/ScatteredSetup` message. ([@elebow])
- Fix `RSpec/RepeatedDescription` to take into account example metadata. ([@lazycoder9])

## 1.37.1 (2019-12-16)

- Improve message and description of `FactoryBot/FactoryClassName`. ([@ybiquitous])
- Fix `FactoryBot/FactoryClassName` to ignore `Hash` and `OpenStruct`. ([@jfragoulis])

## 1.37.0 (2019-11-25)

- Implement `RSpec/DescribedClassModuleWrapping` to disallow RSpec statements within a module. ([@kellysutton])
- Fix documentation rake task to support RuboCop 0.75. ([@nickcampbell18])
- Fix `RSpec/SubjectStub` to detect implicit subjects stubbed. ([@QQism])
- Fix `RSpec/Pending` not flagging `skip` with string values. ([@pirj])
- Add `AllowedExplicitMatchers` config option for `RSpec/PredicateMatcher`. ([@mkrawc])
- Add `FactoryBot/FactoryClassName` cop. ([@jfragoulis])

## 1.36.0 (2019-09-27)

- Fix `RSpec/DescribedClass`'s error when `described_class` is used as part of a constant. ([@pirj])
- Fix `RSpec/ExampleWording` autocorrect of multi-line docstrings. ([@pirj])
- Add `RSpec/ContextMethod` cop, to detect method names in `context`. ([@geniou])
- Update RuboCop dependency to 0.68.1 with support for children matching node pattern syntax. ([@pirj])
- Add `RSpec/EmptyLineAfterExample` cop to check that there is an empty line after example blocks. ([@pirj])
- Fix `Capybara/CurrentPathExpectation` auto-corrector, to include option `ignore_query: true`. ([@onumis])
- Fix `RSpec/Focus` detecting mixed array/hash metadata. ([@dgollahon])
- Fix `RSpec/Focus` to also detect `pending` examples. ([@dgollahon])

## 1.35.0 (2019-08-02)

- Add `RSpec/ImplicitBlockExpectation` cop. ([@pirj])

## 1.34.1 (2019-07-31)

- Fix `RSpec/DescribedClass`'s error when a local variable is part of the namespace. ([@pirj])

## 1.34.0 (2019-07-23)

- Remove `AggregateFailuresByDefault` config option of `RSpec/MultipleExpectations`. ([@pirj])
- Add `RSpec/LeakyConstantDeclaration` cop. ([@jonatas], [@pirj])
- Improve `aggregate_failures` metadata detection of `RSpec/MultipleExpectations`. ([@pirj])
- Improve `RSpec/SubjectStub` detection and message. ([@pirj])
- Change message of `RSpec/LetSetup` cop to be more descriptive. ([@foton])
- Improve `RSpec/ExampleWording` to handle interpolated example messages. ([@nc-holodakg])
- Improve detection by allowing the use of `RSpec` as a top-level constant. ([@pirj])
- Fix `RSpec/DescribedClass`'s incorrect detection. ([@pirj])
- Improve `RSpec/DescribedClass`'s ability to detect inside modules and classes. ([@pirj])

## 1.33.0 (2019-05-13)

- Let `RSpec/DescribedClass` pass `Struct` instantiation closures. ([@schmijos])
- Fixed `RSpec/ContextWording` missing `context`s with metadata. ([@pirj])
- Fix `FactoryBot/AttributeDefinedStatically` not working with an explicit receiver. ([@composerinteralia])
- Add `RSpec/Dialect` enforces custom RSpec dialects. ([@gsamokovarov])
- Fix redundant blank lines in `RSpec/MultipleSubjects`'s autocorrect. ([@pirj])
- Drop support for ruby `2.2`. ([@bquorning])

## 1.32.0 (2019-01-27)

- Add `RSpec/Yield` cop, suggesting using the `and_yield` method when stubbing a method, accepting a block. ([@Darhazer])
- Fix `FactoryBot/CreateList` autocorrect crashing when the factory is called with a block=. ([@Darhazer])
- Fixed `RSpec/Focus` not flagging some cases of `RSpec.describe` with `focus: true`. ([@Darhazer])
- Fixed `RSpec/Pending` not flagging some cases of `RSpec.describe` with `:skip`. ([@Darhazer])
- Fix false positive in `RSpec/ReceiveCounts` when method name `exactly`, `at_least` or `at_most` is used along with `times`, without being an RSpec API. ([@Darhazer])

## 1.31.0 (2019-01-02)

- Add `IgnoreSharedExamples` option for `RSpec/NamedSubject`. ([@RST-J])
- Add autocorrect support for `Capybara/CurrentPathExpectation` cop. ([@ypresto])
- Add support for built-in `exists` matcher for `RSpec/PredicateMatcher` cop. ([@mkenyon])
- `SingleArgumentMessageChain` no longer reports an array as it's only argument as an offense. ([@Darhazer])

## 1.30.1 (2018-11-01)

- `FactoryBot/CreateList` now ignores `times` blocks with an argument. ([@Darhazer])

## 1.30.0 (2018-10-08)

- Add config to `RSpec/VerifiedDoubles` to enforcement of verification on unnamed doubles. ([@BrentWheeldon])
- Fix `FactoryBot/AttributeDefinedStatically` not working when there is a non-symbol key. ([@vzvu3k6k])
- Fix false positive in `RSpec/ImplicitSubject` when `is_expected` is used inside `its()` block. ([@Darhazer])
- Add `single_statement_only` style to `RSpec/ImplicitSubject` as a more relaxed alternative to `single_line_only`. ([@Darhazer])
- Add `RSpec/UnspecifiedException` as a default cop to encourage more-specific `expect{}.to raise_error(ExceptionType)`, or `raise_exception` style handling of exceptions. ([@daveworth])

## 1.29.1 (2018-09-01)

- Fix false negative in `FactoryBot/AttributeDefinedStatically` when attribute is defined on `self`. ([@Darhazer])
- `RSpec/FactoryBot` cops will now also inspect the `spec/factories.rb` path by default. ([@bquorning])

## 1.29.0 (2018-08-25)

- `RSpec/InstanceVariable` - Recommend local variables in addition to `let`. ([@jaredbeck])
- Add `RSpec/ImplicitSubject` cop. ([@Darhazer])
- Add `RSpec/HooksBeforeExamples` cop. ([@Darhazer])

## 1.28.0 (2018-08-14)

- Add `RSpec/ReceiveNever` cop enforcing usage of `not_to receive` instead of `never` matcher. ([@Darhazer])
- Fix false positive in `RSpec/EmptyLineAfterExampleGroup` cop when example is inside `if`. ([@Darhazer])
- Add `RSpec/MissingExampleGroupArgument` to enforce first argument for an example group. ([@geniou])
- Drop support for ruby `2.1`. ([@bquorning])
- Add `FactoryBot/AttributeDefinedStatically` cop to help FactoryBot users with the deprecation of static attributes. ([@composerinteralia], [@seanpdoyle])
- Remove `FactoryBot/DynamicAttributeDefinedStatically` and `FactoryBot/StaticAttributeDefinedDynamically` cops. ([@composerinteralia])

## 1.27.0 (2018-06-14)

- `RSpec/LeadingSubject` now enforces subject to be before any examples, hooks or let declarations. ([@Darhazer])
- Fix `RSpec/NotToNot` to highlight only the selector (`not_to` or `to_not`), so it works also on `expect { ... }` blocks. ([@bquorning])
- Add `RSpec/EmptyLineAfterHook` cop. ([@bquorning])
- Add `RSpec/EmptyLineAfterExampleGroup` cop to check that there is an empty line after example group blocks. ([@bquorning])
- Fix `RSpec/DescribeClass` crashing on `RSpec.describe` without arguments. ([@Darhazer])
- Bump RuboCop requirement to v0.56.0. ([@bquorning])
- Fix `RSpec/OverwritingSetup` crashing if a variable is used as an argument for `let`. ([@Darhazer])

## 1.26.0 (2018-06-06)

- Fix false positive in `RSpec/EmptyExampleGroup` cop when methods named like a RSpec method are used. ([@Darhazer])
- Fix `Capybara/FeatureMethods` not working when there is require before the spec. ([@Darhazer])
- Fix `RSpec/EmptyLineAfterFinalLet`: allow a comment to be placed after latest let, requiring empty line after the comment. ([@Darhazer])
- Add `RSpec/ReceiveCounts` cop to enforce usage of :once and :twice matchers. ([@Darhazer])

## 1.25.1 (2018-04-10)

- Fix false positive in `RSpec/Pending` cop when pending is used as a method name. ([@Darhazer])
- Fix `FactoryBot/DynamicAttributeDefinedStatically` false positive when using symbol proc argument for a sequence. ([@tdeo])

## 1.25.0 (2018-04-07)

- Add `RSpec/SharedExamples` cop to enforce consistent usage of string to titleize shared examples. ([@anthony-robin])
- Add `RSpec/Be` cop to enforce passing argument to the generic `be` matcher. ([@Darhazer])
- Fix false positives in `StaticAttributeDefinedDynamically` and `ReturnFromStub` when a const is used in an array or hash. ([@Darhazer])
- Add `RSpec/Pending` cop to enforce no existing pending or skipped examples. This is disabled by default. ([@patrickomatic])
- Fix `RSpec/NestedGroups` cop support --auto-gen-config. ([@walf443])
- Fix false positives in `Capybara/FeatureMethods` when feature methods are used as property names in a factory. ([@Darhazer])
- Allow configuring enabled methods in `Capybara/FeatureMethods`. ([@Darhazer])
- Add `FactoryBot/CreateList` cop. ([@Darhazer])

## 1.24.0 (2018-03-06)

- Compatibility with RuboCop v0.53.0. ([@bquorning])
- The `Rails/HttpStatus` cop is unavailable if the `rack` gem cannot be loaded. ([@bquorning])
- Fix `Rails/HttpStatus` not working with custom HTTP status codes. ([@bquorning])
- Fix `FactoryBot/StaticAttributeDefinedDynamically` to handle empty block. ([@abrom])
- Fix false positive in `FactoryBot/DynamicAttributeDefinedStatically` when a before/after callback has a symbol proc argument. ([@abrom])

## 1.23.0 (2018-02-23)

- Add `RSpec/Rails/HttpStatus` cop to enforce consistent usage of the status format (numeric or symbolic). ([@anthony-robin], [@jojos003])
- Fix false negative in `RSpec/ReturnFromStub` when a constant is being returned by the stub. ([@Darhazer])
- Fix `FactoryBot/DynamicAttributeDefinedStatically` to handle dynamic attributes inside arrays/hashes. ([@abrom])
- Add `FactoryBot/StaticAttributeDefinedDynamically` (based on dynamic attribute cop). ([@abrom])

## 1.22.2 (2018-02-01)

- Fix error in `RSpec/DescribedClass` when working on an empty `describe` block. ([@bquorning])

## 1.22.1 (2018-01-17)

- Fix false positives in `RSpec/ReturnFromStub`. ([@Darhazer])

## 1.22.0 (2018-01-10)

- Updates `describe_class` to account for RSpecs `:system` wrapper of rails system tests. ([@EliseFitz15])
- Add `RSpec/ExpectChange` cop to enforce consistent usage of the change matcher. ([@Darhazer])
- Add autocorrect support to `RSpec/LetBeforeExamples`. ([@Darhazer])
- Fix `RSpec/InstanceVariable` flagging instance variables inside dynamically defined class. ([@Darhazer])
- Add autocorrect support for `RSpec/ReturnFromStub` cop. ([@bquorning])
- Add `RSpec/ExampleWithoutDescription` cop. ([@Darhazer])

## 1.21.0 (2017-12-13)

- Compatibility with RuboCop v0.52.0. ([@bquorning])
- Improve performance when user does not override default RSpec Pattern config. ([@walf443])
- Add `AggregateFailuresByDefault` configuration for `RSpec/MultipleExpectations` cop. ([@onk])

## 1.20.1 (2017-11-15)

- Add "without" to list of default allowed prefixes for `RSpec/ContextWording`. ([@bquorning])

## 1.20.0 (2017-11-09)

- Rename namespace `FactoryGirl` to `FactoryBot` following original library update. ([@walf443])
- Fix exception in `RSpec/ReturnFromStub` on empty block. ([@yevhene])
- Add `RSpec/ContextWording` cop. ([@pirj], [@telmofcosta])
- Fix `RSpec/SubjectStub` cop matches receive message inside all matcher. ([@walf443])

## 1.19.0 (2017-10-18)

Compatibility release so users can upgrade RuboCop to 0.51.0. No new features.

## 1.18.0 (2017-09-29)

- Fix false positive in `Capybara/FeatureMethods`. ([@Darhazer])
- Add `RSpec/Capybara/CurrentPathExpectation` cop for feature specs, disallowing setting expectations on `current_path`. ([@timrogers])
- Fix false positive in `RSpec/LetBeforeExamples` cop when example group contains single let. ([@Darhazer])

## 1.17.1 (2017-09-20)

- Improved `RSpec/ReturnFromStub` to handle string interpolation, hashes and do..end blocks. ([@Darhazer])
- Fixed compatibility with JRuby. ([@zverok])

## 1.17.0 (2017-09-14)

- Add `RSpec/Capybara` namespace including the first cop for feature specs: `Capybara/FeatureMethods`. ([@rspeicher])
- Update to RuboCop 0.50.0. ([@bquorning])

## 1.16.0 (2017-09-06)

- Add `RSpec/FactoryGirl` namespace including the first cop for factories: `FactoryGirl/DynamicAttributeDefinedStatically`. ([@jonatas])
- Add disabled by default `RSpec/AlignLeftLetBrace`. ([@backus])
- Add disabled by default `RSpec/AlignRightLetBrace`. ([@backus])
- Add `RSpec/LetBeforeExamples` cop. ([@Darhazer])
- Add `RSpec/MultipleSubjects` cop. ([@backus])
- Add `RSpec/ReturnFromStub` cop. ([@Darhazer])
- Add `RSpec/VoidExpect` cop. ([@pocke])
- Add `RSpec/InvalidPredicateMatcher` cop. ([@pocke])
- Change HookArgument cop to detect when hook has a receiver. ([@pocke])
- Add `RSpec/PredicateMatcher` cop. ([@pocke])
- Add `RSpec/ExpectInHook` cop. ([@pocke])
- `RSpec/MultipleExpectations` now detects usage of expect_any_instance_of. ([@Darhazer])
- `RSpec/MultipleExpectations` now detects usage of is_expected. ([@bmorrall])

## 1.15.1 (2017-04-30)

- Fix the handling of various edge cases in the `RSpec/ExampleWording` cop, including one that would cause autocorrect to crash. ([@dgollahon])
- Fix `RSpec/IteratedExpectation` crashing when there is an assignment in the iteration. ([@Darhazer])
- Fix false positive in `RSpec/SingleArgumentMessageChain` cop when the single argument is a hash. ([@Darhazer])

## 1.15.0 (2017-03-24)

- Add `RSpec/DescribeSymbol` cop. ([@rspeicher])
- Fix error when `RSpec/OverwritingSetup` and `RSpec/ScatteredLet` analyzed empty example groups. ([@backus])

## 1.14.0 (2017-03-24)

- Add `RSpec/OverwritingSetup` cop. ([@Darhazer])
- Add autocorrect support for `RSpec/LeadingSubject` cop. ([@Darhazer])
- Add `RSpec/ScatteredLet` cop. ([@Darhazer])
- Add `RSpec/IteratedExpectation` cop. ([@Darhazer])
- Add `RSpec/EmptyLineAfterSubject` cop. ([@Darhazer])
- Add `RSpec/EmptyLineAfterFinalLet` cop. ([@Darhazer])

## 1.13.0 (2017-03-07)

- Add repeated 'it' detection to `RSpec/ExampleWording` cop. ([@dgollahon])
- Add [observed_nesting/max_nesting] info to `RSpec/NestedGroups` messages. ([@dgollahon])
- Add `RSpec/ItBehavesLike` cop. ([@dgollahon])
- Add `RSpec/SharedContext` cop. ([@Darhazer])
- `RSpec/MultipleExpectations`: Count aggregate_failures block as single expectation. ([@Darhazer])
- Fix `ExpectActual` cop flagging `rspec-rails` routing specs. ([@backus])
- Fix `FilePath` cop not registering offenses for files like `spec/blog/user.rb` when it should be `spec/blog/user_spec.rb`. ([@backus])

## 1.12.0 (2017-02-21)

- Add `RSpec/InstanceSpy` cop. ([@Darhazer])
- Add `RSpec/BeforeAfterAll` for avoiding leaky global test setup. ([@cfabianski])

## 1.11.0 (2017-02-16)

- Add `AroundBlock` cop. ([@Darhazer])
- Add `EnforcedStyle` configuration for `RSpec/DescribedClass` cop. ([@Darhazer])
- Fix false positive for `RSpec/RepeatedExample` cop. ([@redross])

## 1.10.0 (2017-01-15)

- Fix false negative for `RSpec/MessageSpies` cop. ([@onk])
- Fix internal dependencies on RuboCop to be compatible with 0.47 release. ([@backus])
- Add autocorrect support for `SingleArgumentMessageChain` cop. ([@bquorning])
- Rename `NestedGroups`' configuration key from `MaxNesting` to `Max` in order to be consistent with other cop configuration. ([@backus])
- Add `RepeatedExample` cop for detecting repeated examples within example groups. ([@backus])
- Add `ScatteredSetup` cop for enforcing that only one `before`, `around`, and `after` hook are used per example group scope. ([@backus])
- Add `ExpectOutput` cop for recommending `expect { ... }.to output(...).to_stdout`. ([@backus])

## 1.9.1 (2017-01-02)

- Fix unintentional regression change in `NestedGroups` reported in #270. ([@backus])
- Change `MaxNesting` for `NestedGroups` from 2 to 3. ([@backus])

## 1.9.0 (2016-12-29)

- Add `MessageSpies` cop for enforcing consistent style of either `expect(...).to have_received` or `expect(...).to receive`, intended as a replacement for the `MessageExpectation` cop. ([@bquorning])
- Fix `DescribeClass` to not flag `describe` at the top of a block of shared examples. ([@clupprich])
- Add `SingleArgumentMessageChain` cop for recommending use of `receive` instead of `receive_message_chain` where possible. ([@bquorning])
- Add `RepeatedDescription` cop for detecting repeated example descriptions within example groups. ([@backus])

## 1.8.0 (2016-10-27)

- Optionally ignore method names in the `describe` argument when running the `FilePath` cop. ([@bquorning])
- Fix regression in how `FilePath` converts alphanumeric class names into paths. ([@bquorning])
- Add `ImplicitExpect` cop for enforcing `should` vs. `is_expected.to`. ([@backus])
- Disable `MessageExpectation` cop in the default configuration. ([@bquorning])

## 1.7.0 (2016-08-24)

- Add support for checking all example groups with `ExampleLength`. ([@backus])
- Add support for checking shared example groups for `DescribedClass`. ([@backus])
- Add support for checking `its` from [rspec-its](https://github.com/rspec/rspec-its). ([@backus])
- Add `EmptyExampleGroup` cop for detecting `describe`s and `context`s without any tests inside. ([@backus])
- Add `CustomIncludeMethods` configuration option for `EmptyExampleGroup`. ([@backus])
- Add `NestedGroups` cop for detecting excessive example group nesting. ([@backus])
- Add `MaxNesting` configuration option for `NestedGroups` cop. ([@backus])
- Add `ExpectActual` cop for detecting literal values within `expect(...)`. ([@backus])
- Add `MultipleExpectations` cop for detecting multiple `expect(...)` calls within one example. ([@backus])
- Add `Max` configuration option for `MultipleExpectations`. ([@backus])
- Add `SubjectStub` cop for testing stubbed test subjects. ([@backus])
- Add `LetSetup` cop for detecting cases where `let!` is used for test setup. ([@backus])
- Change all cops to only inspect files with names following rspec convention (`*/spec/*` and/or `_spec.rb`). ([@backus])
- Add `AllCops/RSpec` configuration option for specifying custom spec file patterns. ([@backus])
- Add `AssignmentOnly` configuration option for `RSpec/InstanceVariable` cop. ([@backus])
- Add `BeEql` cop which looks for expectations that can use `be(...)` instead of `eql(...)`. ([@backus])
- Add autocorrect support for `BeEql` cop. ([@backus])
- Add `MessageExpectation` cop for enforcing consistent style of either `expect(...).to receive` or `allow(...).to receive`. ([@backus])
- Add `MessageChain` cop. ([@bquorning])

## 1.6.0 (2016-08-03)

- Add `SkipBlocks` option for `DescribedClass` cop. ([@backus])

## 1.5.3 (2016-08-02)

- Add `RSpec/NamedSubject` cop. ([@backus])

## 1.5.2 (2016-08-01)

- Drop support for ruby `2.0.0` and `2.1.0`. ([@backus])
- Internal refactorings and improved test coverage. ([@backus])

## 1.5.1 (2016-07-20)

- Fix `unrecognized parameter RSpec/VerifiedDoubles:IgnoreSymbolicNames` warning. ([@jeffreyc])
- Update to rubocop 0.41.2. ([@backus])

## 1.5.0 (2016-05-17)

- Expand `VerifiedDoubles` cop to check for `spy` as well as `double`. ([@andyw8])
- Enable `VerifiedDoubles` cop by default. ([@andyw8])
- Add `IgnoreSymbolicNames` option for `VerifiedDoubles` cop. ([@andyw8])
- Add `RSpec::ExampleLength` cop. ([@andyw8])
- Handle alphanumeric class names in `FilePath` cop. ([@andyw8])
- Skip `DescribeClass` cop for view specs. ([@andyw8])
- Skip `FilePath` cop for Rails routing specs. ([@andyw8])
- Add cop to check for focused specs. ([@renanborgescampos], [@jaredmoody])
- Clean-up `RSpec::NotToNot` to use same configuration semantics as other RuboCop cops, add autocorrect support for `RSpec::NotToNot`. ([@baberthal])
- Update to rubocop 0.40.0. ([@nijikon])

## 1.4.1 (2016-04-03)

- Ignore routing specs for DescribeClass cop. ([@nijikon])
- Move rubocop dependency to runtime. ([@nijikon])
- Update to rubocop 0.39.0. ([@nijikon])

## 1.4.0 (2016-02-15)

- Update to rubocop 0.37.2. ([@nijikon])
- Update ruby versions we test against. ([@nijikon])
- Add `RSpec::NotToNot` cop. ([@miguelfteixeira])
- Add `RSpec/AnyInstance` cop. ([@mlarraz])

## 1.3.1

- Fix auto correction issue - syntax had changed in RuboCop v0.31. ([@bquorning])
- Add RuboCop clone to vendor folder - see #39 for details. ([@bquorning])

## 1.3.0

- Ignore non string arguments for FilePathCop - thanks to @deivid-rodriguez. ([@geniou])
- Skip DescribeMethod cop for tagged specs. ([@deivid-rodriguez])
- Skip DescribeClass cop for feature/request specs. ([@deivid-rodriguez])

## 1.2.2

- Make `RSpec::ExampleWording` case insensitive. ([@geniou])

## 1.2.1

- Add `RSpec::VerifiedDoubles` cop. ([@andyw8])

## 1.2.0

- Drop support of ruby `1.9.2`. ([@geniou])
- Update to RuboCop `~> 0.24`. ([@geniou])
- Add `autocorrect` to `RSpec::ExampleWording`. This experimental - use with care and check the changes. ([@geniou])
- Fix config loader debug output. ([@geniou])
- Rename `FileName` cop to `FilePath` as a workaround - see [#19](https://github.com/nevir/rubocop-rspec/issues/19). ([@geniou])

## 1.1.0

- Add `autocorrect` to `RSpec::DescribedClass` cop. ([@geniou])

## 1.0.1

- Add `config` folder to gemspec. ([@pstengel])

## 1.0.rc3

- Update to RuboCop `>= 0.23`. ([@geniou])
- Add configuration option for `CustomTransformation` to `FileName` cop. ([@geniou])

## 1.0.rc2

- Gem is no longer 20MB (sorry!). ([@nevir])
- `RspecFileName` cop allows for method specs to organized into directories by class and type. ([@nevir])

## 1.0.rc1

- Update code to work with rubocop `>= 0.19`. ([@geniou])
- Split `UnitSpecNaming` cop into `RSpecDescribeClass`, `RSpecDescribeMethod` and `RSpecFileName` and enabled them all by default. ([@geniou])
- Add `RSpecExampleWording` cop to prevent to use of should at the beginning of the spec description. ([@geniou])
- Fix `RSpecFileName` cop for non-class specs. ([@geniou])
- Adapt `RSpecFileName` cop to common naming convention and skip spec with multiple top level describes. ([@geniou])
- Add `RSpecMultipleDescribes` cop to check for multiple top level describes. ([@geniou])
- Add `RSpecDescribedClass` to promote the use of `described_class`. ([@geniou])
- Add `RSpecInstanceVariable` cop to check for the usage of instance variables. ([@geniou])

<!-- Contributors (alphabetically) -->

[@aarestad]: https://github.com/aarestad
[@abrom]: https://github.com/abrom
[@ahukkanen]: https://github.com/ahukkanen
[@akiomik]: https://github.com/akiomik
[@akrox58]: https://github.com/akrox58
[@alexwayfer]: https://github.com/AlexWayfer
[@andrykonchin]: https://github.com/andrykonchin
[@andyw8]: https://github.com/andyw8
[@anthony-robin]: https://github.com/anthony-robin
[@aried3r]: https://github.com/aried3r
[@baberthal]: https://github.com/baberthal
[@backus]: https://github.com/backus
[@bcgraham]: https://github.com/bcgraham
[@biinari]: https://github.com/biinari
[@bmorrall]: https://github.com/bmorrall
[@bquorning]: https://github.com/bquorning
[@brentwheeldon]: https://github.com/BrentWheeldon
[@brianhawley]: https://github.com/BrianHawley
[@cbliard]: https://github.com/cbliard
[@cfabianski]: https://github.com/cfabianski
[@clupprich]: https://github.com/clupprich
[@composerinteralia]: https://github.com/composerinteralia
[@corsonknowles]: https://github.com/corsonknowles
[@corydiamand]: https://github.com/corydiamand
[@darhazer]: https://github.com/Darhazer
[@daveworth]: https://github.com/daveworth
[@dduugg]: https://github.com/dduugg
[@deivid-rodriguez]: https://github.com/deivid-rodriguez
[@dgollahon]: https://github.com/dgollahon
[@dmitrytsepelev]: https://github.com/dmitrytsepelev
[@drcapulet]: https://github.com/drcapulet
[@drowze]: https://github.com/Drowze
[@dswij]: https://github.com/dswij
[@dvandersluis]: https://github.com/dvandersluis
[@earlopain]: https://github.com/earlopain
[@edgibbs]: https://github.com/edgibbs
[@eikes]: https://github.com/eikes
[@eitoball]: https://github.com/eitoball
[@elebow]: https://github.com/elebow
[@elisefitz15]: https://github.com/EliseFitz15
[@elliterate]: https://github.com/elliterate
[@faucct]: https://github.com/faucct
[@foton]: https://github.com/foton
[@francois-ferrandis]: https://github.com/francois-ferrandis
[@franzliedke]: https://github.com/franzliedke
[@g-rath]: https://github.com/G-Rath
[@geniou]: https://github.com/geniou
[@gsamokovarov]: https://github.com/gsamokovarov
[@harry-graham]: https://github.com/harry-graham
[@harrylewis]: https://github.com/harrylewis
[@hasghari]: https://github.com/hasghari
[@hosamaly]: https://github.com/hosamaly
[@ignaciovillaverde]: https://github.com/ignaciovillaverde
[@jaredbeck]: https://github.com/jaredbeck
[@jaredmoody]: https://github.com/jaredmoody
[@jdufresne]: https://github.com/jdufresne
[@jeffreyc]: https://github.com/jeffreyc
[@jeppester]: https://github.com/jeppester
[@jessieay]: https://github.com/jessieay
[@jfragoulis]: https://github.com/jfragoulis
[@johnny-miyake]: https://github.com/johnny-miyake
[@jojos003]: https://github.com/jojos003
[@jonatas]: https://github.com/jonatas
[@jtannas]: https://github.com/jtannas
[@k-s-a]: https://github.com/K-S-A
[@kellysutton]: https://github.com/kellysutton
[@koic]: https://github.com/koic
[@krororo]: https://github.com/krororo
[@kuahyeow]: https://github.com/kuahyeow
[@lazycoder9]: https://github.com/lazycoder9
[@lee266]: https://github.com/lee266
[@leoarnold]: https://github.com/leoarnold
[@liberatys]: https://github.com/Liberatys
[@lokhi]: https://github.com/lokhi
[@lovro-bikic]: https://github.com/lovro-bikic
[@luke-hill]: https://github.com/luke-hill
[@m-yamashita01]: https://github.com/M-Yamashita01
[@marocchino]: https://github.com/marocchino
[@miguelfteixeira]: https://github.com/miguelfteixeira
[@mkenyon]: https://github.com/mkenyon
[@mkrawc]: https://github.com/mkrawc
[@mlarraz]: https://github.com/mlarraz
[@mockdeep]: https://github.com/mockdeep
[@mothonmars]: https://github.com/MothOnMars
[@mvz]: https://github.com/mvz
[@naveg]: https://github.com/naveg
[@nc-holodakg]: https://github.com/nc-holodakg
[@nevir]: https://github.com/nevir
[@ngouy]: https://github.com/ngouy
[@nickcampbell18]: https://github.com/nickcampbell18
[@nijikon]: https://github.com/nijikon
[@onk]: https://github.com/onk
[@onumis]: https://github.com/onumis
[@oshiro3]: https://github.com/oshiro3
[@patrickomatic]: https://github.com/patrickomatic
[@paydaylight]: https://github.com/paydaylight
[@philcoggins]: https://github.com/PhilCoggins
[@pirj]: https://github.com/pirj
[@pocke]: https://github.com/pocke
[@pstengel]: https://github.com/pstengel
[@qqism]: https://github.com/QQism
[@r7kamura]: https://github.com/r7kamura
[@rafix02]: https://github.com/Rafix02
[@redross]: https://github.com/redross
[@renanborgescampos]: https://github.com/renanborgescampos
[@robinaugh]: https://github.com/robinaugh
[@robotdana]: https://github.com/robotdana
[@rolfschmidt]: https://github.com/rolfschmidt
[@rrosenblum]: https://github.com/rrosenblum
[@rspeicher]: https://github.com/rspeicher
[@rst-j]: https://github.com/RST-J
[@sakuro]: https://github.com/sakuro
[@samrjenkins]: https://github.com/samrjenkins
[@schmijos]: https://github.com/schmijos
[@seanpdoyle]: https://github.com/seanpdoyle
[@sl4vr]: https://github.com/sl4vr
[@smcgivern]: https://github.com/smcgivern
[@splattael]: https://github.com/splattael
[@stephannv]: https://github.com/stephannv
[@swelther]: https://github.com/swelther
[@t3h2mas]: https://github.com/t3h2mas
[@tdeo]: https://github.com/tdeo
[@tejasbubane]: https://github.com/tejasbubane
[@telmofcosta]: https://github.com/telmofcosta
[@tietew]: https://github.com/Tietew
[@timrogers]: https://github.com/timrogers
[@tmaier]: https://github.com/tmaier
[@topalovic]: https://github.com/topalovic
[@twalpole]: https://github.com/twalpole
[@vzvu3k6k]: https://github.com/vzvu3k6k
[@walf443]: https://github.com/walf443
[@yasu551]: https://github.com/yasu551
[@ybiquitous]: https://github.com/ybiquitous
[@ydah]: https://github.com/ydah
[@yevhene]: https://github.com/yevhene
[@ypresto]: https://github.com/ypresto
[@zdennis]: https://github.com/zdennis
[@zverok]: https://github.com/zverok
