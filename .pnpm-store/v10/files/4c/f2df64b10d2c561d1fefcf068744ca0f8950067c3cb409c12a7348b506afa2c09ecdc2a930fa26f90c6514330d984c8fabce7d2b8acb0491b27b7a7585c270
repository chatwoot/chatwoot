# Metadata

This document describes `metadata.json` that's generated from `PhoneNumberMetadata.xml` by running `npm run metadata:generate` command. It serves as an intermediary step for generating all other metadata (such as `metadata.min.json`), and is therefore not included in the final distribution. See [`PhoneNumberMetadata.xml`](https://github.com/google/libphonenumber/blob/master/resources/PhoneNumberMetadata.xml) in Google's repo. They also have some [docs](https://github.com/google/libphonenumber/blob/master/resources/phonemetadata.proto) on metadata fields too.

## Country calling codes

`country_calling_codes` — A list of countries by country calling code: some country calling codes are shared between several countries (for example, United States and Canada).

## Countries

`countries` — Contains metadata for each country.

### `phone_code`

Country calling code, duplicated here for easy lookup of country calling code by country. Could be considered "reverse lookup" compared to `country_calling_codes`.

### `idd_prefix`

[International Direct Dialing prefix](https://wikitravel.org/en/International_dialling_prefix) when calling out of this country. "IDD prefixes" are defined for every country and are used to call from one country to another. "IDD prefixes" originated when telephony was still analogue and analogue phones didn't have a `+` input. Nowadays, mobile phone users dial international numbers using a `+` rather than an "IDD prefix", but the mobile phone operating system replaces the `+` with an "IDD prefix" under the hood. For example, to call a Russian number `+7 800 555 35 35` from US the dialled digits would be `01178005553535` where `011` is an "IDD prefix".

### `default_idd_prefix`

When a country supports different "IDD prefixes", the `idd_prefix` is a regular expression and `default_idd_prefix` is the default "IDD prefix".

### `ext`

Localized `" ext. "` prefix for this country. For example, in Russia it's `" доб. "`. Is only used for formatting phone numbers having "extensions" (usually these're organizational phone numbers: businesses, governmental institutions, educational institutions, etc).

### `leading_digits`

National (significant) number "leading digits" pattern. It's only defined for about 20% of the countries, and in most cases it's for resolving ambiguity in cases when there're groups of countries sharing the same "country calling code". Although, if there's a group of countries sharing the same "country calling code", it doesn't necessarily mean that those countries have a `leading_digits` pattern defined.

For example, USA and Canada share the same `1` country calling code, but neither of them have a `leading_digits` pattern defined. On the other hand, Antigua and Barbuda also shares the same `1` country calling code, and its `leading_digits` pattern is `"268"`, so if an international phone number starts with `+1268` then it's certain that it belongs to Antigua and Barbuda, so "leading digits" are, in some cases, a quick way of determining which one of the countries sharing the same country calling code does a phone number belong to.

While in most cases a `leading_digits` pattern is a sequence of digits like `"268"` for Antigua and Barbuda, in other cases it's a pattern like `"8001|8[024]9"` for Dominican Republic.

Overall, `leading_digits` patterns are only used as a performance speed-up trick when determining which country a phone number belongs to: the check is still simpler than looking for a match against all of the precise phone number digit patterns of every country sharing a given country calling code.

For that reason, matching a `leading_digits` pattern is a sufficient but not a necessary condition for a phone number to belong to a country: if a `leading_digits` pattern exists and a phone number matches it that it's certain that the phone number belongs to the country, and no other country. But, if there's no `leading_digits` pattern, or if the phone number doesn't match the `leading_digits` pattern, then it doesn't mean that the phone number doesn't belong to the country.

For example, "toll free" numbers starting with `800` are valid for all countries having `1` country calling code, so it doesn't make sense to include `800` in their `leading_digits` patterns. But one could say that those "toll free" numbers could be thought of as an unrelated edge case that can be ignored if the application only deals with human phone numbers.

Another example of phone number that're not included in `leading_digits` patters are ["personal"](https://en.wikipedia.org/wiki/Personal_Communications_Service) (satellite) numbers that start with [`5xx`](https://en.wikipedia.org/wiki/Personal_communications_service_(NANP)) for `+1` calling code.

<!-- https://www.nationalnanpa.com/number_resource_info/5XX_codes.html -->

The last example are mobile phone numbers which sometimes have identical patterns across the countries sharing the same "country calling code". An example are Finland (`FI`) and Åland Islands (`AX`) which share the same `+358` calling code and the same pattern for mobile phone numbers. And while [`+358 457 XXX XXXX`](https://en.wikipedia.org/wiki/Telephone_numbers_in_Åland) mobile numbers could belong both to Finland or Åland Islands, Åland Islands' `leading_digits` pattern is just `18` which doesn't include any mobile numbers at all.

So `leading_digits` patterns could only be used for a quick "positive" check and they can't be used for ruling out any countries.

### `national_number_pattern`

A regular expression covering all possible phone numbers for the country.

### `national_prefix`

"National prefix", also known as "National Direct Dialing prefix". In the early days of analogue telephony, countries were divided into "areas" (for example, cities), and calling within an area (for example, a city) would only involve dialing a phone number without "area code" digits, but calling from one "area" (city) to another (city) would require dialing a "national prefix" first, so that the analogue telephone station would switch the user into "nation-wide" calling mode first.

For example, in New Zealand, the number that would be locally dialled as `09 345 3456` would be dialled from overseas as `+64 9 345 3456`. In this case, `0` is the national prefix.

Other national prefix examples: `1` in US, `0` in France and UK, `8` in Russia.

### `national_prefix_for_parsing` / `national_prefix_transform_rule`

`national_prefix_for_parsing` is used to parse a [national (significant) number](https://gitlab.com/catamphetamine/libphonenumber-js#national-significant-number) from a phone number. Contrary to its name, `national_prefix_for_parsing` is used not just for parsing a "national prefix" out of a phone number (just `national_prefix` property would be sufficient for that), but also for parsing any other possible phone number prefixes out of a phone number, if there're any, and for any other cases like fixing a missing area code. So it's actually not a "national prefix for parsing", but rather a "national (significant) number extraction mechanism".

`national_prefix_for_parsing` is a regular expression that could (or could not) have some ["capturing groups"](https://www.regular-expressions.info/refcapture.html). If there're any "capturing groups", then `national_prefix_for_parsing` is accompanied by `national_prefix_transform_rule`: yet another incorrect name by Google, because `national_prefix_transform_rule` is not a "rule for transforming a national prefix", but rather a "template to transform the captured groups into a national (significant) number".

There're different types of possible "prefixes" a phone number could have. One example are ["carrier codes"](https://www.bandwidth.com/glossary/carrier-identification-code-cic/). If a `national_prefix_transform_rule` is defined and the `national_prefix_for_parsing` has more than one "capturing group", then the second "capturing group" is a "carrier code". If a `national_prefix_transform_rule` is not defined and the `national_prefix_for_parsing` has at least one "capturing group", then the first "capturing group" is a "carrier code".

For example, countries like Argentina and Brazil do use ["carrier codes"](https://www.bandwidth.com/glossary/carrier-identification-code-cic/), and their `national_prefix_for_parsing` regular expressions include both national prefix and all possible "carrier codes". So, for example, to dial the number `2222-2222` in Fortaleza, Brazil (national prefix `0`, area code `85`) using the long distance carrier Oi (selection code `31`), one would dial `0 31 85 2222 2222`, and, for parsing such numbers, Brazil's `national_prefix_for_parsing` is `0(?:(1[245]|2[1-35]|31|4[13]|[56]5|99)(\d{10,11}))?`, which matches the whole `0318522222222` number with captured group #1 being `31` ("carrier code") and captured group #2 being `8522222222` (which is also the actual national (significant) number, because `national_prefix_transform_rule` is `$2`).

Another example of a "prefix": some countries support "utility" prefixes, like Australia (national prefix `0`) that supports `1831` prefix to [hide your phone number](https://exchange.telstra.com.au/how-to-block-your-number-when-calling-someone/) when calling somebody (and `1832` to un-hide it when in "permanent" hiding mode), and so Australia's `national_prefix_for_parsing` is `0|(183[12])`, which matches the `1831` prefix as group #1.

Another example of using a `national_prefix_for_parsing` / `national_prefix_transform_rule` pair, in this case for reasons completely unrelated to any "prefixes", are U.S. Virgin Islands (national prefix `1`) whose phone numbers always start with a `340` area code because there's no other area code in this tiny (`346.36` square kilometers) island country. So it's common for its citizens to call `693-4800` instead of `(340) 693-4800`, and Google's `libphonenumber` handles this case by `national_prefix_for_parsing` being `1|([2-9]\d{6})$`, which matches `6934800` number as group #1, which is later used in `national_prefix_transform_rule`, which is `340$1`, meaning that it prepends `340` to the group #1 being the `6934800` number, resulting in `3406934800` national (significant) number.

If `national_prefix_for_parsing` matches any "capturing groups", then it doesn't provide the actual national prefix being extracted, or even guarantee the fact that there is a national prefix: in those cases, it just converts a national number to a national (significant) number by applying a `national_prefix_for_parsing`/`national_prefix_transform_rule` transform to it.

For example, in `AG` country, phone numbers are same as in the `US`, with the only difference that they start with `268`. The `national_prefix_for_parsing` is `1|([457]\\d{6})$`. If a number is entered with a leading `1` (`"1 268 464 1234"`), then there're no "capturing groups" in that regular expression, so the national prefix is the entire substring matched by the regular expression: `"1"`. If a number is entered without a leading `1` (`"268 464 1234"`), then the regular expression doesn't match, and the number doesn't have a national prefix (which is true). If a number is entered without the "area code" `268` (just `"464 1234"`), then `national_prefix_for_parsing` regular expression matches with the "capturing group" being `"4641234"`, and then `national_prefix_transform_rule` `268$1` transforms that "capturing group" into a `2684641234` national (significant) number; and even though `national_prefix_for_parsing` did match, the phone number didn't have any national prefix.

Another example is Mexico (`MX`) that has no `national_prefix_transform_rule` and has `national_prefix_for_parsing` `0(?:[12]|4[45])|1`: the `?:` defines a "non-capturing group", so `national_prefix_for_parsing` has no "capturing groups", and, therefore, matches the actual national prefix of a phone number; that national prefix isn't used anywhere though: it's simply discarded, because all `format`s of Mexico have `national_prefix_is_optional_when_formatting: true`, meaning that a national prefix isn't used when formatting a phone number using any of those `format`s.

If no `national_prefix_for_parsing` has been defined, but `national_prefix` has been defined, then `national_prefix_for_parsing` is equal to `national_prefix`.

Whatever national prefix has been extracted, it's not used anywhere: instead, `national_prefix_formatting_rule` of a `format` already has a national prefix "hardcoded". For example, in Russia, `national_prefix` is `8`, and `national_prefix_formatting_rule` of all `format`s is `8 ($1)`. So the code doesn't store the extracted national prefix anywhere: only the fact that the national prefix has been extracted is used to decide whether to apply `national_prefix_formatting_rule` when formatting the parsed number.

### `types`

Regular expressions for all possible phone number [types](https://gitlab.com/catamphetamine/libphonenumber-js#gettype-string) for this country: `fixed_line`, `mobile`, `toll_free`, `premium_rate`, etc.

#### `type` `pattern`

A regular expression for a national (significant) number matching the type.

#### `type` `possible_lengths`

Possible lengths of a national (significant) number matching the type. Is always present.

### `examples`

Phone number examples for each of the phone number `types`.

### `possible_lengths`

Possible lengths of a national (significant) number for this numbering plan. This property is a combination of `possible_lengths` of all `types`. Is always present.

### `formats`

Describes all possible phone number formats for this country. May be missing if phone numbers aren't formatted for this country (there're many such countries, usually small islands).

#### `format` `pattern`

A regular expression for a phone number supported by this format.

For example, in `US` there's only one possible phone number format, and it's `pattern` is `(\d{3})(\d{3})(\d{4})`, meaning that the national (significant) number must be `3 + 3 + 4 = 10` digits long (for example, `2133734253`), and is divided into three groups of digits for formatting (in this case, `213`, `373` and `4253`).

#### `format` `format`

Defines how the aforementioned groups of digits are combined when formatting a phone number.

For example, in `US` there's only one possible phone number format, and it's `format` is `($1) $2-$3`, so `2133734253` national (significant) number is formatted as `(213) 373-4253`.

#### `format` `international_format`

Parentheses arond "area code" only make sense when formatting a national phone number, so international phone numbers don't use them, hence the explicit `international_format` in addition to the national `format`.

For example, in `US` there's only one possible phone number format, and it's `format` is `($1) $2-$3`, while its `international_format` is `$1-$2-$3`, meaning that `2133734253` national (significant) number is formatted as `+1 213 373-4253` when formatted for international dialing.

#### `format` `national_prefix_formatting_rule`

`national_prefix_formatting_rule` is sometimes used to define how national prefix changes how a phone number should be formatted. For example, in Russia (national prefix `8`), all `format`s have `national_prefix_formatting_rule` `8 ($1)`, meaning that a `88005553535` phone number is first stripped of `8` national prefix into a `8005553535` national (significant) number, then the national (significant) number is first parsed using `format.pattern` `(\d{3})(\d{3})(\d{2})(\d{2})` and then formatted using `format.format` `$1 $2-$3-$4` while also replacing `$1` in that `format.format` with `format.national_prefix_formatting_rule` which is `8 ($1)`, so the resulting `format.format` becomes `8 ($1) $2-$3-$4`, and so the formatted number is `8 (800) 555-35-35`. Have the phone number been input without the `8` national prefix, the `national_prefix_formatting_rule` wouldn't be applied, and `format.format` would stay `$1 $2-$3-$4`, and the formatted phone number would be `800 555-35-35`.

In some cases (for example, in Argentina), `format.format` may exclude `$1`, so in those cases `national_prefix_formatting_rule` being `0$1` would actually mean `0$2`, because there's no `$1` "capturing group" in `format.format`, but there is `$2` "capturing group" there.

#### `format` `national_prefix_is_optional_when_formatting`

This field specifies whether the national prefix can be omitted when formatting a number in national format. For example, a UK (`GB`) number would be formatted by `libphonenumber` as `020 XXXX XXXX`. Have they seen this number commonly being written without the leading `0` (like `(20) XXXX XXXX`), they would have updated the metadata with `national_prefix_is_optional_when_formatting` being `true` for that `format`, so that such number, when formatted, wouldn't have `national_prefix_formatting_rule` applied to it. Otherwise, if `national_prefix_is_optional_when_formatting` is not set to `true`, `national_prefix_formatting_rule` is always applied (when present).

#### `format` `domestic_carrier_code_formatting_rule`

Specifies how a carrier code (`$CC`) together with the first group (`$FG`) in a national significant number should be formatted, if carrier codes are used when formatting the number for dialing. For example, if a `format`'s `format` is `$1 $2-$3` and `domestic_carrier_code_formatting_rule` is `$NP $CC ($FG)`, then a national number, when having a carrier code, is formatted as `national-prefix carrier-code ($1) $2-$3`.

For example, Google's `libphonenumber` has `formatNumberForMobileDialing()` function that returns a number formatted in such a way that it can be dialed from a mobile phone within a specific country, and it adds ["carrier codes"](https://www.bandwidth.com/glossary/carrier-identification-code-cic/) when dialing within certain countries (Brazil — when dialing from a mobile phone to any number, Colombia — when dialing from a mobile phone to a fixed line number). Since `libphonenumber-js` is not a dialing library, it doesn't provide such a function and doesn't use "carrier codes" when formatting phone numbers, so this property is ignored in this library.

#### `format` `leading_digits_patterns`

"Leading digits" patterns are used in `AsYouType` formatter to choose a format suitable for the phone number being input: if a phone number's "leading digits" match those of a format, then that format is used to format the phone number being input. Each subsequent leading digits pattern in `leading_digits_patterns` array requires one more leading digit.

## Non-geographic

There're [calling codes](https://gitlab.com/catamphetamine/libphonenumber-js#non-geographic) that don't correspond to any country. For example, "Global Mobile Satellite System" (`+881`). Such phone numbering systems are called "non-geographic entities" in Google's code. These "non-geographic entitites" reside in their own `nonGeographic` property, analogous to the `countries` property. `nonGeographic` is an object with keys being calling codes of the corresponding "non-geographic entities", and values being same as the values of the `countries` property.

"Non-geographic" numbering plans don't have [`possible_lengths`](#possible-lengths).