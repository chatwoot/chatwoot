# Unicode::Emoji [![[version]](https://badge.fury.io/rb/unicode-emoji.svg)](https://badge.fury.io/rb/unicode-emoji)  [![[ci]](https://github.com/janlelis/unicode-emoji/workflows/Test/badge.svg)](https://github.com/janlelis/unicode-emoji/actions?query=workflow%3ATest)

Provides various sophisticated regular expressions to work with Emoji in strings,
incorporating the latest Unicode / Emoji standards.

Additional features:

- A categorized list of Emoji (RGI: Recommended for General Interchange)
- Retrieve Emoji properties info about specific codepoints (Emoji_Modifier, Emoji_Presentation, etc.)

Emoji version: **16.0** (September 2024)

CLDR version (used for sub-region flags): **46** (October 2024)

## Gemfile

```ruby
gem "unicode-emoji"
```

## Usage – Regex Matching

The gem includes multiple Emoji regexes, which are compiled out of various Emoji Unicode data sources.

```ruby
require "unicode/emoji"

string = "String which contains all types of Emoji sequences:

- Basic Emoji: 😴
- Textual Emoji with Emoji variation (VS16): ▶️
- Emoji with skin tone modifier: 🛌🏽
- Region flag: 🇵🇹
- Sub-Region flag: 🏴󠁧󠁢󠁳󠁣󠁴󠁿
- Keycap sequence: 2️⃣
- Skin tone modifier: 🏻
- Sequence using ZWJ (zero width joiner): 🤾🏽‍♀️
"

string.scan(Unicode::Emoji::REGEX) # => ["😴", "▶️", "🛌🏽", "🇵🇹", "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "2️⃣", "🏻", "🤾🏽‍♀️"]
```

Depending on your exact usecase, you can choose between multiple levels of Emoji detection:

### Main Regexes

Regex                         | Description | Example Matches | Example Non-Matches
------------------------------|-------------|-----------------|--------------------
`Unicode::Emoji::REGEX`       | **Use this one if unsure!** Matches (non-textual) Basic Emoji and all kinds of *recommended* Emoji sequences (RGI/FQE) | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🤾🏽‍♀️`, `🏻` |  `🤾🏽‍♀`, `🏌‍♂️`, `😴︎`, `▶`, `🇵🇵`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤠‍🤢`, `1`, `1⃣`
`Unicode::Emoji::REGEX_VALID` | Matches (non-textual) Basic Emoji and all kinds of *valid* Emoji sequences | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀` ,`🏌‍♂️`, `🤠‍🤢`, `🏻` | `😴︎`, `▶`, `🇵🇵`, `1`, `1⃣`
`Unicode::Emoji::REGEX_WELL_FORMED` | Matches (non-textual) Basic Emoji and all kinds of *well-formed* Emoji sequences | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`,`🏌‍♂️` , `🤠‍🤢`,  `🇵🇵`, `🏻` | `😴︎`, `▶`, `1`, `1⃣`
`Unicode::Emoji::REGEX_POSSIBLE` | Matches all singleton Emoji, all kinds of Emoji sequences, and even non-Emoji singleton components like digits. Only exception: Unqualified keycap sequences are not matched | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏌‍♂️`, `🤠‍🤢`,  `🇵🇵`, `😴︎`, `▶`, `🏻`, `1` | `1⃣`

#### Include Text Emoji

By default, textual Emoji (emoji characters with text variation selector or those that have a default text presentation) will not be included in the default regexes (except in `REGEX_POSSIBLE`). However, if you wish to match for them too, you can include them in your regex by appending the `_INCLUDE_TEXT` suffix:

Regex                         | Description | Example Matches | Example Non-Matches
------------------------------|-------------|-----------------|--------------------
`Unicode::Emoji::REGEX_INCLUDE_TEXT`       | `REGEX` + `REGEX_TEXT` | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🤾🏽‍♀️`, `😴︎`, `▶`, `1⃣` , `🏻`| `🤾🏽‍♀`, `🏌‍♂️`, `🇵🇵`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤠‍🤢`, `1`
`Unicode::Emoji::REGEX_VALID_INCLUDE_TEXT` | `REGEX_VALID` + `REGEX_TEXT` | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏌‍♂️`, `🤠‍🤢`, `😴︎`, `▶`, `1⃣` , `🏻` | `🇵🇵`, `1`
`Unicode::Emoji::REGEX_WELL_FORMED_INCLUDE_TEXT` | `REGEX_WELL_FORMED` + `REGEX_TEXT` | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏌‍♂️`, `🤠‍🤢`,  `🇵🇵`, `😴︎`, `▶`, `1⃣` , `🏻` | `1`

#### Minimally-qualified and Unqualified Sequences

Regex                         | Description | Example Matches | Example Non-Matches
------------------------------|-------------|-----------------|--------------------
`Unicode::Emoji::REGEX_INCLUDE_MQE` | Like `REGEX`, but additionally includes Emoji with missing Emoji Presentation Variation Selectors, where the first partial Emoji has all required Variation Selectors | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏻` | `🏌‍♂️`, `😴︎`, `▶`, `🇵🇵`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤠‍🤢`, `1`, `1⃣`
`Unicode::Emoji::REGEX_INCLUDE_MQE_UQE` | Like `REGEX`, but additionally includes Emoji with missing Emoji Presentation Variation Selectors | `😴`, `▶️`, `🛌🏽`, `🇵🇹`, `2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏌‍♂️`, `🏻` | `😴︎`, `▶`, `🇵🇵`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤠‍🤢`, `1`, `1⃣`

[List of MQE and UQE Emoji sequences](https://character.construction/unqualified-emoji)

#### Singleton Regexes

Matches only simple one-codepoint (+ optional variation selector) Emoji:

Regex                         | Description | Example Matches | Example Non-Matches
------------------------------|-------------|-----------------|--------------------
`Unicode::Emoji::REGEX_BASIC` | Matches (non-textual) Basic Emoji, but no sequences at all | `😴`, `▶️`, `🏻` | `😴︎`, `▶`, `🛌🏽`, `🇵🇹`, `🇵🇵`,`2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏌‍♂️`, `🤠‍🤢`, `1`
`Unicode::Emoji::REGEX_TEXT`  | Matches only textual singleton Emoji | `😴︎`, `▶` | `😴`, `▶️`, `🏻`, `🛌🏽`, `🇵🇹`, `🇵🇵`,`2️⃣`, `🏴󠁧󠁢󠁳󠁣󠁴󠁿`, `🏴󠁧󠁢󠁡󠁧󠁢󠁿`, `🤾🏽‍♀️`, `🤾🏽‍♀`, `🏌‍♂️`, `🤠‍🤢`, `1`

Here is a list of all Emoji that can be matched using the two regexes: [character.construction/emoji-vs-text](https://character.construction/emoji-vs-text). The `REGEX_BASIC` regex also matches [visual Emoji components](https://character.construction/emoji-components) (skin tone modifiers and hair components).

While `REGEX_BASIC` is part of the above regexes, `REGEX_TEXT` is only included in the `*_INCLUDE_TEXT` or `*_UQE` variants.

### Comparison 

1) Fully-qualified RGI Emoji ZWJ sequence
2) Minimally-qualified RGI Emoji ZWJ sequence (lacks Emoji Presentation Selectors, but not in the first Emoji character)
3) Unqualified RGI Emoji ZWJ sequence (lacks Emoji Presentation Selector, including in the first Emoji character). Unqualified Emoji include all basic Emoji in Text Presentation (see column 11/12).
4) Non-RGI Emoji ZWJ sequence
5) Valid Region made from a pair of Regional Indicators
6) Any Region made from a pair of Regional Indicators
7) RGI Flag Emoji Tag Sequences (England, Scotland, Wales)
8) Valid Flag Emoji Tag Sequences (any known subdivision)
9) Any Emoji Tag Sequences (any tag sequence with any base)
10) Basic Default Emoji Presentation Characters or Text characters with Emoji Presentation Selector
11) Basic Default Text Presentation Characters or Basic Emoji with Text Presentation Selector
12) Non-Emoji (unqualified) keycap

Regex | 1 RGI/FQE | 2 RGI/MQE | 3 RGI/UQE | 4 Non-RGI | 5 Valid Re­gion | 6 Any Re­gion | 7 RGI Tag | 8 Valid Tag | 9 Any Tag | 10 Basic Emoji | 11 Basic Text | 12 Text Key­cap
-|-|-|-|-|-|-|-|-|-|-|-|-
REGEX                          | ✅ | ❌ | ❌    | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌
REGEX INCLUDE TEXT             | ✅ | ❌ | ❌    | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅
REGEX INCLUDE MQE              | ✅ | ✅ | ❌    | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌
REGEX INCLUDE MQE UQE          | ✅ | ✅ | ✅    | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅
REGEX VALID                    | ✅ | ✅ | (✅)¹ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌
REGEX VALID INCLUDE TEXT       | ✅ | ✅ | ✅    | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅
REGEX WELL FORMED              | ✅ | ✅ | (✅)¹ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌
REGEX WELL FORMED INCLUDE TEXT | ✅ | ✅ | ✅    | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅
REGEX POSSIBLE                 | ✅ | ✅ | ✅    | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌
REGEX BASIC                    | ❌ | ❌ | ❌    | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌
REGEX TEXT                     | ❌ | ❌ | ❌    | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅

¹ Matches all unqualified Emoji, except for textual singleton Emoji (see columns 11, 12)

See [spec files](/spec) for detailed examples about which regex matches which kind of Emoji.

### Picking the Right Emoji Regex

- Usually you just want `REGEX` (recommended Emoji set, RGI)
- Use `REGEX_INCLUDE_MQE` or `REGEX_INCLUDE_MQE_UQE` if you want to catch Emoji sequences with missing Variation Selectors.
- If you want broader matching (any ZWJ sequences, more sub-region flags), choose `REGEX_VALID`
- If you need to match any region flag and any tag sequence, choose `REGEX_WELL_FORMED`
- Use the `_INCLUDE_TEXT` suffix with any of the above base regexes, if you want to also match basic textual Emoji
- And finally, there is also the option to use `REGEX_POSSIBLE`, which is a simplified test for possible Emoji, comparable to `REGEX_WELL_FORMED*`. It might contain false positives, however, the regex is less complex and [suggested in the Unicode standard itself](https://www.unicode.org/reports/tr51/#EBNF_and_Regex) as a first check.

### Examples

Desc | Emoji | Escaped | `REGEX` (RGI/FQE) | `REGEX_INCLUDE_MQE` (RGI/MQE) | `REGEX_VALID` | `REGEX_WELL_FORMED` / `REGEX_POSSIBLE`
-----|-------|---------|---------------|-----------------------|-----------------------------------|-----------------
RGI ZWJ Sequence   | 🤾🏽‍♀️ | `\u{1F93E 1F3FD 200D 2640 FE0F}` | ✅ | ✅ | ✅ | ✅
RGI ZWJ Sequence MQE | 🤾🏽‍♀ | `\u{1F93E 1F3FD 200D 2640}` | ❌ | ✅ | ✅ | ✅
Valid ZWJ Sequence, Non-RGI | 🤠‍🤢 | `\u{1F920 200D 1F922}` | ❌ | ❌  | ✅ | ✅
Known Region       | 🇵🇹 | `\u{1F1F5 1F1F9}` | ✅ | ✅ | ✅ | ✅
Unknown Region     | 🇵🇵 | `\u{1F1F5 1F1F5}` | ❌ | ❌  | ❌  | ✅
RGI Tag Sequence   | 🏴󠁧󠁢󠁳󠁣󠁴󠁿 | `\u{1F3F4 E0067 E0062 E0073 E0063 E0074 E007F}` | ✅ | ✅ | ✅ | ✅
Valid Tag Sequence | 🏴󠁧󠁢󠁡󠁧󠁢󠁿 | `\u{1F3F4 E0067 E0062 E0061 E0067 E0062 E007F}` | ❌ | ❌  | ✅ | ✅
Well-formed Tag Sequence | 😴󠁧󠁢󠁡󠁡󠁡󠁿 | `\u{1F634 E0067 E0062 E0061 E0061 E0061 E007F}` | ❌ | ❌  | ❌  | ✅

Please see [the standard](https://www.unicode.org/reports/tr51/#Emoji_Sets) for more details, examples, explanations.

More info about valid vs. recommended Emoji can also be found in this [blog article on Emojipedia](https://blog.emojipedia.org/unicode-behind-the-curtain/).

### Emoji Property Regexes

Ruby includes native regex Emoji properties, as listed in the following table. You can also opt-in to use the `*_PROP_*` regexes to get the Emoji support level of this gem (instead of Ruby's).

Gem Regex (`Unicode::Emoji`'s Emoji support level) | Native Regex (Ruby's Emoji support level)
---------------------------------------------------|------------------------------------------
`Unicode::Emoji::REGEX_PROP_EMOJI`         | `/\p{Emoji}/`
`Unicode::Emoji::REGEX_PROP_MODIFIER`      | `/\p{EMod}/`
`Unicode::Emoji::REGEX_PROP_MODIFIER_BASE` | `/\p{EBase}/`
`Unicode::Emoji::REGEX_PROP_COMPONENT`     | `/\p{EComp}/`
`Unicode::Emoji::REGEX_PROP_PRESENTATION`  | `/\p{EPres}/`
`Unicode::Emoji::REGEX_TEXT_PRESENTATION`  | `/[\p{Emoji}&&\P{EPres}]/`

#### Extended Pictographic Regex

`Unicode::Emoji::REGEX_PICTO` matches single codepoints with the **Extended_Pictographic** property. For example, it will match `✀` BLACK SAFETY SCISSORS.

`Unicode::Emoji::REGEX_PICTO_NO_EMOJI` matches single codepoints with the **Extended_Pictographic** property, but excludes Emoji characters.

See [character.construction/picto](https://character.construction/picto) for a list of all non-Emoji pictographic characters.

## Usage – List

Use `Unicode::Emoji::LIST` or the **list** method to get a ordered and categorized list of Emoji:

```ruby
Unicode::Emoji.list.keys
# => ["Smileys & Emotion", "People & Body", "Component", "Animals & Nature", "Food & Drink", "Travel & Places", "Activities", "Objects", "Symbols", "Flags"]

Unicode::Emoji.list("Food & Drink").keys
# => ["food-fruit", "food-vegetable", "food-prepared", "food-asian", "food-marine", "food-sweet", "drink", "dishware"]

Unicode::Emoji.list("Food & Drink", "food-asian")
=> ["🍱", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍠", "🍢", "🍣", "🍤", "🍥", "🥮", "🍡", "🥟", "🥠", "🥡"]
```

Please note that categories might change with future versions of the Emoji standard, although this has not happened often.

A list of all Emoji (generated from this gem) can be found at [character.construction/emoji](https://character.construction/emoji).

## Usage – Properties Data

Allows you to access the codepoint data for a single character form Unicode's [emoji-data.txt](https://www.unicode.org/Public/16.0.0/ucd/emoji/emoji-data.txt) file:

```ruby
require "unicode/emoji"

Unicode::Emoji.properties "☝" # => ["Emoji", "Emoji_Modifier_Base"]
```

## Also See

- [Unicode® Technical Standard #51](https://www.unicode.org/reports/tr51/)
- [Emoji categories](https://unicode.org/emoji/charts/emoji-ordering.html)
- Ruby gem which displays [Emoji sequence names](https://github.com/janlelis/unicode-sequence_name) ([as website](https://character.construction/name))
- Part of [unicode-x](https://github.com/janlelis/unicode-x)

## MIT

- Copyright (C) 2017-2024 Jan Lelis <https://janlelis.com>. Released under the MIT license.
- Unicode data: https://www.unicode.org/copyright.html#Exhibit1
