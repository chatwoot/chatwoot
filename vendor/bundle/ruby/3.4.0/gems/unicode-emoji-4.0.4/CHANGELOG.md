# CHANGELOG

## 4.0.4

- Add `REGEX_TEXT_PRESENTATION` to be able to match for raw default-text Emoji codepoints

## 4.0.3

- Remove emoji-test.txt from Rubygems package

## 4.0.2

- Directly use `RbConfig::CONFIG["UNICODE_EMOJI_VERSION"]` to detect Ruby's Emoji version,
  drop unicode-version dependency

## 4.0.0

- **Breaking change:** Regexes now include single skin tone modifiers (`🏻`) and hair components (`🦰`).
  They were previously considered to be invalid partial Emoji, however since they are supposed to be
  displayed as Emoji in isolation, they are now part of the regexes (see *ED-20* in UTS51).
- **Breaking change:** Drop `REGEX_ANY` in favor of `REGEX_PROP_EMOJI`
- Expose regexes for Emoji props (`REGEX_PROP_*`). The advantage over using the native regex properties
  directly is that you will be able to use the Emoji support level of this gem instead of Ruby's.
  For example, as of releasing this, the current Emoji version is 16.0, while Ruby is at 15.0.
  Also see README for a table listing the regexes that match Emoji properties.
- Add `REGEX_EMOJI_KEYCAP` for matching specifically Emoji keycaps
- Use character class instead of lookbehind for native text emoji and non-emoji pictographic regexes

## 3.8.0

- Add new RGI-based regexes `REGEX_INCLUDE_MQE` and `REGEX_INCLUDE_MQE_UQE` which allows to match
  for minimally-qualified and unqualified RGI sequences (Emoji that lack some VS16)
- Add specs running through `emoji-text.txt` and classify qualification statuses per regex
- Improve documentation and add detailed table about which regex has which features
- Native regexes: Use native Emoji props for Emoji text presentation
- Update CLDR to v46 (valid subdivisions)
- Further improvements (see commit log)

## 3.7.0

- Bump required Ruby slightly to 2.5
- Introduce new `REGEX_POSSIBLE` which contains the regex described in
  https://www.unicode.org/reports/tr51/#EBNF_and_Regex
- Fix that some valid subdivisions were not decompressed (`REGEX_VALID`)
- Be stricter about selection of tag characters in `REGEX_WELL_FORMED`
  - Only U+E0030..U+E0039, U+E0061..U+E007A allowed
  - Max tag sequence length
- Use native `/\p{RI}/` regex for regional indicators
- Separately autoload emoji list, so it can be loaded when other indexes
  are not needed

## 3.6.0

- `Unicode::Emoji::REGEX_TEXT` now matches non-emoji keycaps like "3⃣"  (U+0033 U+20E3)
- Minor refactorings

## 3.5.0

- Emoji 16.0

## 3.4.0

- Emoji 15.1

## 3.3.2

- Update valid subdivisions to CLDR 43 (no changes)
  -> there won't be any new RGI subdivision flags in Emoji

## 3.3.1

- Update valid subdivisions to CLDR 42 (no changes)

## 3.3.0

- Emoji 15.0

## 3.2.0

- Update valid subdivisions to CLDR 41

## 3.1.1

- Fix `REGEX` to be able to match complete family emoji, instead of
  sub-matching partial families, thanks @matt17r

## 3.1.0

- Update valid subdivisions to CLDR 40

## 3.0.0

- Vastly improve memory usage, patch by @radarek
  - Emoji regexes are now pre-generated and bundled with the release
  - Regexes use character classes instead of unions when possible
  - Most constants (e.g. regexes) now get autoloaded
  - See https://github.com/janlelis/unicode-emoji/pull/9 for more details

## 2.9.0

- Emoji 14.0

## 2.8.0

- Update valid subdivisions to CLDR 39

## 2.7.1

- Update valid subdivisions to CLDR 38.1

## 2.7.0

- Update valid subdivisions to CLDR 38
- Loosen Ruby dependency to allow Ruby 3.0

## 2.6.0

- Emoji 13.1

## 2.5.0

- Use native Emoji regex properties when current Ruby's Emoji support is the same as our current Emoji version
- Update valid subdivisions to CLDR 37

## 2.4.0

- Emoji 13.0

## 2.3.1

- Fix index to actually include Emoji 12.1

## 2.3.0

- Emoji 12.1

## 2.2.0

- Update subdivisions to CLDR 36

## 2.1.0

- Add `REGEX_PICTO` which matches codepoints with the **Extended_Pictographic** property
- Add `REGEX_PICTO_NO_EMOJI` which matches codepoints with the **Extended_Pictographic** property, but no **Emoji** property

## 2.0.0

- Emoji 12.0 data (including valid subdivisions)
- Introduce new `REGEX_WELL_FORMED` to be able to match for invalid tag and region sequences
- Introduce new `*_INCLUDE_TEXT` regexes which include matching for textual presentation emoji
- Refactoring: Update Emoji matching to latest standard while keeping naming close to standard
- Issue warning when using `#list` method to retrieve outdated category
- Change matching for ZWJ sequences: Do not limit sequence to a maximum of 3 ZWJs

## 1.1.0

- Emoji 11.0
- Do not depend on rubygems (only use zlib stdlib for unzipping)

## 1.0.3

- Explicitly load rubygems/util, fixes regression in 1.2.1

## 1.0.2

- Use `Gem::Util` for `gunzip`, removes deprecation warning

## 1.0.1

- Actually set required Ruby version to 2.3 in gemspec

## 1.0.0

- Drop support for Ruby below 2.3, use 0.9 if you need to
- Internal refactorings, no API change

## 0.9.3

- Implement native Emoji regex matchers, but do not activate or document, yet

## 0.9.2

- REGEX_TEXT: Do not match if the text emoji is followed by a emoji modifier

## 0.9.1

- Include a categorized list of recommended Emoji

## 0.9.0

- Initial release (Emoji version 5.0)
